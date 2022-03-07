// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pr_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  group('Check CheckPullRequest', () {
    late Request req;
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    late FakeGithubService githubService;

    setUp(() {
      req = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);
    });

    test('call checkPullRequest handler to handle the get request', () async {
      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });
  });
}
