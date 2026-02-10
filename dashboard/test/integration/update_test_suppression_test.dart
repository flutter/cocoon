// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:flutter_dashboard/service/appengine_cocoon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github/github.dart';

void main() {
  group('Integration: Update Test Suppression', () {
    late IntegrationServer server;
    late IntegrationHttpClient client;
    late AppEngineCocoonService service;

    setUp(() async {
      final githubService = FakeGithubService();
      githubService.getIssueMock = (slug, {issueNumber}) {
        if (issueNumber == 123) {
          return Future.value(Issue(state: 'open', id: 123, number: 123));
        }
        return null;
      };

      server = IntegrationServer(
        config: FakeConfig(
          webhookKeyValue: 'fake-secret',
          dynamicConfig: DynamicConfig(dynamicTestSuppression: true),
          githubService: githubService,
        ),
      );

      client = IntegrationHttpClient(server);
      service = AppEngineCocoonService(client: client);
    });

    test('suppress and unsuppress a test', () async {
      const repo = 'flutter/flutter';
      const testName = 'linux_android';
      const idToken = 'fake-token';

      // 1. Verify initially empty
      var suppressedTests = await service.fetchSuppressedTests(repo: repo);
      expect(suppressedTests.data, isEmpty);

      // 2. Suppress the test
      final suppressResponse = await service.updateTestSuppression(
        idToken: idToken,
        repo: repo,
        testName: testName,
        suppress: true,
        issueLink: 'https://github.com/flutter/flutter/issues/123',
        note: 'Flaky',
      );
      expect(suppressResponse.error, isNull);

      // 3. Verify it is suppressed
      suppressedTests = await service.fetchSuppressedTests(repo: repo);
      expect(suppressedTests.data, hasLength(1));
      expect(suppressedTests.data!.first.name, testName);

      // 4. Unsuppress the test
      final unsuppressResponse = await service.updateTestSuppression(
        idToken: idToken,
        repo: repo,
        testName: testName,
        suppress: false,
      );
      expect(unsuppressResponse.error, isNull);

      // 5. Verify it is gone
      suppressedTests = await service.fetchSuppressedTests(repo: repo);
      expect(suppressedTests.data, isEmpty);
    });
  });
}
