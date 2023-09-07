// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/subscription_tester.dart';
import '../src/service/fake_buildbucket.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

const String ref = 'deadbeef';

void main() {
  late PresubmitLuciSubscription handler;
  late FakeBuildBucketClient buildbucket;
  late FakeConfig config;
  late MockGitHub mockGitHubClient;
  late FakeHttpRequest request;
  late SubscriptionTester tester;
  late MockRepositoriesService mockRepositoriesService;
  late MockGithubChecksService mockGithubChecksService;

  setUp(() async {
    config = FakeConfig();
    buildbucket = FakeBuildBucketClient();

    mockGithubChecksService = MockGithubChecksService();
    handler = PresubmitLuciSubscription(
      cache: CacheService(inMemory: true),
      config: config,
      buildBucketClient: buildbucket,
      luciBuildService: FakeLuciBuildService(config: config),
      githubChecksService: mockGithubChecksService,
      authProvider: FakeAuthenticationProvider(),
    );
    request = FakeHttpRequest();

    tester = SubscriptionTester(
      request: request,
    );

    mockGitHubClient = MockGitHub();
    mockRepositoriesService = MockRepositoriesService();
    when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
    config.githubClient = mockGitHubClient;
  });

  test('Requests without repo_owner and repo_name do not update checks', () async {
    tester.message = pushMessageJsonNoBuildset(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
    );

    await tester.post(handler);
    verifyNever(mockGithubChecksService.updateCheckStatus(any, any, any));
  });

  test('Requests with repo_owner and repo_name update checks', () async {
    when(mockGithubChecksService.updateCheckStatus(any, any, any)).thenAnswer((_) async => true);
    tester.message = createBuildbucketPushMessage(
      'COMPLETED',
      result: 'SUCCESS',
      builderName: 'Linux Host Engine',
      userData: '{\\"repo_owner\\": \\"flutter\\", \\"repo_name\\": \\"cocoon\\"}',
    );
    await tester.post(handler);
    verify(mockGithubChecksService.updateCheckStatus(any, any, any)).called(1);
  });
}
