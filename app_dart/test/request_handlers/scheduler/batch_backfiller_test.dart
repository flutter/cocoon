// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart' as rpc;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_strategy.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/batch_backfiller.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/pending_task.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/service/fake_ci_yaml_fetcher.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  // Under Test.
  late BatchBackfiller handler;

  // Dependencies.
  late FakeConfig config;
  late FakeFirestoreService firestore;
  late FakeCiYamlFetcher ciYamlFetcher;
  late _FakeLuciBuildService fakeLuciBuildService;

  // Used to implement BranchService.getBranches.
  late List<rpc.Branch>? branchesForRepository;

  // Fixture.
  late RequestHandlerTester tester;

  setUp(() {
    firestore = FakeFirestoreService();
    config = FakeConfig(
      backfillerCommitLimitValue: 10,
      backfillerTargetLimitValue: 100,
      supportedReposValue: {Config.flutterSlug},
    );
    ciYamlFetcher = FakeCiYamlFetcher();
    fakeLuciBuildService = _FakeLuciBuildService();

    final branchService = MockBranchService();
    branchesForRepository = [];
    when(branchService.getReleaseBranches(slug: anyNamed('slug'))).thenAnswer((
      i,
    ) async {
      final slug = i.namedArguments[#slug] as RepositorySlug;
      return branchesForRepository ??
          [
            rpc.Branch(
              channel: Config.defaultBranch(slug),
              reference: Config.defaultBranch(slug),
            ),
          ];
    });

    handler = BatchBackfiller(
      config: config,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: fakeLuciBuildService,
      backfillerStrategy: const _NaiveBackfillStrategy(),
      firestore: firestore,
      branchService: branchService,
    );

    tester = RequestHandlerTester();
  });

  const $N = TaskStatus.waitingForBackfill;
  const $I = TaskStatus.inProgress;
  const $S = TaskStatus.succeeded;
  const $F = TaskStatus.failed;
  const $K = TaskStatus.skipped;

  Future<List<String>> visualizeFirestoreGrid({
    int? commits,
    String? branch,
  }) async {
    final grid = await firestore.queryRecentCommitsAndTasks(
      Config.flutterSlug,
      commitLimit: commits ?? config.backfillerCommitLimit,
      branch: branch,
    );

    final result = <String>[];
    const emojis = {$N: '⬜', $I: '🟨', $S: '🟩', $F: '🟥', $K: '⬛️'};

    for (final commit in grid) {
      final buffer = StringBuffer('🧑‍💼 ');
      buffer.writeAll(commit.tasks.map((t) => emojis[t.status]), ' ');
      result.add('$buffer');
    }

    return result;
  }

  Future<void> fillStorageAndSetCiYaml(
    List<List<TaskStatus>> statuses, {
    String branch = 'master',
    List<bool> backfill = const [true, true, true, true],
  }) async {
    if (backfill.length < 4) {
      backfill = List.filled(4, true)..setAll(0, backfill);
    }
    ciYamlFetcher.setCiYamlFrom(
      '''
    enabled_branches:
      - master

    targets:
      - name: Linux 0
        backfill: ${backfill[0]}
      - name: Linux 1
        backfill: ${backfill[1]}
      - name: Linux 2
        backfill: ${backfill[2]}
      - name: Linux 3
        backfill: ${backfill[3]}
    ''',
      engine: '''
    enabled_branches:
      - master

    targets:
      - name: Engine 0
    ''',
    );

    var date = DateTime(2025, 1, 1);
    for (final (i, row) in statuses.indexed) {
      final fsCommit = generateFirestoreCommit(
        i,
        createTimestamp: date.millisecondsSinceEpoch,
        branch: branch,
      );
      firestore.putDocument(fsCommit);

      for (final (n, column) in row.indexed) {
        final fsTask = generateFirestoreTask(
          n,
          status: column,
          commitSha: fsCommit.sha,
          name: 'Linux $n',
        );
        firestore.putDocument(fsTask);
      }

      date = date.subtract(const Duration(seconds: 1));
    }
  }

  // This is not how the production BatchBackfiller works (not exactly), but
  // we are mostly testing reading NEW tasks (⬜) from the database, and marking
  // them IN PROGRESS (🟨) while scheduling LUCI builds.
  //
  // Specific backfill strategies are tested elsewhere.
  test('schedules the first NEW task in each target', () async {
    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $I, $F, $S],
      [$N, $N, $N, $N],
    ]);
    // dart format on

    // BEFORE:
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
    ]);

    await tester.get(handler);

    // AFTER:
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 🟨 🟨 🟥 🟩',
      '🧑‍💼 ⬜ 🟨 🟨 🟨',
    ]);
  });

  test('fetches and filters based on the ToT commit\'s targets', () async {
    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $I, $F, $S],
      [$N, $N, $N, $N],
    ]);
    // dart format on

    // Override. Remove the first column from ToT.
    ciYamlFetcher.setCiYamlFrom(
      '''
    enabled_branches:
      - master

    targets:
      # Intentionally removed.
      # - name: Linux 0
      - name: Linux 1
      - name: Linux 2
      - name: Linux 3
    ''',
      engine: '''
    enabled_branches:
      - master

    targets:
      - name: Engine 0
    ''',
    );

    // BEFORE:
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
    ]);

    await tester.get(handler);

    // AFTER:
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ 🟨 🟨 🟨',
    ]);
  });

  test('only schedules the top X tasks even if more are eligible', () async {
    config.backfillerTargetLimitValue = 3;

    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $I, $F, $S],
      [$N, $N, $N, $N],
    ]);
    // dart format on

    // BEFORE:
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
    ]);

    await tester.get(handler);

    // AFTER:
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 🟨 🟨 🟥 🟩',
      '🧑‍💼 ⬜ 🟨 🟨 ⬜',
    ]);
  });

  test('only considers the top X commits', () async {
    config.backfillerCommitLimitValue = 1;

    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $I, $F, $S],
      [$N, $N, $N, $N],
    ]);
    // dart format on

    // BEFORE:
    expect(await visualizeFirestoreGrid(commits: 2), [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
    ]);

    await tester.get(handler);

    // AFTER:
    expect(await visualizeFirestoreGrid(commits: 2), [
      '🧑‍💼 🟨 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
    ]);
  });

  test('backfills release candidate branches', () async {
    branchesForRepository = [
      rpc.Branch(channel: 'master', reference: 'master'),
      rpc.Branch(channel: 'beta', reference: 'flutter-3.32-candidate.0'),
    ];

    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $I, $F, $S],
      [$N, $N, $N, $N],
    ], branch: 'flutter-3.32-candidate.0');
    // dart format on

    // BEFORE:
    expect(
      await visualizeFirestoreGrid(
        commits: 2,
        branch: 'flutter-3.32-candidate.0',
      ),
      // dart format off
      [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
      ],
      // dart format on
    );

    await tester.get(handler);

    // AFTER:
    expect(
      await visualizeFirestoreGrid(
        commits: 2,
        branch: 'flutter-3.32-candidate.0',
      ),
      // dart format off
      [
      '🧑‍💼 🟨 🟨 🟥 🟩',
      '🧑‍💼 ⬜ 🟨 🟨 🟨',
      ],
      // dart format on
    );
  });

  // https://github.com/flutter/flutter/issues/167756
  test('skips backfill=false targets', () async {
    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $N],
    ], backfill: [false, true]);
    // dart format on

    // BEFORE:
    // dart format off
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 ⬜ ⬜',
    ]);
    // dart format on

    await tester.get(handler);

    // AFTER:
    // dart format off
    expect(await visualizeFirestoreGrid(), [
      '🧑‍💼 ⬛️ 🟨',
    ]);
    // dart format on
  });

  // https://github.com/flutter/flutter/issues/168738
  test('schedules low-priority targets for "ios-experimental"', () async {
    branchesForRepository = [
      // Intentionally left blank.
    ];

    // dart format off
    await fillStorageAndSetCiYaml([
      [$N, $I, $F, $S],
      [$N, $N, $N, $N],
    ], branch: 'ios-experimental');
    // dart format on

    // BEFORE:
    expect(
      await visualizeFirestoreGrid(commits: 2, branch: 'ios-experimental'),
      // dart format off
      [
      '🧑‍💼 ⬜ 🟨 🟥 🟩',
      '🧑‍💼 ⬜ ⬜ ⬜ ⬜',
      ],
      // dart format on
    );

    await tester.get(handler);

    // AFTER:
    expect(
      await visualizeFirestoreGrid(commits: 2, branch: 'ios-experimental'),
      // dart format off
      [
      '🧑‍💼 🟨 🟨 🟥 🟩',
      '🧑‍💼 ⬜ 🟨 🟨 🟨',
      ],
      // dart format on
    );

    expect(
      fakeLuciBuildService.scheduledPostsubmitBuilds,
      allOf(
        hasLength(4),
        everyElement(
          isA<PendingTask>().having(
            (t) => t.priority,
            'priority',
            LuciBuildService.kBackfillPriority,
          ),
        ),
      ),
      reason: 'Should use a low priority for all executions',
    );
  });
}

/// A very hermetic but dumb backfilling algorithm.
///
/// Picks the first `⬜` for each target.
final class _NaiveBackfillStrategy extends BackfillStrategy {
  const _NaiveBackfillStrategy();

  @override
  List<BackfillTask> determineBackfill(BackfillGrid grid) {
    return [
      for (final (_, tasks) in grid.eligibleTasks)
        if (tasks.firstWhereOrNull(
              (t) => t.status == TaskStatus.waitingForBackfill,
            )
            case final task?)
          grid.createBackfillTask(
            task,
            priority: LuciBuildService.kBackfillPriority,
          ),
    ];
  }
}

final class _FakeLuciBuildService extends Fake implements LuciBuildService {
  final scheduledPostsubmitBuilds = <PendingTask>[];

  @override
  Future<List<PendingTask>> schedulePostsubmitBuilds({
    required CommitRef commit,
    required List<PendingTask> toBeScheduled,
  }) async {
    scheduledPostsubmitBuilds.addAll(toBeScheduled);
    return [];
  }
}
