// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:gcloud/pubsub.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_v2_tester.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late SchedulerRequestSubscription handler;
  late SubscriptionV2Tester tester;

  late MockBuildBucketV2Client buildBucketV2Client;

  setUp(() async {
    buildBucketV2Client = MockBuildBucketV2Client();
    handler = SchedulerRequestSubscription(
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
    final bbv2.BatchRequest request = bbv2.BatchRequest();
    tester.message = Message.withString(request.toString());
    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('schedules request to buildbucket', () async {
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
    
    final bbv2.BatchRequest request = bbv2.BatchRequest();
    
    final bbv2.ScheduleBuildRequest scheduleBuildRequest = bbv2.ScheduleBuildRequest();
    final bbv2.BuilderID builderID = bbv2.BuilderID();
    builderID.builder = 'Linux A';
    scheduleBuildRequest.builder = builderID;

    final bbv2.BatchRequest_Request batchRequestRequest = bbv2.BatchRequest_Request.create();
    batchRequestRequest.scheduleBuild = scheduleBuildRequest;

    request.requests.add(batchRequestRequest);

    tester.message = Message.withString(request.writeToJson());
    final Body body = await tester.post(handler);
    expect(body, Body.empty);
  });

  test('Object creation test', () {
    final bbv2.BatchRequest batchRequest = bbv2.BatchRequest.create();
    final bbv2.BatchRequest_Request batchRequestRequest = bbv2.BatchRequest_Request();
    final List<bbv2.BatchRequest_Request> requestList = batchRequest.requests;
    expect(requestList.isEmpty, isTrue);
    requestList.add(batchRequestRequest);
    expect(requestList.length, 1);
    requestList.clear();
    expect(requestList.length, isZero);
    expect(batchRequest.requests.length, isZero);
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


    final bbv2.BatchRequest request = bbv2.BatchRequest();
    
    final bbv2.ScheduleBuildRequest scheduleBuildRequest = bbv2.ScheduleBuildRequest();
    
    final bbv2.BuilderID requestBuilderID = bbv2.BuilderID();
    requestBuilderID.builder = 'Linux A';
    scheduleBuildRequest.builder = requestBuilderID;

    final bbv2.BatchRequest_Request batchRequestRequest = bbv2.BatchRequest_Request();
    batchRequestRequest.scheduleBuild = scheduleBuildRequest;

    request.requests.add(batchRequestRequest);

    tester.message = Message.withString(request.writeToJson());
    final Body body = await tester.post(handler);

    expect(body, Body.empty);
    expect(verify(buildBucketV2Client.batch(any)).callCount, 2);
  });

  test('acking message and logging error when no response comes back after retry limit', () async {
    when(buildBucketV2Client.batch(any)).thenAnswer((_) async {
      return bbv2.BatchResponse().createEmptyInstance();
    });

    final bbv2.BatchRequest request = bbv2.BatchRequest();

    final bbv2.ScheduleBuildRequest scheduleBuildRequest = bbv2.ScheduleBuildRequest();
    final bbv2.BuilderID builderID = bbv2.BuilderID();
    builderID.builder = 'Linux A';
    scheduleBuildRequest.builder = builderID;

    final bbv2.BatchRequest_Request batchRequestRequest = bbv2.BatchRequest_Request.create();
    batchRequestRequest.scheduleBuild = scheduleBuildRequest;

    request.requests.add(batchRequestRequest);

    tester.message = Message.withString(request.writeToJson());
    final Body body = await tester.post(handler);

    expect(body, isNotNull);
    expect(verify(buildBucketV2Client.batch(any)).callCount, 3);
  });
}
