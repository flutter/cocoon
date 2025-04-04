// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group('Task', () {
    test('disallows illegal status', () {
      final task = Task.fromDocument(
        Document()
          ..name = 'name'
          ..fields = {},
      );
      expect(() => task.setStatus('unknown'), throwsArgumentError);
    });

    test('creates task document correctly from task data model', () async {
      final task = generateTask(1);
      final commitSha = task.commitKey!.id!.split('/').last;
      final taskDocument = Task.fromDatastore(task);
      expect(
        taskDocument.name,
        '$kDatabase/documents/$kTaskCollectionId/${commitSha}_${task.name}_${task.attempts}',
      );
      expect(taskDocument.createTimestamp, task.createTimestamp);
      expect(taskDocument.endTimestamp, task.endTimestamp);
      expect(taskDocument.bringup, task.isFlaky);
      expect(taskDocument.taskName, task.name);
      expect(taskDocument.startTimestamp, task.startTimestamp);
      expect(taskDocument.status, task.status);
      expect(taskDocument.testFlaky, task.isTestFlaky);
      expect(taskDocument.commitSha, commitSha);
    });

    group('updateFromBuild', () {
      test('update succeeds from buildbucket v2', () async {
        final pubSubCallBack = bbv2.BuildsV2PubSub().createEmptyInstance();
        pubSubCallBack.mergeFromProto3Json(
          jsonDecode(buildBucketMessage) as Map<String, dynamic>,
        );
        final build = pubSubCallBack.build;

        final task = generateFirestoreTask(
          1,
          name: build.builder.builder,
          commitSha: 'asldjflaksdjflkasjdflkasjf',
        );

        final createTimeDateTime = DateTime.parse(
          '2024-03-27T23:36:11.895266929Z',
        );
        final startTimeDateTime = DateTime.parse(
          '2024-03-27T23:36:18.758986946Z',
        );
        final endTimeDateTime = DateTime.parse(
          '2024-03-27T23:51:20.758986946Z',
        );

        expect(task.status, Task.statusNew);
        expect(task.buildNumber, isNull);
        expect(task.endTimestamp, 0);
        expect(task.createTimestamp, 0);
        expect(task.startTimestamp, 0);

        task.updateFromBuild(build);
        expect(task.status, 'Succeeded');

        expect(task.buildNumber, 561);
        expect(task.createTimestamp, createTimeDateTime.millisecondsSinceEpoch);
        expect(task.startTimestamp, startTimeDateTime.millisecondsSinceEpoch);
        expect(task.endTimestamp, endTimeDateTime.millisecondsSinceEpoch);
      });
    });
  });

  // TODO(chillers): There is a bug where `dart test` does not work in offline mode.
  // Need to file issue and get traces.
  group('Task.fromFirestore', () {
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    test('generates task correctly', () async {
      final firestoreTask = generateFirestoreTask(1);
      when(mockFirestoreService.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<Document>.value(firestoreTask);
      });
      final resultedTask = await Task.fromFirestore(
        mockFirestoreService,
        TaskId(commitSha: 'abc123', taskName: 'test', currentAttempt: 1),
      );
      expect(resultedTask.name, firestoreTask.name);
      expect(resultedTask.fields, firestoreTask.fields);
    });
  });

  group('resert as retry', () {
    test('success', () {
      final task = generateFirestoreTask(
        1,
        status: Task.statusFailed,
        testFlaky: true,
      );
      task.resetAsRetry(attempt: 2);

      expect(int.parse(task.name!.split('_').last), 2);
      expect(task.status, Task.statusNew);
      expect(task.testFlaky, false);
    });
  });

  group('TaskId', () {
    test('can parse a documentId', () {
      final documentId =
          'f2e0a2afb35cefe48600c81f39e163db00cff89f_'
          'Linux android_java17_dependency_smoke_tests_'
          '1';

      expect(
        TaskId.tryParse(documentId),
        TaskId(
          commitSha: 'f2e0a2afb35cefe48600c81f39e163db00cff89f',
          taskName: 'Linux android_java17_dependency_smoke_tests',
          currentAttempt: 1,
        ),
      );
    });

    test('can parse a documentId with multiple _s', () {
      final documentId =
          'e971379436d426324f4a02fe2b1bfdb24a261764_'
          'Mac_x64_ios hot_mode_dev_cycle_ios__benchmark_'
          '1';

      expect(
        TaskId.tryParse(documentId),
        TaskId(
          commitSha: 'e971379436d426324f4a02fe2b1bfdb24a261764',
          taskName: 'Mac_x64_ios hot_mode_dev_cycle_ios__benchmark',
          currentAttempt: 1,
        ),
      );
    });
  });
}

