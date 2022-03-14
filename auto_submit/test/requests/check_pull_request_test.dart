// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../src/service/fake_config.dart';

void main() {
  group('Check CheckPullRequest', () {
    late Request req;
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;

    setUp(() {
      req = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);
      config = FakeConfig();
      checkPullRequest = CheckPullRequest(config: config);
    });

    test('Merge PR with successful status and checks', () async {
      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });
  });
}
