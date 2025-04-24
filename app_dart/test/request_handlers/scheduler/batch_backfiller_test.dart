// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart' as rpc;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_strategy.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/batch_backfiller.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/service/fake_ci_yaml_fetcher.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_luci_build_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  // Under Test.
  late BatchBackfiller handler;

  // Dependencies.
  late FakePubSub pubSub;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeConfig config;
  late FakeFirestoreService firestore;
  late FakeCiYamlFetcher ciYamlFetcher;

  // Used to implement BranchService.getBranches.
  late List<rpc.Branch>? branchesForRepository;

  // Fixture.
  late RequestHandlerTester tester;

  setUp(() {
    pubSub = FakePubSub();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestore = FakeFirestoreService();
    config = FakeConfig(
      backfillerCommitLimitValue: 10,
      backfillerTargetLimitValue: 100,
      supportedReposValue: {Config.flutterSlug},
    );
    ciYamlFetcher = FakeCiYamlFetcher();

    final luciBuildService = FakeLuciBuildService(
      config: config,
      pubsub: pubSub,
      githubChecksUtil: mockGithubChecksUtil,
      firestore: firestore,
    );

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
      luciBuildService: luciBuildService,
      backfillerStrategy: const _NaiveBackfillStrategy(),
      firestore: firestore,
      branchService: branchService,
    );

    tester = RequestHandlerTester();
  });

  const $N = fs.Task.statusNew;
  const $I = fs.Task.statusInProgress;
  const $S = fs.Task.statusSucceeded;
  const $F = fs.Task.statusFailed;
  const $K = fs.Task.statusSkipped;

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
    List<List<String>> statuses, {
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
        if (tasks.firstWhereOrNull((t) => t.status == fs.Task.statusNew)
            case final task?)
          grid.createBackfillTask(
            task,
            priority: LuciBuildService.kBackfillPriority,
          ),
    ];
  }
}