String buildBucketMessage = '''
{
	"build":  {
		"id":  "8752269309051025889",
		"builder":  {
			"project":  "flutter-dashboard",
			"bucket":  "flutter",
			"builder":  "Mac_arm64 module_test_ios"
		},
		"number":  561,
		"createdBy":  "user:dart-internal-flutter-engine@dart-ci-internal.iam.gserviceaccount.com",
		"createTime":  "2024-03-27T23:36:11.895266929Z",
		"startTime":  "2024-03-27T23:36:18.758986946Z",
		"updateTime":  "2024-03-27T23:51:20.758986946Z",
    "endTime": "2024-03-27T23:51:20.758986946Z",
		"status":  "SUCCESS",
		"tags":  [
			{
				"key":  "buildset",
				"value":  "commit/gitiles/flutter.googlesource.com/mirrors/engine/+/e76c956498841e1ab458577d3892003e553e4f3c"
			},
			{
				"key":  "parent_buildbucket_id",
				"value":  "8752269371711734033"
			},
			{
				"key":  "parent_task_id",
				"value":  "689b160e60417e11"
			},
			{
				"key":  "user_agent",
				"value":  "recipe"
			},
      {
        "key": "build_address",
        "value": "luci.flutter.prod/Mac_arm64 module_test_ios/271"
      }
		],
		"exe":  {
			"cipdPackage":  "flutter/recipe_bundles/flutter.googlesource.com/recipes",
			"cipdVersion":  "refs/heads/flutter-3.19-candidate.1",
			"cmd":  [
				"luciexe"
			]
		},
		"schedulingTimeout":  "21600s",
		"executionTimeout":  "14400s",
		"gracePeriod":  "30s",
		"ancestorIds":  [
			"8752269474035875297",
			"8752269371711734033"
		]
	},
	"buildLargeFields":  "eJycVE+LI8UbTvdMksmbX+aXVBh2tmYXg66CwdqazcyusjCoC+LJk6jHslL1JqlNd1VbVZ2ZnZsieBE8eBSEBb+AB8GzX0PRs99CunsyCC7+2T4V1PO8/dbzPs97+SvAzwC3oeNRmQLJmI7QLo1FsZnxeWkyjR4m0FfOLsxSWJkjGdH/51KJlQtRNGA4hdFSZQZtFBvpjZxnGMgL09twBAfandvMSS2k1d4ZLTQWgaSTFhxAX+PGKBTxSYGkQ3etswg3Yewx+ifCbdB7o1FkJkSS0hbcgIHHDGVAUTdXcaIvEQbQtU4sXS5JOklgH3ZUUZIubUufPziF3zvQbgi/daa/dGAJ6dISORPQpW3GcqmgT3v1gamihGvikO4z5ksbTY4sdxqhR7tXLQDQPcasY1l0cEDHjBUeq79EpqWPLOg1HMFurdmYjirNts03xX9KoG2NfSzJj8n0h6QaQ6Pzs+FfJ9CN0i8xBvJFMvs8gSN6c5GVMaLn0bks8IWzUYRyHjDCi3SyvayfzqVXK7PB8FD6aBZSxQBv0ze3mLDCLONFJuPC+Zxr6c+N5blULjy8NIWoT+IKLRZe5nju/BoeARTeFeijwUBOpzM4huGdbVUXLkTQa3JrSuEQ+kGvxQZ9MM6SHu3eO8WT42P1T/77PoW9bfPku3T2NIVv0+k3KQxgt3ZOm+4sVYAZ9OaVXIWMK/IyfcmVkf9FRl49ZluNw9MEBsaqrNQNL5CvktmXSaXMv6A3KrHmphKfNeLfvTQFvEvf+Y8l2BWOX0+oLvS3JjqAtkeZ5eR/tBqELlU0zsIjGGrvLAptcrSV4IHcnb0GhA7/lLmzOnB92nPh7D2p2L2Tyt+qKM8u3njwnKm+AZ25i8JoMqD9KlAn99nq/uz15/DFIexLrUXjjSDUJ9d5P4R+7Q5b5nP0pDdqVd/Hn74FGYzvNISr5cRrO3wwfR9egb2IeSG08YTSQ/6hy8ocA//I+TUP/Jwbzy94hFehp6RaYQ28RekzgTUChtCrlo547OaB7NDkuNpEKnPzqqt00vosaf0RAAD//yypqMk="
}
''';
