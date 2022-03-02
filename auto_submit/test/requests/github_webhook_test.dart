// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/requests/cirrus_graphql_client.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../service/fake_config.dart';
import '../utilities/mocks.dart';

void main() {
  group('Check Webhook handler', () {
    late Request req;
    late GithubWebhook handler;
    late FakeConfig config;
    late RepositorySlug slug;
    final MockCirrusGraphQLClient mockCirrusClient = MockCirrusGraphQLClient();
    final MockGithubService mockGitHubService = MockGithubService();

    const int number = 2;

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);
      config = FakeConfig(
          rollerAccountsValue: <String>{}, githubService: mockGitHubService, cirrusGraphQLClient: mockCirrusClient);
      handler = GithubWebhook(config);
      slug = RepositorySlug('flutter', 'cocoon');
    });

    test('Merges PR with successful status and checks', () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number)).thenAnswer((_) async {
        return PullRequest.fromJson(json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });
  });
}
