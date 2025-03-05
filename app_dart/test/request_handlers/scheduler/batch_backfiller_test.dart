// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/request_handling/request_handler_tester.dart';
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
  late BatchBackfiller handler;
  late RequestHandlerTester tester;
  late FakeDatastoreDB db;
  late FakePubSub pubsub;
  late FakeScheduler scheduler;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Config config;
  late MockFirestoreService mockFirestoreService;

  group('BatchBackfiller', () {
    setUp(() async {
      mockFirestoreService = MockFirestoreService();

      db =
          FakeDatastoreDB()
            ..addOnQuery<Commit>((Iterable<Commit> results) => commits);

      config = FakeConfig(
        dbValue: db,
        backfillerTargetLimitValue: 2,
        firestoreService: mockFirestoreService,
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

      when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<CommitResponse>.value(CommitResponse());
      });

      scheduler = FakeScheduler(
        config: config,
        ciYaml: batchPolicyConfig,
        githubChecksUtil: mockGithubChecksUtil,
        luciBuildService: FakeLuciBuildService(
          config: config,
          pubsub: pubsub,
          githubChecksUtil: mockGithubChecksUtil,
        ),
      );

      handler = BatchBackfiller(config: config, scheduler: scheduler);

      tester = RequestHandlerTester();
    });

    test('does not backfill on completed task column', () async {
      final allGreen = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusSucceeded),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => allGreen);
      await tester.get(handler);
      expect(pubsub.messages, isEmpty);
    });

    test('does not backfill when there is a running task', () async {
      final middleTaskInProgress = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
        generateTask(2, name: 'Linux_android A', status: Task.statusInProgress),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => middleTaskInProgress);
      await tester.get(handler);
      expect(pubsub.messages, isEmpty);
    });

    test('does not backfill when task does not exist in TOT', () async {
      scheduler = FakeScheduler(
        config: config,
        ciYaml: notInToTConfig,
        githubChecksUtil: mockGithubChecksUtil,
        luciBuildService: FakeLuciBuildService(
          config: config,
          pubsub: pubsub,
          githubChecksUtil: mockGithubChecksUtil,
        ),
      );
      handler = BatchBackfiller(config: config, scheduler: scheduler);
      final allGray = <Task>[
        generateTask(1, name: 'Linux_android B', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => allGray);
      await tester.get(handler);
      expect(pubsub.messages.length, 0);
    });

    test('backfills latest task', () async {
      final allGray = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
        generateTask(2, name: 'Linux_android A', status: Task.statusNew),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => allGray);
      await tester.get(handler);
      expect(pubsub.messages.length, 1);

      final batchRequest = bbv2.BatchRequest.create();
      batchRequest.mergeFromProto3Json(pubsub.messages.first);

      final scheduleBuildRequest = batchRequest.requests.first.scheduleBuild;

      expect(scheduleBuildRequest.priority, LuciBuildService.kBackfillPriority);
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
      final allGray = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusNew),
        generateTask(2, name: 'Linux_android A', status: Task.statusNew),
        generateTask(3, name: 'Linux_android A', status: Task.statusFailed),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => allGray);
      await tester.get(handler);
      expect(pubsub.messages.length, 1);

      final batchRequest = bbv2.BatchRequest.create();
      batchRequest.mergeFromProto3Json(pubsub.messages.first);

      final scheduleBuildRequest = batchRequest.requests.first.scheduleBuild;

      expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);
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
      await tester.get(handler);
      expect(pubsub.messages.length, 1);

      final batchRequest = bbv2.BatchRequest.create();
      batchRequest.mergeFromProto3Json(pubsub.messages.first);

      final scheduleBuildRequest = batchRequest.requests.first.scheduleBuild;

      expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);
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
      await tester.get(handler);
      expect(pubsub.messages.length, 0);
    });

    test('backfills older task', () async {
      final oldestGray = <Task>[
        generateTask(1, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(2, name: 'Linux_android A', status: Task.statusSucceeded),
        generateTask(3, name: 'Linux_android A', status: Task.statusNew),
      ];
      db.addOnQuery<Task>((Iterable<Task> results) => oldestGray);
      await tester.get(handler);
      expect(pubsub.messages.length, 1);
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
      await tester.get(handler);
      expect(db.values.length, 1);
      expect(task.status, Task.statusInProgress);

      final captured =
          verify(mockFirestoreService.writeViaTransaction(captureAny)).captured;
      expect(captured.length, 1);
      final commitResponse = captured[0] as List<Write>;
      expect(commitResponse.length, 1);
      final taskDocuemnt = firestore.Task.fromDocument(
        taskDocument: commitResponse[0].update!,
      );
      expect(taskDocuemnt.status, firestore.Task.statusInProgress);
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
      await tester.get(handler);
      expect(db.values.length, 0);
      expect(pubsub.messages.length, 0);
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
      await tester.get(handler);
      expect(pubsub.messages.length, 1);
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
      await tester.get(handler);
      expect(pubsub.messages.length, 2);
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
        await tester.get(handler);
        expect(pubsub.messages.length, 2);
      },
    );

    group('getFilteredBackfill', () {
      test('backfills high priorty targets first', () async {
        final backfill = <Tuple<Target, FullTask, int>>[
          Tuple(
            generateTarget(1),
            FullTask(generateTask(1), generateCommit(1)),
            LuciBuildService.kRerunPriority,
          ),
          Tuple(
            generateTarget(2),
            FullTask(generateTask(2), generateCommit(2)),
            LuciBuildService.kBackfillPriority,
          ),
          Tuple(
            generateTarget(3),
            FullTask(generateTask(3), generateCommit(3)),
            LuciBuildService.kRerunPriority,
          ),
        ];
        final filteredBackfill = handler.getFilteredBackfill(backfill);
        expect(filteredBackfill.length, 2);
        expect(filteredBackfill[0].third, LuciBuildService.kRerunPriority);
        expect(filteredBackfill[1].third, LuciBuildService.kRerunPriority);
      });
    });
  });
}
