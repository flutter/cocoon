// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/presubmit_build_test_subscription.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_authentication.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/service/fake_luci_build_service.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';
import '../../src/utilities/push_message.dart';

void main() {
  late PresubmitBuildTestSubscription handler;
  late FakeConfig config;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockGithubChecksUtil mockGithubChecksUtil;

  setUp(() async {
    config = FakeConfig(maxLuciTaskRetriesValue: 3);
    mockGithubChecksUtil = MockGithubChecksUtil();
    when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
        .thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));
    final FakeLuciBuildService luciBuildService = FakeLuciBuildService(
      config: config,
      githubChecksUtil: mockGithubChecksUtil,
    );
    handler = PresubmitBuildTestSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      authProvider: FakeAuthenticationProvider(),
      scheduler: FakeScheduler(
        ciYaml: buildTestConfig,
        config: config,
        luciBuildService: luciBuildService,
      ),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );
  });

  test('ack empty messages', () async {
    tester.message = const PushMessage(data: '{}');

    expect(await tester.post(handler), Body.empty);
  });

  test('ack when there is no repo info', () async {
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux build',
    );
    expect(await tester.post(handler), Body.empty);
  });

  test('ack when there are no dependencies', () async {
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux test',
    );
    expect(await tester.post(handler), Body.empty);
  });

  test('ack when not a successful build', () async {
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((_) async => generateCheckRun(1));
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'FAILURE',
      builderName: 'Linux build',
      userData: '{\\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"cocoon\\"}',
    );
    expect(await tester.post(handler), Body.empty);
  });

  test('schedule dependencies', () async {
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((_) async => generateCheckRun(1));
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux build',
      userData: '{\\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"flutter\\", \\"commit_branch\\": \\"master\\"}',
    );
    await tester.post(handler);
    verify(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        'Linux test',
        output: anyNamed('output'),
      ),
    ).called(1);
  });
}
