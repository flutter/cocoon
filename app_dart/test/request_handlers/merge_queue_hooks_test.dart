// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/github_webhook_message.dart';
import 'package:cocoon_service/src/request_handlers/merge_queue_hooks.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late MergeQueueHooks handler;

  setUp(() {
    firestore = FakeFirestoreService();
    tester = ApiRequestHandlerTester();
    handler = MergeQueueHooks(
      config: FakeConfig(),
      authenticationProvider: FakeDashboardAuthentication(),
      firestore: firestore,
    );
  });

  test('denies non-google emails', () async {
    tester.context.email = 'user@example.com';
    await expectLater(tester.get(handler), throwsA(isA<Forbidden>()));
  });

  test('allows google emails', () async {
    tester.context.email = 'user@google.com';
    final response = await tester.get(handler);
    expect(response, isNotNull);
    final body = await response.body
        .cast<List<int>>()
        .transform(utf8.decoder)
        .join();
    expect(body, contains('hooks'));
    expect(body, contains('[]'));
  });

  test('returns webhook messages', () async {
    tester.context.email = 'user@google.com';

    // Seed Firestore with a mock GithubWebhookMessage
    final timestamp = DateTime.now();
    final jsonString = jsonEncode({
      'action': 'enqueue',
      'merge_group': {
        'head_ref': 'refs/heads/main',
        'head_commit': {'id': '123456', 'message': 'test commit\nbody'},
      },
    });

    final message = GithubWebhookMessage(
      event: 'merge_group',
      jsonString: jsonString,
      timestamp: timestamp,
      expireAt: timestamp.add(const Duration(days: 1)),
    )..name = 'projects/flutter-dashboard/databases/cocoon/documents/github_webhook_messages/67ZoF8emsDqhgFjHkNdx';
    await firestore.createDocument(
      message,
      collectionId: GithubWebhookMessage.metadata.collectionId,
    );

    final response = await tester.get(handler);
    final body = await response.body
        .cast<List<int>>()
        .transform(utf8.decoder)
        .join();
    final json = MergeGroupHooks.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );

    expect(json.hooks, hasLength(1));
    final hook = json.hooks[0];
    expect(hook.id, '67ZoF8emsDqhgFjHkNdx');
    expect(hook.timestamp, timestamp.millisecondsSinceEpoch);
    expect(hook.action, 'enqueue');
    expect(hook.headRef, 'refs/heads/main');
    expect(hook.headCommitId, '123456');
    expect(hook.headCommitMessage, 'test commit');
  });
}
