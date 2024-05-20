// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart' as datastore;
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group('Task', () {
    test('disallows illegal status', () {
      final Task task = Task();
      expect(() => task.setStatus('unknown'), throwsArgumentError);
    });

    test('creates task document correctly from task data model', () async {
      final datastore.Task task = generateTask(1);
      final String commitSha = task.commitKey!.id!.split('/').last;
      final Task taskDocument = taskToDocument(task);
      expect(taskDocument.name, '$kDatabase/documents/$kTaskCollectionId/${commitSha}_${task.name}_${task.attempts}');
      expect(taskDocument.createTimestamp, task.createTimestamp);
      expect(taskDocument.endTimestamp, task.endTimestamp);
      expect(taskDocument.bringup, task.isFlaky);
      expect(taskDocument.taskName, task.name);
      expect(taskDocument.startTimestamp, task.startTimestamp);
      expect(taskDocument.status, task.status);
      expect(taskDocument.testFlaky, task.isTestFlaky);
      expect(taskDocument.commitSha, commitSha);
    });

    test('creates task documents correctly from targets', () async {
      final Commit commit = generateCommit(1);
      final List<Target> targets = <Target>[
        generateTarget(1, platform: 'Mac'),
        generateTarget(2, platform: 'Linux'),
      ];
      final List<Task> taskDocuments = targetsToTaskDocuments(commit, targets);
      expect(taskDocuments.length, 2);
      expect(
        taskDocuments[0].name,
        '$kDatabase/documents/$kTaskCollectionId/${commit.sha}_${targets[0].value.name}_$kTaskInitialAttempt',
      );
      expect(taskDocuments[0].fields![kTaskCreateTimestampField]!.integerValue, commit.timestamp.toString());
      expect(taskDocuments[0].fields![kTaskEndTimestampField]!.integerValue, '0');
      expect(taskDocuments[0].fields![kTaskBringupField]!.booleanValue, false);
      expect(taskDocuments[0].fields![kTaskNameField]!.stringValue, targets[0].value.name);
      expect(taskDocuments[0].fields![kTaskStartTimestampField]!.integerValue, '0');
      expect(taskDocuments[0].fields![kTaskStatusField]!.stringValue, Task.statusNew);
      expect(taskDocuments[0].fields![kTaskTestFlakyField]!.booleanValue, false);
      expect(taskDocuments[0].fields![kTaskCommitShaField]!.stringValue, commit.sha);
    });

    group('updateFromBuild', () {
      test('update succeeds from buildbucket v2', () async {
        final bbv2.BuildsV2PubSub pubSubCallBack = bbv2.BuildsV2PubSub().createEmptyInstance();
        pubSubCallBack.mergeFromProto3Json(jsonDecode(buildBucketMessage) as Map<String, dynamic>);
        final bbv2.Build build = pubSubCallBack.build;

        final Task task = generateFirestoreTask(
          1,
          name: build.builder.builder,
          commitSha: 'asldjflaksdjflkasjdflkasjf',
        );

        final DateTime createTimeDateTime = DateTime.parse('2024-03-27T23:36:11.895266929Z');
        final DateTime startTimeDateTime = DateTime.parse('2024-03-27T23:36:18.758986946Z');
        final DateTime endTimeDateTime = DateTime.parse('2024-03-27T23:51:20.758986946Z');

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
      final Task firestoreTask = generateFirestoreTask(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Document>.value(
          firestoreTask,
        );
      });
      final Task resultedTask = await Task.fromFirestore(
        firestoreService: mockFirestoreService,
        documentName: 'test',
      );
      expect(resultedTask.name, firestoreTask.name);
      expect(resultedTask.fields, firestoreTask.fields);
    });
  });

  group('resert as retry', () {
    test('success', () {
      final Task task = generateFirestoreTask(
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

  test('task facade', () {
    final Task taskDocument = generateFirestoreTask(1);
    final Map<String, dynamic> expectedResult = <String, dynamic>{
      kTaskDocumentName: taskDocument.name,
      kTaskCommitSha: taskDocument.commitSha,
      kTaskCreateTimestamp: taskDocument.createTimestamp,
      kTaskStartTimestamp: taskDocument.startTimestamp,
      kTaskEndTimestamp: taskDocument.endTimestamp,
      kTaskTaskName: taskDocument.taskName,
      kTaskAttempts: taskDocument.attempts,
      kTaskBringup: taskDocument.bringup,
      kTaskTestFlaky: taskDocument.testFlaky,
      kTaskBuildNumber: taskDocument.buildNumber,
      kTaskStatus: taskDocument.status,
    };
    expect(taskDocument.facade, expectedResult);
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
