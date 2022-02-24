// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:auto_submit/requests/github_webhook.dart';

import './webhook_event_test.dart';

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
      githubWebhook = GithubWebhook();
    });

    test('call handler to handle the post request', () async {
      Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      final body = json.decode(resBody) as Map<String, dynamic>;
      List<IssueLabel> labels = <IssueLabel>[];
      body['pull_request']['labels'].forEach((element) => labels.add(IssueLabel.fromJson(element)));
      expect(labels[0].name, 'cla: yes');
      expect(labels[1].name, 'autosubmit');
    });
  });
}
