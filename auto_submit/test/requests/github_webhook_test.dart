// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/requests/github_webhook.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../src/service/fake_config.dart';
import './github_webhook_test_data.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);
      githubWebhook = GithubWebhook(
        config: FakeConfig(),
      );
    });

    test('call handler to handle the post request', () async {
      Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      final body = json.decode(resBody) as Map<String, dynamic>;
      List<IssueLabel>? labels = PullRequest.fromJson(body['pull_request']).labels;
      expect(labels![0].name, 'cla: yes');
      expect(labels[1].name, 'autosubmit');
    });
  });
}
