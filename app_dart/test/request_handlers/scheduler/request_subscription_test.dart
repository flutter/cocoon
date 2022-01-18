// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/google/grpc.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late SchedulerRequestSubscription handler;
  late SubscriptionTester tester;

  late MockBuildBucketClient buildBucketClient;

  setUp(() async {
    buildBucketClient = MockBuildBucketClient();
    when(buildBucketClient.batch(any)).thenAnswer((_) async => const BatchResponse());
    handler = SchedulerRequestSubscription(
      cache: CacheService(inMemory: true),
      config: FakeConfig(),
      authProvider: FakeAuthenticationProvider(),
      buildBucketClient: buildBucketClient,
    );
    tester = SubscriptionTester(
      request: FakeHttpRequest(),
    );
  });

  test('throws exception when BatchRequest cannot be decoded', () async {
    tester.message = const PushMessage();
    expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
  });

  test('schedules request to buildbucket', () async {
    const BatchRequest request = BatchRequest();
    tester.message = PushMessage(data: base64Encode(utf8.encode(jsonEncode(request))));
    final Body body = await tester.post(handler);
    expect(body, Body.empty);
  });

  test('retry requests to buildbucket', () async {
    int attempt = 0;
    when(buildBucketClient.batch(any)).thenAnswer((_) async {
      final List<Response> responses = <Response>[];
      responses.add(Response(
        scheduleBuild: generateBuild(
          0,
          name: 'Linux A',
        ),
        error: attempt == 0 ? const GrpcStatus(code: 1, message: 'error :(') : null,
      ));
      attempt += 1;
      return BatchResponse(responses: responses);
    });
    const BatchRequest request = BatchRequest(
      requests: <Request>[
        Request(
          scheduleBuild: ScheduleBuildRequest(
            builderId: BuilderId(builder: 'Linux A'),
          ),
        ),
      ],
    );
    tester.message = PushMessage(data: jsonEncode(request));
    final Body body = await tester.post(handler);
    expect(body, Body.empty);
    verify(buildBucketClient.batch(any)).called(2);
  });
}
