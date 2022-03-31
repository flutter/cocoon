// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/requests/github_webhook.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;
    final FakeConfig config = FakeConfig();
    final FakePubSub pubsub = FakePubSub();

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'), body: generateWebhookEvent());
      githubWebhook = GithubWebhook(config: config, pubsub: pubsub);
    });

    test('call handler to handle the post request', () async {
      final Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      final body = json.decode(resBody) as Map<String, dynamic>;
      List<IssueLabel> labels = PullRequest.fromJson(body['pull_request']).labels!;
      expect(labels[0].name, 'cla: yes');
      expect(labels[1].name, 'autosubmit');
    });
  });
}
