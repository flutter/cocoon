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
      req = Request('POST', Uri.parse('http://localhost/'), headers: {
        'header1': 'header value1',
      }, body: '''{
      "action": "open",
      "pull_request": {
        "url": "https://api.github.com/repos/flutter/pulls/123",
        "id": 294034,
        "title": "Defer reassemble until reload is finished",
        "user": {
          "login": "octocat",
          "id": 862741
        },
        "labels": [
          {
            "id": 487496476,
            "node_id": "MDU6TGFiZWw0ODc0OTY0NzY=",
            "url": "https://api.github.com/repos/flutter/labels/cla:%20yes",
            "name": "cla: yes",
            "color": "ffffff",
            "default": false
          },
          {
            "id": 284437560,
            "node_id": "MDU6TGFiZWwyODQ0Mzc1NjA=",
            "url": "https://api.github.com/repos/flutter/labels/autosubmit",
            "name": "autosubmit",
            "color": "207de5",
            "default": false
          }
        ]
      },
      "repository": {
        "id": 1868532,
        "name": "cocoon",
        "full_name": "cocooon/octocat",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 21031067
        },
        "html_url": "https://github.com/cocooon/octocat",
        "watchers": 0
      }
    }''');
      githubWebhook = GithubWebhook();
    });

    test('call handler to handle the post request', () async {
      Response response = await githubWebhook.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, '''{
      "action": "open",
      "pull_request": {
        "url": "https://api.github.com/repos/flutter/pulls/123",
        "id": 294034,
        "title": "Defer reassemble until reload is finished",
        "user": {
          "login": "octocat",
          "id": 862741
        },
        "labels": [
          {
            "id": 487496476,
            "node_id": "MDU6TGFiZWw0ODc0OTY0NzY=",
            "url": "https://api.github.com/repos/flutter/labels/cla:%20yes",
            "name": "cla: yes",
            "color": "ffffff",
            "default": false
          },
          {
            "id": 284437560,
            "node_id": "MDU6TGFiZWwyODQ0Mzc1NjA=",
            "url": "https://api.github.com/repos/flutter/labels/autosubmit",
            "name": "autosubmit",
            "color": "207de5",
            "default": false
          }
        ]
      },
      "repository": {
        "id": 1868532,
        "name": "cocoon",
        "full_name": "cocooon/octocat",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 21031067
        },
        "html_url": "https://github.com/cocooon/octocat",
        "watchers": 0
      }
    }''');
    });
  });
}
