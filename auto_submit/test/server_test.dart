// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:auto_submit/requests/github_webhook.dart';

void main() {
  Request req = Request('POST', Uri.parse('http://localhost/'),
      headers: {
        'header1': 'header value1',
      },
      body: "{\"label1\": \"label1cotent\"}");
  GithubWebhook githubWebhook = GithubWebhook();
  test('call webhookHandler to handle the request', () async {
    Response response = await githubWebhook.webhookHandler(req);
    final String resBody = await response.readAsString();
    expect(resBody, "{\"label1\": \"label1cotent\"}");
  });
}
