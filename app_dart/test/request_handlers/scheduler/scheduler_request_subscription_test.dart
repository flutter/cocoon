// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late SchedulerRequestSubscription handler;
  late SubscriptionTester tester;

  late MockBuildBucketClient buildBucketClient;

  setUp(() async {
    buildBucketClient = MockBuildBucketClient();
    handler = SchedulerRequestSubscription(
      cache: CacheService(inMemory: true),
      config: FakeConfig(),
      authProvider: FakeAuthenticationProvider(),
      buildBucketClient: buildBucketClient,
      retryOptions: const RetryOptions(
        maxAttempts: 3,
        maxDelay: Duration.zero,
      ),
    );

    tester = SubscriptionTester(
      request: FakeHttpRequest(),
    );
  });

  test('throws exception when BatchRequest cannot be decoded', () async {
    tester.message = const PushMessage();
    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('schedules request to buildbucket using v2', () async {
    final bbv2.BuilderID responseBuilderID = bbv2.BuilderID();
    responseBuilderID.builder = 'Linux A';

    final bbv2.Build responseBuild = bbv2.Build();
    responseBuild.id = Int64(12345);
    responseBuild.builder = responseBuilderID;

    // has a list of BatchResponse_Response
    final bbv2.BatchResponse batchResponse = bbv2.BatchResponse();
    final bbv2.BatchResponse_Response batchResponseResponse = bbv2.BatchResponse_Response();
    batchResponseResponse.scheduleBuild = responseBuild;
    batchResponse.responses.add(batchResponseResponse);

    when(buildBucketClient.batch(any)).thenAnswer((_) async => batchResponse);

    // We cannot construct the object manually with the protos as we cannot write out
    // the json with all the required double quotes and testing fails.
    const String messageData = '''
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

    const PushMessage pushMessage = PushMessage(data: messageData, messageId: '798274983');
    tester.message = pushMessage;
    final Body body = await tester.post(handler);
    expect(body, Body.empty);
  });

  test('retries schedule build if no response comes back', () async {
    final bbv2.BuilderID responseBuilderID = bbv2.BuilderID();
    responseBuilderID.builder = 'Linux A';

    final bbv2.Build responseBuild = bbv2.Build();
    responseBuild.id = Int64(12345);
    responseBuild.builder = responseBuilderID;

    // has a list of BatchResponse_Response
    final bbv2.BatchResponse batchResponse = bbv2.BatchResponse();

    final bbv2.BatchResponse_Response batchResponseResponse = bbv2.BatchResponse_Response();
    batchResponseResponse.scheduleBuild = responseBuild;

    batchResponse.responses.add(batchResponseResponse);

    int attempt = 0;

    when(buildBucketClient.batch(any)).thenAnswer((_) async {
      attempt += 1;
      if (attempt == 2) {
        return batchResponse;
      }

      return bbv2.BatchResponse().createEmptyInstance();
    });

    const String messageData = '''
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

    const PushMessage pushMessage = PushMessage(data: messageData, messageId: '798274983');
    tester.message = pushMessage;
    final Body body = await tester.post(handler);

    expect(body, Body.empty);
    expect(verify(buildBucketClient.batch(any)).callCount, 2);
  });

  test('acking message and logging error when no response comes back after retry limit', () async {
    when(buildBucketClient.batch(any)).thenAnswer((_) async {
      return bbv2.BatchResponse().createEmptyInstance();
    });

    const String messageData = '''
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

    const PushMessage pushMessage = PushMessage(data: messageData, messageId: '798274983');
    tester.message = pushMessage;
    final Body body = await tester.post(handler);

    expect(body, isNotNull);
    expect(verify(buildBucketClient.batch(any)).callCount, 3);
  });
}
