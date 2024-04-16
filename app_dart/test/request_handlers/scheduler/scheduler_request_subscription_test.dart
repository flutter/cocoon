// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/pubsub_message_v2.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/scheduler_request_subscription.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_v2_tester.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late SchedulerRequestSubscriptionV2 handler;
  late SubscriptionV2Tester tester;

  late MockBuildBucketV2Client buildBucketV2Client;

  setUp(() async {
    buildBucketV2Client = MockBuildBucketV2Client();
    handler = SchedulerRequestSubscriptionV2(
      cache: CacheService(inMemory: true),
      config: FakeConfig(),
      authProvider: FakeAuthenticationProvider(),
      buildBucketClient: buildBucketV2Client,
      retryOptions: const RetryOptions(
        maxAttempts: 3,
        maxDelay: Duration.zero,
      ),
    );

    tester = SubscriptionV2Tester(
      request: FakeHttpRequest(),
    );
  });

  test('throws exception when BatchRequest cannot be decoded', () async {
    tester.message = const PushMessageV2();
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

    when(buildBucketV2Client.batch(any)).thenAnswer((_) async => batchResponse);

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

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: messageData, messageId: '798274983');
    tester.message = pushMessageV2;
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

    when(buildBucketV2Client.batch(any)).thenAnswer((_) async {
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

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: messageData, messageId: '798274983');
    tester.message = pushMessageV2;
    final Body body = await tester.post(handler);

    expect(body, Body.empty);
    expect(verify(buildBucketV2Client.batch(any)).callCount, 2);
  });

  test('acking message and logging error when no response comes back after retry limit', () async {
    when(buildBucketV2Client.batch(any)).thenAnswer((_) async {
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

    const PushMessageV2 pushMessageV2 = PushMessageV2(data: messageData, messageId: '798274983');
    tester.message = pushMessageV2;
    final Body body = await tester.post(handler);

    expect(body, isNotNull);
    expect(verify(buildBucketV2Client.batch(any)).callCount, 3);
  });
}
