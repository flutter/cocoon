// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handlers/github/branch_subscription.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/utilities/mocks.dart';
import '../../src/utilities/webhook_generators.dart';

void main() {
  late GithubBranchWebhookSubscription webhook;
  late SubscriptionTester tester;
  late MockBranchService branchService;
  late MockCommitService commitService;

  setUp(() {
    branchService = MockBranchService();
    commitService = MockCommitService();
    webhook = GithubBranchWebhookSubscription(
      config: MockConfig(),
      cache: CacheService(inMemory: true),
      commitService: commitService,
      branchService: branchService,
    );
    tester = SubscriptionTester(request: FakeHttpRequest());
  });

  group('branch subscription', () {
    test('Ignores empty message', () async {
      tester.message = const PushMessage();

      await tester.post(webhook);

      verifyNever(branchService.handleCreateRequest(any)).called(0);
      verifyNever(commitService.handleCreateGithubRequest(any)).called(0);
    });

    test('Ignores webhook message from event that is not "create"', () async {
      tester.message = generateGithubWebhookMessage(
        event: 'pull_request',
      );

      await tester.post(webhook);

      verifyNever(branchService.handleCreateRequest(any)).called(0);
      verifyNever(commitService.handleCreateGithubRequest(any)).called(0);
    });

    test('Successfully stores branch in datastore and does not create a new commit due to not being a candidate branch',
        () async {
      tester.message = generateCreateBranchMessage(
        'cool-branch',
        'flutter/flutter',
      );

      await tester.post(webhook);

      verify(branchService.handleCreateRequest(any)).called(1);
      verifyNever(commitService.handleCreateGithubRequest(any)).called(0);
    });

    test('Successfully stores branch in datastore and creates a new commit due to being a candidate branch', () async {
      tester.message = generateCreateBranchMessage(
        'flutter-1.2-candidate.3',
        'flutter/flutter',
      );

      await tester.post(webhook);

      verify(branchService.handleCreateRequest(any)).called(1);
      verify(commitService.handleCreateGithubRequest(any)).called(1);
    });
  });
}
