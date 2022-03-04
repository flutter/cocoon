// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/github_webhook.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;
    late FakeConfig config;
    late FakeGithubService githubService;
    late Future<FakeGithubService> futureGithubService;

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);
      githubService = FakeGithubService();

      Future<FakeGithubService> getFuture(FakeGithubService githubService) async {
        return githubService;
      }

      futureGithubService = getFuture(githubService);
      config = FakeConfig(githubService: futureGithubService);
      githubWebhook = GithubWebhook(config: config);
    });

    test('call handler to handle the post request', () async {
      final Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });
  });
}
