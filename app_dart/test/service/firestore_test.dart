// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/service/access_client_provider.dart';
import 'package:cocoon_service/src/service/firestore.dart';

import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../src/utilities/entity_generators.dart';

void main() {
  test('creates writes correctly from documents', () async {
    final List<Document> documents = <Document>[
      Document(name: 'd1', fields: <String, Value>{'key1': Value(stringValue: 'value1')}),
      Document(name: 'd2', fields: <String, Value>{'key1': Value(stringValue: 'value2')}),
    ];
    final List<Write> writes = documentsToWrites(documents, exists: false);
    expect(writes.length, documents.length);
    expect(writes[0].update, documents[0]);
    expect(writes[0].currentDocument!.exists, false);
  });

  group('getValueFromFilter', () {
    final FirestoreService firestoreService = FirestoreService(AccessClientProvider());
    test('int object', () async {
      const Object intValue = 1;
      expect(firestoreService.getValueFromFilter(intValue).integerValue, '1');
    });

    test('string object', () async {
      const Object stringValue = 'string';
      expect(firestoreService.getValueFromFilter(stringValue).stringValue, 'string');
    });

    test('bool object', () async {
      const Object boolValue = true;
      expect(firestoreService.getValueFromFilter(boolValue).booleanValue, true);
    });
  });

  group('generateFilter', () {
    final FirestoreService firestoreService = FirestoreService(AccessClientProvider());
    test('a composite filter with a single field filter', () async {
      final Map<String, Object> filterMap = <String, Object>{
        'intField =': 1,
      };
      const String compositeFilterOp = kCompositeFilterOpAnd;
      final Filter filter = firestoreService.generateFilter(filterMap, compositeFilterOp);
      expect(filter.compositeFilter, isNotNull);
      final List<Filter> filters = filter.compositeFilter!.filters!;
      expect(filters.length, 1);
      expect(filters[0].fieldFilter!.field!.fieldPath, 'intField');
      expect(filters[0].fieldFilter!.value!.integerValue, '1');
      expect(filters[0].fieldFilter!.op, kFieldFilterOpEqual);
    });

    test('a composite filter with multiple field filters', () async {
      final Map<String, Object> filterMap = <String, Object>{
        'intField =': 1,
        'stringField =': 'string',
      };
      const String compositeFilterOp = kCompositeFilterOpAnd;
      final Filter filter = firestoreService.generateFilter(filterMap, compositeFilterOp);
      expect(filter.fieldFilter, isNull);
      expect(filter.compositeFilter, isNotNull);
      final List<Filter> filters = filter.compositeFilter!.filters!;
      expect(filters.length, 2);
      expect(filters[0].fieldFilter!.field!.fieldPath, 'intField');
      expect(filters[0].fieldFilter!.value!.integerValue, '1');
      expect(filters[0].fieldFilter!.op, kFieldFilterOpEqual);
      expect(filters[1].fieldFilter!.field!.fieldPath, 'stringField');
      expect(filters[1].fieldFilter!.value!.stringValue, 'string');
      expect(filters[1].fieldFilter!.op, kFieldFilterOpEqual);
    });
  });

  group('documentsFromQueryResponse', () {
    final FirestoreService firestoreService = FirestoreService(AccessClientProvider());
    late List<RunQueryResponseElement> runQueryResponseElements;
    test('when null document returns', () async {
      runQueryResponseElements = <RunQueryResponseElement>[
        RunQueryResponseElement(),
      ];
      final List<Document> documents = firestoreService.documentsFromQueryResponse(runQueryResponseElements);
      expect(documents.isEmpty, true);
    });

    test('when non-null document returns', () async {
      final GithubGoldStatus githubGoldStatus = generateFirestoreGithubGoldStatus(1);
      runQueryResponseElements = <RunQueryResponseElement>[
        RunQueryResponseElement(document: githubGoldStatus),
      ];
      final List<Document> documents = firestoreService.documentsFromQueryResponse(runQueryResponseElements);
      expect(documents.length, 1);
      expect(documents[0].name, githubGoldStatus.name);
    });
  });

  group('generateOrders', () {
    final FirestoreService firestoreService = FirestoreService(AccessClientProvider());
    Map<String, String>? orderMap;
    test('when there is no orderMap', () async {
      orderMap = null;
      final List<Order>? orders = firestoreService.generateOrders(orderMap);
      expect(orders, isNull);
    });

    test('when there is non-null orderMap', () async {
      orderMap = <String, String>{'createTimestamp': kQueryOrderDescending};
      final List<Order>? orders = firestoreService.generateOrders(orderMap);
      expect(orders!.length, 1);
      final Order resultOrder = orders[0];
      expect(resultOrder.direction, kQueryOrderDescending);
      expect(resultOrder.field!.fieldPath, 'createTimestamp');
    });
  });

  group('Update from build bbv2', () {
    test('update succeeds from buildbucket v2', () async {
      final bbv2.BuildsV2PubSub pubSubCallBack = bbv2.BuildsV2PubSub().createEmptyInstance();
      pubSubCallBack.mergeFromProto3Json(jsonDecode(buildMessage) as Map<String, dynamic>);
      final bbv2.Build build = pubSubCallBack.build;

      final Task task = generateFirestoreTask(
        1,
        name: build.builder.builder,
        commitSha: 'asldjflaksdjflkasjdflkasjf',
      );

      task.updateFromBuildV2(build);

      final Write w = Write(
        update: task,
        currentDocument: Precondition(exists: true),
      );

      final BatchWriteRequest batchWriteRequest = BatchWriteRequest(writes: [w]);

      // gives
      /*
{
  "writes":[
    {
      "currentDocument":{
        "exists":true
      },
      "update":{
        "fields":{
          "createTimestamp":{
            "integerValue":"1711582571895"
          },
          "startTimestamp":{
            "integerValue":"1711582578758"
          },
          "endTimestamp":{
            "integerValue":"0"
          },
          "bringup":{
            "booleanValue":false
          },
          "testFlaky":{
            "booleanValue":false
          },
          "status":{
            "stringValue":"In Progress"
          },
          "name":{
            "stringValue":"Mac_arm64 module_test_ios"
          },
          "commitSha":{
            "stringValue":"asldjflaksdjflkasjdflkasjf"
          },
          "buildNumber":{
            "integerValue":"561"
          }
        },
        "name":"asldjflaksdjflkasjdflkasjf_Mac_arm64 module_test_ios_1"
      }
    }
  ]
}
      */
    });

    test('Empty tag', () {
      final bbv2.StringPair stringPair = bbv2.StringPair().createEmptyInstance();
      expect(stringPair.hasKey(), false);
    });
  });

  group('Update from build v1', () {
    test('update succeeds from build', () {
      final BuildPushMessage buildPushMessage = BuildPushMessage.fromJson(jsonDecode(oldBuild) as Map<String, dynamic>);
      final Build? build = buildPushMessage.build;
      final Task task = generateFirestoreTask(
        1,
        name: 'Mac_arm64 module_test_ios',
        commitSha: 'asldjflaksdjflkasjdflkasjf',
      );
      task.updateFromBuild(build!);
    });
  });
}

