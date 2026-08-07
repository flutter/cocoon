// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A realistic GitHub IssueEvent JSON payload based on issue #188740.
String issueEventJson({
  String action = 'closed',
  String htmlUrl = 'https://github.com/flutter/flutter/issues/188740',
  String login = 'codefu',
  int number = 188740,
  String title = 'Increase errors in Cocoon since Friday',
}) =>
    '''
{
  "action": "$action",
  "issue": {
    "url": "https://api.github.com/repos/flutter/flutter/issues/$number",
    "repository_url": "https://api.github.com/repos/flutter/flutter",
    "html_url": "$htmlUrl",
    "id": 4771077498,
    "node_id": "I_kwDOAeUeuM8AAAABHGDdeg",
    "number": $number,
    "title": "$title",
    "user": {
      "login": "jtmcdole",
      "id": 1924313,
      "html_url": "https://github.com/jtmcdole",
      "type": "User",
      "site_admin": false
    },
    "labels": [
      {
        "id": 1578115393,
        "name": "team-infra",
        "color": "198022",
        "default": false,
        "description": "Owned by Infrastructure team"
      },
      {
        "id": 2096800592,
        "name": "P1",
        "color": "990000",
        "default": false,
        "description": "High-priority issues at the top of the work list"
      }
    ],
    "state": "$action",
    "locked": false,
    "assignees": [
      {
        "login": "$login",
        "id": 6338570,
        "html_url": "https://github.com/$login",
        "type": "User"
      }
    ],
    "assignee": {
      "login": "$login",
      "id": 6338570,
      "html_url": "https://github.com/$login",
      "type": "User"
    },
    "created_at": "2026-06-29T19:40:37Z",
    "updated_at": "2026-08-06T19:37:41Z",
    "closed_at": "2026-08-06T19:37:41Z",
    "author_association": "MEMBER",
    "body": "Increase errors in Cocoon since Friday",
    "state_reason": "completed"
  },
  "repository": {
    "id": 31792824,
    "name": "flutter",
    "full_name": "flutter/flutter",
    "owner": {
      "login": "flutter",
      "id": 14101776,
      "avatar_url": "https://avatars.githubusercontent.com/u/14101776?v=4",
      "html_url": "https://github.com/flutter",
      "type": "Organization"
    },
    "html_url": "https://github.com/flutter/flutter"
  },
  "sender": {
    "login": "$login",
    "id": 6338570,
    "html_url": "https://github.com/$login",
    "type": "User",
    "site_admin": false
  }
}
''';
