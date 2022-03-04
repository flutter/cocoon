// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/requests/github_webhook.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../utilities/mocks.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;
    late FakeConfig config;
    late Future<MockGithubService> futureMockGithubService;
    final MockGithubService mockGithubService = MockGithubService();
    late RepositorySlug slug;

    const int number = 1598;

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);

      Future<MockGithubService> getFuture(MockGithubService mockGithubService) async {
        return mockGithubService;
      }

      futureMockGithubService = getFuture(mockGithubService);
      config = FakeConfig(githubService: futureMockGithubService);
      githubWebhook = GithubWebhook(config: config);
      slug = RepositorySlug('flutter', 'cocoon');
    });

    test('call handler to handle the post request', () async {
      when(mockGithubService.getPullRequest(slug, prNumber: number)).thenAnswer((_) async {
        return PullRequest.fromJson(json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });

      final Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });
  });
}
