// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/github/branch_subscription.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/utilities/mocks.dart';
import '../../src/utilities/webhook_generators.dart';

void main() {
  group('GithubBranchWebhookSubscription', () {
    late GithubBranchWebhookSubscription webhook;
    late FakeHttpRequest request;
    late MockBranchService branchService;
    late SubscriptionTester tester;

    /// Name of an example release base branch name.
    const String kReleaseBaseRef = 'flutter-2.12-candidate.4';

    setUp(() {
      request = FakeHttpRequest();
      branchService = MockBranchService();
      tester = SubscriptionTester(request: request);

      webhook = GithubBranchWebhookSubscription(
        config: FakeConfig(),
        cache: CacheService(inMemory: true),
        branchService: branchService,
      );
    });
    test('process create branch event', () async {
      tester.message = generateCreateBranchMessage(kReleaseBaseRef, Config.flutterSlug.fullName);
      await tester.post(webhook);

      verify(branchService.branchFlutterRecipes(kReleaseBaseRef));
    });

    test('do not create recipe branches on non-flutter/flutter branches', () async {
      tester.message = generateCreateBranchMessage(kReleaseBaseRef, Config.engineSlug.fullName);
      await tester.post(webhook);

      verifyNever(branchService.branchFlutterRecipes(any));
    });

    test('do not process non-create messages', () async {
      tester.message = generateGithubWebhookMessage();
      expect(await tester.post(webhook), Body.empty);

      verifyNever(branchService.branchFlutterRecipes(any));
    });
  });
}
