// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/service/luci_build_service/opaque_commit.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/service/fake_ci_yaml_fetcher.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_luci_build_service.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

final List<Commit> commits = <Commit>[
  generateCommit(3),
  generateCommit(2),
  generateCommit(1),
];

void main() {
  useTestLoggerPerTest();

  late BatchBackfiller handler;
  late RequestHandlerTester tester;
  late FakeDatastoreDB db;
  late FakePubSub pubsub;
  late FakeScheduler scheduler;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Config config;
  late FakeFirestoreService firestore;
  late FakeCiYamlFetcher ciYamlFetcher;

  setUp(() async {
    firestore = FakeFirestoreService();

    db =
        FakeDatastoreDB()
          ..addOnQuery<Commit>((Iterable<Commit> results) => commits);

    config = FakeConfig(
      dbValue: db,
      backfillerTargetLimitValue: 2,
      firestoreService: firestore,
    );

    pubsub = FakePubSub();

    mockGithubChecksUtil = MockGithubChecksUtil();

    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((_) async => generateCheckRun(1));

    ciYamlFetcher = FakeCiYamlFetcher(ciYaml: batchPolicyConfig);
    final luciBuildService = FakeLuciBuildService(
      config: config,
      pubsub: pubsub,
      githubChecksUtil: mockGithubChecksUtil,
    );

    scheduler = FakeScheduler(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
      luciBuildService: luciBuildService,
    );

    handler = BatchBackfiller(
      config: config,
      scheduler: scheduler,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luciBuildService,
    );

    tester = RequestHandlerTester();
  });

  test('does not backfill on completed task column', () async {
    final allGreen = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android A', status: Task.statusSucceeded),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => allGreen);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages, isEmpty);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusSucceeded).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusSucceeded).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusSucceeded).hasCommitSha('3'),
      ]),
    );
  });

  test('does not backfill when there is a running task', () async {
    final middleTaskInProgress = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusNew),
      generateTask(2, name: 'Linux_android A', status: Task.statusInProgress),
      generateTask(3, name: 'Linux_android A', status: Task.statusNew),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => middleTaskInProgress);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusInProgress,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages, isEmpty);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusInProgress).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('3'),
      ]),
    );
  });

  test('does not backfill when task does not exist in TOT', () async {
    ciYamlFetcher.ciYaml = notInToTConfig;
    final luciBuildService = FakeLuciBuildService(
      config: config,
      pubsub: pubsub,
      githubChecksUtil: mockGithubChecksUtil,
    );
    scheduler = FakeScheduler(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
      luciBuildService: luciBuildService,
    );
    handler = BatchBackfiller(
      config: config,
      scheduler: scheduler,
      ciYamlFetcher: ciYamlFetcher,
      luciBuildService: luciBuildService,
    );
    final allGray = <Task>[
      generateTask(1, name: 'Linux_android B', status: Task.statusNew),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => allGray);
    await tester.get(handler);
    expect(pubsub.messages.length, 0);
  });

  test('backfills latest task', () async {
    // TODO(matanlurey): FakeDatastore doesn't apply sorting, so manually sort
    // the tasks to ensure the latest task is the last one (Firestore does).
    final allGray = <Task>[
      generateTask(
        1,
        name: 'Linux_android A',
        status: Task.statusNew,
        created: DateTime(2025, 1, 1, 1, 0),
      ),
      generateTask(
        2,
        name: 'Linux_android A',
        status: Task.statusNew,
        created: DateTime(2025, 1, 1, 1, 1),
      ),
      generateTask(
        3,
        name: 'Linux_android A',
        status: Task.statusNew,
        created: DateTime(2025, 1, 1, 1, 2),
      ),
    ]..sort((a, b) => b.createTimestamp!.compareTo(a.createTimestamp!));
    db.addOnQuery<Task>((Iterable<Task> results) => allGray);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '1',
        created: DateTime(2025, 1, 1, 1, 0),
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '2',
        created: DateTime(2025, 1, 1, 1, 1),
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
        created: DateTime(2025, 1, 1, 1, 2),
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 1);

    final batchRequest = bbv2.BatchRequest.create();
    batchRequest.mergeFromProto3Json(pubsub.messages.first);

    final scheduleBuildRequest = batchRequest.requests.first.scheduleBuild;

    expect(scheduleBuildRequest.priority, LuciBuildService.kBackfillPriority);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusInProgress).hasCommitSha('3'),
      ]),
    );
  });

  test(
    'does not backfill targets when number of available tasks is less than BatchPolicy.kBatchSize',
    () async {
      final scheduleA = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => scheduleA);
      await tester.get(handler);
      expect(pubsub.messages.length, 0);
    },
  );

  test('backfills earlier failed task with higher priority', () async {
    // TODO(matanlurey): FakeDatastore doesn't apply sorting, so manually sort
    // the tasks to ensure the latest task is the last one (Firestore does).
    final allGray = <Task>[
      generateTask(
        1,
        name: 'Linux_android A',
        status: Task.statusNew,
        created: DateTime(2025, 1, 1, 1, 0),
      ),
      generateTask(
        2,
        name: 'Linux_android A',
        status: Task.statusNew,
        created: DateTime(2025, 1, 1, 1, 1),
      ),
      generateTask(
        3,
        name: 'Linux_android A',
        status: Task.statusFailed,
        created: DateTime(2025, 1, 1, 1, 2),
      ),
    ]..sort((a, b) => b.createTimestamp!.compareTo(a.createTimestamp!));
    db.addOnQuery<Task>((Iterable<Task> results) => allGray);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '1',
        created: DateTime(2025, 1, 1, 1, 0),
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '2',
        created: DateTime(2025, 1, 1, 1, 1),
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusFailed,
        commitSha: '3',
        created: DateTime(2025, 1, 1, 1, 2),
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 1);

    final batchRequest = bbv2.BatchRequest.create();
    batchRequest.mergeFromProto3Json(pubsub.messages.first);

    final scheduleBuildRequest = batchRequest.requests.first.scheduleBuild;

    expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusInProgress).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusFailed).hasCommitSha('3'),
      ]),
    );
  });

  test('backfills task successfully with retry', () async {
    pubsub.exceptionFlag = true;
    pubsub.exceptionRepetition = 1;
    final allGray = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusNew),
      generateTask(2, name: 'Linux_android A', status: Task.statusNew),
      generateTask(3, name: 'Linux_android A', status: Task.statusFailed),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => allGray);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusFailed,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 1);

    final batchRequest = bbv2.BatchRequest.create();
    batchRequest.mergeFromProto3Json(pubsub.messages.first);

    final scheduleBuildRequest = batchRequest.requests.first.scheduleBuild;

    expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusInProgress).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusFailed).hasCommitSha('3'),
      ]),
    );
  });

  test('fails to backfill tasks when retry limit is hit', () async {
    pubsub.exceptionFlag = true;
    pubsub.exceptionRepetition = 3;
    final allGray = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusNew),
      generateTask(2, name: 'Linux_android A', status: Task.statusNew),
      generateTask(3, name: 'Linux_android A', status: Task.statusFailed),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => allGray);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusFailed,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 0);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusInProgress).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusNew).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusFailed).hasCommitSha('3'),
      ]),
    );
  });

  test('backfills older task', () async {
    final oldestGray = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android A', status: Task.statusNew),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => oldestGray);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 1);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusSucceeded).hasCommitSha('1'),
        isTask.hasStatus(fs.Task.statusSucceeded).hasCommitSha('2'),
        isTask.hasStatus(fs.Task.statusInProgress).hasCommitSha('3'),
      ]),
    );
  });

  test('updates task as in-progress after backfilling', () async {
    final oldestGray = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android A', status: Task.statusNew),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => oldestGray);
    final task = oldestGray[2];
    expect(db.values.length, 0);
    expect(task.status, Task.statusNew);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(db.values.length, 1);
    expect(task.status, Task.statusInProgress);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusSucceeded),
        isTask.hasStatus(fs.Task.statusSucceeded),
        isTask.hasStatus(fs.Task.statusInProgress),
      ]),
    );
  });

  test('skip scheduling builds if datastore commit fails', () async {
    db.commitException = true;
    final oldestGray = <Task>[
      generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android A', status: Task.statusNew),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => oldestGray);
    expect(db.values.length, 0);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(db.values.length, 0);
    expect(pubsub.messages.length, 0);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(fs.Task.statusSucceeded),
        isTask.hasStatus(fs.Task.statusSucceeded),
        isTask.hasStatus(fs.Task.statusNew),
      ]),
    );
  });

  test('backfills only column A when B does not need backfill', () async {
    final scheduleA = <Task>[
      // Linux_android A
      generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      // Linux_android B
      generateTask(1, name: 'Linux_android B', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android B', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android B', status: Task.statusSucceeded),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => scheduleA);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android B',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android B',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android B',
        status: fs.Task.statusSucceeded,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 1);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux_android A')
            .hasCommitSha('1')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android A')
            .hasCommitSha('2')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android A')
            .hasCommitSha('3')
            .hasStatus(fs.Task.statusInProgress),
        isTask
            .hasTaskName('Linux_android B')
            .hasCommitSha('1')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android B')
            .hasCommitSha('2')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android B')
            .hasCommitSha('3')
            .hasStatus(fs.Task.statusSucceeded),
      ]),
    );
  });

  test('backfills both column A and B', () async {
    final scheduleA = <Task>[
      // Linux_android A
      generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      // Linux_android B
      generateTask(1, name: 'Linux_android B', status: Task.statusSucceeded),
      generateTask(2, name: 'Linux_android B', status: Task.statusSucceeded),
      generateTask(3, name: 'Linux_android B', status: Task.statusNew),
    ];
    db.addOnQuery<Task>((Iterable<Task> results) => scheduleA);

    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android A',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android A',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        1,
        name: 'Linux_android B',
        status: fs.Task.statusSucceeded,
        commitSha: '1',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        2,
        name: 'Linux_android B',
        status: fs.Task.statusSucceeded,
        commitSha: '2',
      ),
    );
    firestore.putDocument(
      generateFirestoreTask(
        3,
        name: 'Linux_android B',
        status: fs.Task.statusNew,
        commitSha: '3',
      ),
    );

    await tester.get(handler);
    expect(pubsub.messages.length, 2);

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask
            .hasTaskName('Linux_android A')
            .hasCommitSha('1')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android A')
            .hasCommitSha('2')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android A')
            .hasCommitSha('3')
            .hasStatus(fs.Task.statusInProgress),
        isTask
            .hasTaskName('Linux_android B')
            .hasCommitSha('1')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android B')
            .hasCommitSha('2')
            .hasStatus(fs.Task.statusSucceeded),
        isTask
            .hasTaskName('Linux_android B')
            .hasCommitSha('3')
            .hasStatus(fs.Task.statusInProgress),
      ]),
    );
  });

  test(
    'backfills limited targets when number of available targets exceeds backfillerTargetLimit ',
    () async {
      final scheduleA = <Task>[
        // Linux_android A
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
        generateTask(2, name: 'Linux_android A', status: Task.statusNew),
        // Linux_android B
        generateTask(1, name: 'Linux_android B', status: Task.statusNew),
        generateTask(2, name: 'Linux_android B', status: Task.statusNew),
        // Linux_android C
        generateTask(1, name: 'Linux_android C', status: Task.statusNew),
        generateTask(2, name: 'Linux_android C', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => scheduleA);

      firestore.putDocument(
        generateFirestoreTask(
          1,
          name: 'Linux_android A',
          status: fs.Task.statusNew,
          commitSha: '1',
        ),
      );
      firestore.putDocument(
        generateFirestoreTask(
          2,
          name: 'Linux_android A',
          status: fs.Task.statusNew,
          commitSha: '2',
        ),
      );
      firestore.putDocument(
        generateFirestoreTask(
          1,
          name: 'Linux_android B',
          status: fs.Task.statusNew,
          commitSha: '1',
        ),
      );
      firestore.putDocument(
        generateFirestoreTask(
          2,
          name: 'Linux_android B',
          status: fs.Task.statusNew,
          commitSha: '2',
        ),
      );
      firestore.putDocument(
        generateFirestoreTask(
          1,
          name: 'Linux_android C',
          status: fs.Task.statusNew,
          commitSha: '1',
        ),
      );
      firestore.putDocument(
        generateFirestoreTask(
          2,
          name: 'Linux_android C',
          status: fs.Task.statusNew,
          commitSha: '2',
        ),
      );

      await tester.get(handler);
      expect(pubsub.messages.length, 2);

      // The batch backfiller randomly selects tasks to backfill when they are
      // otherwise equal. The test is not deterministic, so we need to have a
      // soft check here.
      expect(
        firestore,
        existsInStorage(
          fs.Task.metadata,
          unorderedEquals([
            isTask.hasStatus(fs.Task.statusNew),
            isTask.hasStatus(fs.Task.statusNew),
            isTask.hasStatus(fs.Task.statusNew),
            isTask.hasStatus(fs.Task.statusNew),
            isTask.hasStatus(fs.Task.statusInProgress),
            isTask.hasStatus(fs.Task.statusInProgress),
          ]),
        ),
      );
    },
  );

  group('getFilteredBackfill', () {
    test('backfills high priorty targets first', () async {
      final backfill = <Tuple<Target, FullTask, int>>[
        Tuple(
          generateTarget(1),
          FullTask(
            generateTask(1),
            OpaqueCommit.fromDatastore(generateCommit(1)),
          ),
          LuciBuildService.kRerunPriority,
        ),
        Tuple(
          generateTarget(2),
          FullTask(
            generateTask(2),
            OpaqueCommit.fromDatastore(generateCommit(2)),
          ),
          LuciBuildService.kBackfillPriority,
        ),
        Tuple(
          generateTarget(3),
          FullTask(
            generateTask(3),
            OpaqueCommit.fromDatastore(generateCommit(3)),
          ),
          LuciBuildService.kRerunPriority,
        ),
      ];
      final filteredBackfill = handler.getFilteredBackfill(backfill);
      expect(filteredBackfill.length, 2);
      expect(filteredBackfill[0].third, LuciBuildService.kRerunPriority);
      expect(filteredBackfill[1].third, LuciBuildService.kRerunPriority);
    });
  });
}
