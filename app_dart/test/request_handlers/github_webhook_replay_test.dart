// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/github_webhook_message.dart';
import 'package:cocoon_service/src/request_handlers/github_webhook_replay.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_dashboard_authentication.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  late GithubWebhookReplay handler;
  late FakeConfig config;
  late FakeFirestoreService firestoreService;
  late ApiRequestHandlerTester tester;
  late GithubWebhook githubWebhook;
  late FakePubSub pubsub;

  setUp(() {
    config = FakeConfig(webhookKeyValue: 'fake_key');
    firestoreService = FakeFirestoreService();
    tester = ApiRequestHandlerTester();
    pubsub = FakePubSub();

    githubWebhook = GithubWebhook(
      config: config,
      pubsub: pubsub,
      secret: config.webhookKey,
      topic: 'github-webhooks',
      firestore: firestoreService,
    );

    handler = GithubWebhookReplay(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(),
      firestoreService: firestoreService,
      githubWebhook: githubWebhook,
    );
  });

  test('denies non-google emails', () async {
    tester.context.email = 'user@example.com';
    await expectLater(tester.post(handler), throwsA(isA<Forbidden>()));
  });

  test('Rejects missing id parameter', () async {
    tester.context.email = 'user@google.com';
    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('Rejects missing document', () async {
    tester.context.email = 'user@google.com';
    tester.request.uri = Uri.parse('/api/github-webhook-replay?id=missing_doc');
    await expectLater(tester.post(handler), throwsA(isA<NotFoundException>()));
  });

  test('Replays webhook successfully', () async {
    tester.context.email = 'user@google.com';

    final message = GithubWebhookMessage(
      event: 'pull_request',
      jsonString: '{"foo":"bar"}',
      timestamp: DateTime.now(),
      expireAt: DateTime.now().add(const Duration(days: 7)),
    );
    final doc = await firestoreService.createDocument(
      message,
      collectionId: GithubWebhookMessage.metadata.collectionId,
    );

    final id = doc.name!.split('/').last;
    tester.request.uri = Uri.parse('/api/github-webhook-replay?id=$id');
    await tester.post(handler);

    expect(pubsub.messages, hasLength(1));
  });
}
