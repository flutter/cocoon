// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_submit/requests/exceptions.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:crypto/crypto.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import './github_webhook_test_data.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;
    const String keyString = 'not_a_real_key';
    final FakeConfig config = FakeConfig(webhookKey: keyString);
    final FakePubSub pubsub = FakePubSub();
    late Map<String, String> validHeader;
    late Map<String, String> inValidHeader;

    String getHmac(Uint8List list, Uint8List key) {
      final Hmac hmac = Hmac(sha1, key);
      return hmac.convert(list).toString();
    }

    setUp(() {
      githubWebhook = GithubWebhook(config: config, pubsub: pubsub);
    });

    test('throws if repo base is flutter/flutter', () async {
      final Uint8List body = utf8.encode(generateWebhookEvent());
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      validHeader = <String, String>{'X-Hub-Signature': 'sha1=$hmac', 'X-GitHub-Event': 'yes'};
      req = Request('POST', Uri.parse('http://localhost/'), body: generateWebhookEvent(), headers: validHeader);
      expect(
        () async => githubWebhook.post(req),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('call handler to handle the post request', () async {
      final String event = generateWebhookEvent(repoName: 'not-flutter');
      final Uint8List body = utf8.encode(event);
      final Uint8List key = utf8.encode(keyString);
      final String hmac = getHmac(body, key);
      validHeader = <String, String>{'X-Hub-Signature': 'sha1=$hmac', 'X-GitHub-Event': 'yes'};
      req = Request('POST', Uri.parse('http://localhost/'), body: event, headers: validHeader);
      final Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      final reqBody = json.decode(resBody) as Map<String, dynamic>;
      final List<IssueLabel> labels = PullRequest.fromJson(reqBody['pull_request'] as Map<String, dynamic>).labels!;
      expect(labels[0].name, 'cla: yes');
      expect(labels[1].name, 'autosubmit');
    });

    test('Rejects invalid hmac', () async {
      inValidHeader = <String, String>{'X-GitHub-Event': 'pull_request', 'X-Hub-Signature': 'bar'};
      req = Request('POST', Uri.parse('http://localhost/'), body: 'Hello, World!', headers: inValidHeader);
      await expectLater(githubWebhook.post(req), throwsA(isA<Forbidden>()));
    });

    test('Rejects missing headers', () async {
      req = Request('POST', Uri.parse('http://localhost/'), body: generateWebhookEvent());
      await expectLater(githubWebhook.post(req), throwsA(isA<BadRequestException>()));
    });
  });
}
