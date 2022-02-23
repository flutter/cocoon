// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:auto_submit/requests/github_webhook.dart';

void main() {
  group('Check Webhook', () {
    late Request req;
    late GithubWebhook githubWebhook;

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: "{\"label1\": \"label1cotent\"}");
      githubWebhook = GithubWebhook();
    });

    test('call handler to handle the post request', () async {
      Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, "{\"label1\": \"label1cotent\"}");
    });
  });
}
