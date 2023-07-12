// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  late GithubWebhook webhook;
  late FakeConfig config;
  late FakeHttpRequest request;
  late FakePubSub pubsub;
  late RequestHandlerTester tester;
  const String keyString = 'not_a_real_key';

  String getHmac(Uint8List list, Uint8List key) {
    final Hmac hmac = Hmac(sha1, key);
    return hmac.convert(list).toString();
  }

  setUp(() {
    request = FakeHttpRequest();
    tester = RequestHandlerTester(request: request);

    config = FakeConfig(
      webhookKeyValue: keyString,
    );
    pubsub = FakePubSub();

    webhook = GithubWebhook(
      config: config,
      pubsub: pubsub,
    );
  });

  test('Rejects non-POST methods with methodNotAllowed', () async {
    expect(tester.get(webhook), throwsA(isA<MethodNotAllowed>()));
    expect(pubsub.messages, isEmpty);
  });

  test('Rejects missing headers', () async {
    expect(tester.post(webhook), throwsA(isA<BadRequestException>()));
    expect(pubsub.messages, isEmpty);
  });

  test('Rejects invalid hmac', () async {
    request.headers.set('X-GitHub-Event', 'pull_request');
    request.headers.set('X-Hub-Signature', 'bar');
    request.body = 'Hello, World!';
    expect(tester.post(webhook), throwsA(isA<Forbidden>()));
    expect(pubsub.messages, isEmpty);
  });

  test('Publishes message', () async {
    request.headers.set('X-GitHub-Event', 'pull_request');
    request.body = '{}';
    final Uint8List body = utf8.encode(request.body!);
    final Uint8List key = utf8.encode(keyString);
    final String hmac = getHmac(body, key);
    request.headers.set('X-Hub-Signature', 'sha1=$hmac');
    await tester.post(webhook);

    expect(pubsub.messages, hasLength(1));
    final Map<String, dynamic> messageJson = pubsub.messages.single;
    final GithubWebhookMessage message = GithubWebhookMessage.fromJson(jsonEncode(messageJson));
    expect(message.event, 'pull_request');
    expect(message.payload, '{}');
  });
}
