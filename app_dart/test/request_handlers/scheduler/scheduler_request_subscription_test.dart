// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/service/fake_github_service.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late SchedulerRequestSubscription handler;
  late SubscriptionTester tester;

  late MockBuildBucketClient buildBucketClient;
  late FakeGithubService githubService;

  setUp(() async {
    buildBucketClient = MockBuildBucketClient();
    githubService = FakeGithubService();
    handler = SchedulerRequestSubscription(
      cache: CacheService(inMemory: true),
      config: FakeConfig()..githubService = githubService,
      authProvider: FakeAuthenticationProvider(),
      buildBucketClient: buildBucketClient,
      retryOptions: const RetryOptions(maxAttempts: 3, maxDelay: Duration.zero),
    );

    tester = SubscriptionTester(request: FakeHttpRequest());
  });

  test('throws exception when BatchRequest cannot be decoded', () async {
    tester.message = const PushMessage();
    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('schedules request to buildbucket using v2', () async {
    final responseBuilderID = bbv2.BuilderID();
    responseBuilderID.builder = 'Linux A';

    final responseBuild = bbv2.Build();
    responseBuild.id = Int64(12345);
    responseBuild.builder = responseBuilderID;

    // has a list of BatchResponse_Response
    final batchResponse = bbv2.BatchResponse();
    final batchResponseResponse = bbv2.BatchResponse_Response();
    batchResponseResponse.scheduleBuild = responseBuild;
    batchResponse.responses.add(batchResponseResponse);

    when(buildBucketClient.batch(any)).thenAnswer((_) async => batchResponse);

    // We cannot construct the object manually with the protos as we cannot write out
    // the json with all the required double quotes and testing fails.
    const messageData = '''
{
  "requests": [
    {
      "scheduleBuild": {
        "builder": {
          "builder": "Linux A"
        }
      }
    }
  ]
}
''';

    const pushMessage = PushMessage(data: messageData, messageId: '798274983');
    tester.message = pushMessage;
    final body = await tester.post(handler);
    expect(body, Body.empty);
  });

  test('retries schedule build if no response comes back', () async {
    final responseBuilderID = bbv2.BuilderID();
    responseBuilderID.builder = 'Linux A';

    final responseBuild = bbv2.Build();
    responseBuild.id = Int64(12345);
    responseBuild.builder = responseBuilderID;

    // has a list of BatchResponse_Response
    final batchResponse = bbv2.BatchResponse();

    final batchResponseResponse = bbv2.BatchResponse_Response();
    batchResponseResponse.scheduleBuild = responseBuild;

    batchResponse.responses.add(batchResponseResponse);

    var attempt = 0;

    when(buildBucketClient.batch(any)).thenAnswer((_) async {
      attempt += 1;
      if (attempt == 2) {
        return batchResponse;
      }

      return bbv2.BatchResponse().createEmptyInstance();
    });

    const messageData = '''
{
  "requests": [
    {
      "scheduleBuild": {
        "builder": {
          "builder": "Linux A"
        }
      }
    }
  ]
}
''';

    const pushMessage = PushMessage(data: messageData, messageId: '798274983');
    tester.message = pushMessage;
    final body = await tester.post(handler);

    expect(body, Body.empty);
    expect(verify(buildBucketClient.batch(any)).callCount, 2);
    expect(githubService.checkRunUpdates, isEmpty);
  });

  test(
    'acking message and logging error when no response comes back after retry limit',
    () async {
      when(buildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse().createEmptyInstance();
      });

      final data = {
        'requests': [
          {
            'scheduleBuild': {
              'builder': {'builder': 'Linux A'},
              'properties': {'git_url': 'https://github.com/flutter/flutter'},
              'tags': [
                {'key': 'github_checkrun', 'value': '37571271176'},
              ],
            },
          },
        ],
      };

      final pushMessage = PushMessage(
        data: json.encode(data),
        messageId: '798274983',
      );
      tester.message = pushMessage;
      final body = await tester.post(handler);

      final bodyString =
          await utf8.decoder.bind(body.serialize().asyncMap((b) => b!)).join();
      expect(bodyString, 'Failed to schedule builds: (builder: Linux A\n).');
      expect(verify(buildBucketClient.batch(any)).callCount, 3);
      expect(githubService.checkRunUpdates, hasLength(1));
      final checkRun = githubService.checkRunUpdates.first;
      expect(checkRun.conclusion, CheckRunConclusion.failure);
      expect(checkRun.status, CheckRunStatus.completed);
      expect(checkRun.slug.fullName, 'flutter/flutter');
      expect(checkRun.output, isNotNull);
      expect(checkRun.output!.title, 'Failed to schedule build');
      expect(checkRun.output!.summary, '''Failed to schedule `Linux A`:

```
unknown
```
''');

      expect(checkRun.checkRun.id, 37571271176);
      expect(checkRun.checkRun.name, 'Linux A');
    },
  );

  test('records LUCI errors and updates github', () async {
    when(buildBucketClient.batch(any)).thenAnswer((_) async {
      final response = bbv2.BatchResponse().createEmptyInstance();
      bbv2.BatchResponse_Response makeError(int code, String message) {
        final response = bbv2.BatchResponse_Response();
        response.error =
            response.error.createEmptyInstance()
              ..code = code
              ..message = message;

        return response;
      }

      response.responses.add(makeError(5, 'builder not found: "Linux A"'));
      response.responses.add(makeError(5, 'builder not found: "Linux B"'));
      return response;
    });

    final data = {
      'requests': [
        {
          'scheduleBuild': {
            'builder': {'builder': 'Linux A'},
            'properties': {'git_url': 'https://github.com/flutter/flutter'},
            'tags': [
              {'key': 'github_checkrun', 'value': '1234'},
            ],
          },
        },
        {
          'scheduleBuild': {
            'builder': {'builder': 'Linux B'},
            'properties': {'git_url': 'https://github.com/flutter/flutter'},
            'tags': [
              {'key': 'github_checkrun', 'value': '4242'},
            ],
          },
        },
      ],
    };

    final pushMessage = PushMessage(
      data: json.encode(data),
      messageId: '798274983',
    );
    tester.message = pushMessage;
    await tester.post(handler);

    expect(githubService.checkRunUpdates, hasLength(2));
    var checkRun = githubService.checkRunUpdates.first;
    expect(checkRun.checkRun.id, 1234);
    expect(checkRun.output, isNotNull);
    expect(checkRun.output!.summary, '''
Failed to schedule `Linux A`:

```
error: {
  code: 5
  message: builder not found: "Linux A"
}
error: {
  code: 5
  message: builder not found: "Linux B"
}
```
''');
    checkRun = githubService.checkRunUpdates.last;
    expect(checkRun.checkRun.id, 4242);
    expect(checkRun.output, isNotNull);
    expect(checkRun.output!.summary, '''
Failed to schedule `Linux B`:

```
error: {
  code: 5
  message: builder not found: "Linux A"
}
error: {
  code: 5
  message: builder not found: "Linux B"
}
```
''');
  });
}
