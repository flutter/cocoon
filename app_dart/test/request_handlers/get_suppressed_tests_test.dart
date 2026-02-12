// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:test/test.dart';

import '../src/request_handling/api_request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late GetSuppressedTests handler;
  late FakeConfig config;

  final fakeNow = DateTime.now().toUtc();

  setUp(() {
    firestore = FakeFirestoreService();
    tester = ApiRequestHandlerTester();
    config = FakeConfig(
      dynamicConfig: DynamicConfig(dynamicTestSuppression: true),
    );

    handler = GetSuppressedTests(config: config, firestore: firestore);
  });

  test('throws MethodNotAllowed if feature flag is disabled', () async {
    config = FakeConfig(
      dynamicConfig: DynamicConfig(dynamicTestSuppression: false),
    );
    handler = GetSuppressedTests(config: config, firestore: firestore);

    final response = await tester.get(handler);
    final body = await utf8.decodeStream(response.body);
    expect(body, '[]');
  });

  test('returns empty list if no suppressed tests', () async {
    final response = await tester.get(handler);
    final body = await utf8.decodeStream(response.body);
    expect(body, '[]');
  });

  test('returns suppressed tests for default repo', () async {
    final doc = SuppressedTest(
      name: 'foo_test',
      repository: 'flutter/flutter',
      issueLink: 'https://github.com/flutter/flutter/issues/123',
      isSuppressed: true,
      createTimestamp: fakeNow,
      updates: [],
    )..name = '$kDatabase/documents/${SuppressedTest.kCollectionId}/foo_test';
    firestore.putDocument(doc);

    // Add a non-suppressed test
    final doc2 = SuppressedTest(
      name: 'bar_test',
      repository: 'flutter/flutter',
      issueLink: 'https://github.com/flutter/flutter/issues/456',
      isSuppressed: false,
      createTimestamp: fakeNow,
      updates: [],
    )..name = '$kDatabase/documents/${SuppressedTest.kCollectionId}/bar_test';
    firestore.putDocument(doc2);

    final response = await tester.get(handler);
    final body = await utf8.decodeStream(response.body);
    final json = jsonDecode(body) as List<dynamic>;

    expect(json.length, 1);
    expect(json[0]['name'], 'foo_test');
    expect(json[0]['repository'], 'flutter/flutter');
    expect(
      json[0]['issueLink'],
      'https://github.com/flutter/flutter/issues/123',
    );
  });

  test('returns suppressed tests for specific repo', () async {
    tester.request.uri = Uri(queryParameters: {'repo': 'flutter/engine'});

    firestore.putDocuments([
      SuppressedTest(
          name: 'engine_test',
          repository: 'flutter/engine',
          issueLink: 'https://github.com/flutter/flutter/issues/789',
          isSuppressed: true,
          createTimestamp: fakeNow,
          updates: [],
        )
        ..name =
            '$kDatabase/documents/${SuppressedTest.kCollectionId}/engine_test',
      SuppressedTest(
          name: 'engine_test2',
          repository: 'flutter/engine',
          issueLink: 'https://github.com/flutter/flutter/issues/123',
          isSuppressed: true,
          createTimestamp: fakeNow,
          updates: [
            {
              'user': 'fake@example.com',
              'note': 'This is a note',
              'updateTimestamp': fakeNow.toUtc(),
              'action': 'SUPPRESS',
            },
            {
              'user': 'fu@example.com',
              'note': 'this is an update',
              'updateTimestamp': fakeNow.toUtc().add(
                const Duration(minutes: 42),
              ),
              'action': 'SUPPRESS',
            },
          ],
        )
        ..name =
            '$kDatabase/documents/${SuppressedTest.kCollectionId}/engine_test2',
    ]);

    final response = await tester.get(handler);
    final body = await utf8.decodeStream(response.body);
    final json = jsonDecode(body) as List<dynamic>;

    expect(json.length, 2);
    expect(json[0]['name'], 'engine_test');
    expect(json[0]['repository'], 'flutter/engine');
    expect(json[1]['name'], 'engine_test2');
    expect(json[1]['repository'], 'flutter/engine');

    final updates = json[1]['updates'] as List<dynamic>;
    expect(updates.length, 2);
    expect(updates[0]['user'], 'fake@example.com');
    expect(updates[0]['updateTimestamp'], fakeNow.millisecondsSinceEpoch);
    expect(updates[1]['user'], 'fu@example.com');
    expect(
      updates[1]['updateTimestamp'],
      fakeNow.add(const Duration(minutes: 42)).millisecondsSinceEpoch,
    );
  });
}