String buildMessage = '''
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
		"updateTime":  "2024-03-27T23:36:18.758986946Z",
		"status":  "STARTED",
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

String oldBuild = '''
{
  "build":{
    "bucket":"luci.flutter.prod",
    "canary":false,
    "canary_preference":"PROD",
    "completed_ts":"1712774051778864",
    "created_by":"user:flutter-dashboard@appspot.gserviceaccount.com",
    "created_ts":"1712772623529732",
    "experimental":false,
    "id":"8751021449469065793",
    "project":"flutter",
    "result":"SUCCESS",
    "result_details_json":"{\\"properties\\": {\\"got_revision\\": \\"97cd47a02e60a31741a163794120f63a568c0f9f\\"}}",
    "retry_of":"0",
    "service_account":"",
    "started_ts":"1712772642523927",
    "status":"COMPLETED",
    "status_changed_ts":"1712774051778865",
    "tags":[
      "build_address:luci.flutter.prod/Linux_android android_platform_tests_api_33_shard_2 master/561",
      "builder:Linux_android android_platform_tests_api_33_shard_2 master",
      "buildset:commit/git/e98839a9b8de4495c8c333af05d2e81277b56cd8",
      "buildset:commit/gitiles/flutter.googlesource.com/mirrors/packages/+/e98839a9b8de4495c8c333af05d2e81277b56cd8",
      "current_attempt:1",
      "gitiles_ref:refs/heads/main",
      "scheduler_job_id:flutter/Linux_android android_platform_tests_api_33_shard_2 master",
      "swarming_hostname:",
      "swarming_tag:log_location:logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8751021449469065793/+/annotations",
      "swarming_tag:luci_project:flutter",
      "swarming_tag:recipe_name:packages/packages",
      "swarming_tag:recipe_package:flutter/recipe_bundles/flutter.googlesource.com/recipes",
      "swarming_task_id:",
      "user_agent:flutter-cocoon"
    ],
    "updated_ts":"1712774051778864",
    "url":"https://ci.chromium.org/b/8751021449469065793",
    "utcnow_ts":"1712774052428818"
  },
  "hostname":"cr-buildbucket.appspot.com",
  "user_data":"eyJjb21taXRfa2V5IjoiZmx1dHRlci9wYWNrYWdlcy9tYWluL2U5ODgzOWE5YjhkZTQ0OTVjOGMzMzNhZjA1ZDJlODEyNzdiNTZjZDgiLCJ0YXNrX2tleSI6IjY0NTg1ODYwMzkxODk1MDQiLCJmaXJlc3RvcmVfY29tbWl0X2RvY3VtZW50X25hbWUiOiJlOTg4MzlhOWI4ZGU0NDk1YzhjMzMzYWYwNWQyZTgxMjc3YjU2Y2Q4IiwiY2hlY2tfcnVuX2lkIjoyMzY3NDU2MDE4MywiY29tbWl0X3NoYSI6ImU5ODgzOWE5YjhkZTQ0OTVjOGMzMzNhZjA1ZDJlODEyNzdiNTZjZDgiLCJjb21taXRfYnJhbmNoIjoibWFpbiIsImJ1aWxkZXJfbmFtZSI6IkxpbnV4X2FuZHJvaWQgYW5kcm9pZF9wbGF0Zm9ybV90ZXN0c19hcGlfMzNfc2hhcmRfMiBtYXN0ZXIiLCJyZXBvX293bmVyIjoiZmx1dHRlciIsInJlcG9fbmFtZSI6InBhY2thZ2VzIiwiZmlyZXN0b3JlX3Rhc2tfZG9jdW1lbnRfbmFtZSI6ImU5ODgzOWE5YjhkZTQ0OTVjOGMzMzNhZjA1ZDJlODEyNzdiNTZjZDhfTGludXhfYW5kcm9pZCBhbmRyb2lkX3BsYXRmb3JtX3Rlc3RzX2FwaV8zM19zaGFyZF8yIG1hc3Rlcl8xIn0="
}''';
