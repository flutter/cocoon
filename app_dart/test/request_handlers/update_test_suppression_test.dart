// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/suppressed_test.dart';
import 'package:cocoon_service/src/request_handlers/update_test_suppression.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/service/fake_github_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late UpdateSuppressedTest handler;
  late FakeConfig config;
  late FakeGithubServiceWithIssue githubService;

  final fakeNow = DateTime.now().toUtc();

  setUp(() {
    firestore = FakeFirestoreService();
    tester = ApiRequestHandlerTester();
    githubService = FakeGithubServiceWithIssue();

    // Enable feature flag by default for most tests
    final dynamicConfig = DynamicConfig.fromJson({
      'dynamicTestSuppression': true,
    });

    config = FakeConfig(
      githubService: githubService,
      dynamicConfig: dynamicConfig,
    );

    handler = UpdateSuppressedTest(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(),
      firestore: firestore,
      now: () => fakeNow,
    );
  });

  test('throws MethodNotAllowed if feature flag is disabled', () async {
    config.dynamicConfig = DynamicConfig.fromJson({
      'dynamicTestSuppression': false,
    });

    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'SUPPRESS',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
    });

    await expectLater(tester.post(handler), throwsA(isA<MethodNotAllowed>()));
  });

  test('throws BadRequestException if missing parameters', () async {
    tester.request.body = jsonEncode({
      'testName': 'my_test',
      // Missing repository, action, issueLink
    });

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('throws BadRequestException if invalid action', () async {
    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'INVALID',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
    });

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('throws BadRequestException if invalid issue link', () async {
    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'SUPPRESS',
      'issueLink': 'https://example.com/flutter/flutter/issuez/abcd',
    });

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('throws BadRequestException if issue not found (SUPPRESS)', () async {
    githubService.issueResponse = null; // Issue not found

    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'SUPPRESS',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
    });

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('throws BadRequestException if issue closed (SUPPRESS)', () async {
    githubService.issueResponse = Issue(state: 'closed');

    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'SUPPRESS',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
    });

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('creates new suppression if not exists (SUPPRESS)', () async {
    githubService.issueResponse = Issue(state: 'open');

    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'SUPPRESS',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
      'note': 'This is a note',
    });

    await tester.post(handler);

    // Verify document created
    expect(
      firestore,
      existsInStorage(SuppressedTest.metadata, [
        isSuppressedTest
            .hasIssueLink('https://github.com/flutter/flutter/issues/123')
            .hasTestName('my_test')
            .hasRepository('flutter/flutter')
            .hasIsSuppressed(isTrue)
            .hasCreateTimestamp(fakeNow.toUtc())
            .hasUpdates([
              {
                'user': 'fake@example.com',
                'note': 'This is a note',
                'updateTimestamp': fakeNow.toUtc(),
                'action': 'SUPPRESS',
              },
            ]),
      ]),
    );
  });

  test('Creates a new record for new suppressions', () async {
    githubService.issueResponse = Issue(state: 'open');

    // Pre-populate existing suppression (unsuppressed or suppressed)
    final existingDoc = SuppressedTest(
      name: 'my_test',
      repository: 'flutter/flutter',
      issueLink: 'https://github.com/flutter/flutter/issues/old',
      isSuppressed: false,
      createTimestamp: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      updates: [],
    )..name = '$kDatabase/documents/${SuppressedTest.kCollectionId}/existing_doc';
    firestore.putDocument(existingDoc);

    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'SUPPRESS',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
    });

    await tester.post(handler);

    // Verify it is now suppressed and has updates
    expect(
      firestore,
      existsInStorage(SuppressedTest.metadata, [
        isSuppressedTest
            .hasIssueLink('https://github.com/flutter/flutter/issues/old')
            .hasTestName('my_test')
            .hasRepository('flutter/flutter')
            .hasIsSuppressed(isFalse)
            .hasCreateTimestamp(
              DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
            ),
        isSuppressedTest
            .hasIssueLink('https://github.com/flutter/flutter/issues/123')
            .hasTestName('my_test')
            .hasRepository('flutter/flutter')
            .hasIsSuppressed(isTrue)
            .hasCreateTimestamp(fakeNow.toUtc()),
      ]),
    );
  });

  test('unsuppress works', () async {
    githubService.issueResponse = Issue(state: 'closed');

    final earlier = fakeNow.subtract(const Duration(hours: 1)).toUtc();

    // Pre-populate existing suppression (unsuppressed or suppressed)
    final existingDoc = SuppressedTest(
      name: 'my_test',
      repository: 'flutter/flutter',
      issueLink: 'https://github.com/flutter/flutter/issues/123',
      isSuppressed: true,
      createTimestamp: earlier,
      updates: [
        {
          'user': 'fake@example.com',
          'note': 'This is a note',
          'updateTimestamp': earlier,
          'action': 'SUPPRESS',
        },
      ],
    )..name = '$kDatabase/documents/${SuppressedTest.kCollectionId}/existing_doc';
    firestore.putDocument(existingDoc);

    tester.request.body = jsonEncode({
      'testName': 'my_test',
      'repository': 'flutter/flutter',
      'action': 'UNSUPPRESS',
      'issueLink': 'https://github.com/flutter/flutter/issues/123',
      'note': 'Closing issue',
    });

    await tester.post(handler);

    // Verify it is now suppressed and has updates
    expect(
      firestore,
      existsInStorage(SuppressedTest.metadata, [
        isSuppressedTest
            .hasIssueLink('https://github.com/flutter/flutter/issues/123')
            .hasTestName('my_test')
            .hasRepository('flutter/flutter')
            .hasIsSuppressed(isFalse)
            .hasCreateTimestamp(earlier)
            .hasUpdates([
              {
                'user': 'fake@example.com',
                'note': 'This is a note',
                'updateTimestamp': earlier,
                'action': 'SUPPRESS',
              },
              {
                'user': 'fake@example.com',
                'note': 'Closing issue',
                'updateTimestamp': fakeNow.toUtc(),
                'action': 'UNSUPPRESS',
              },
            ]),
      ]),
    );
  });
}

class FakeGithubServiceWithIssue extends FakeGithubService {
  Issue? issueResponse;

  @override
  Future<Issue>? getIssue(RepositorySlug slug, {int? issueNumber}) {
    if (issueResponse == null) {
      return null;
    }
    return Future.value(issueResponse!);
  }
}
