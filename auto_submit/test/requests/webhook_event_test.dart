// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String webhook_event_mock = '''{
      "action": "open",
      "number": 1598,
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
        "name": "flutter",
        "full_name": "flutter/cocoon",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 21031067
        },
        "html_url": "https://github.com/cocooon/octocat",
        "watchers": 0
      }
    }''';
