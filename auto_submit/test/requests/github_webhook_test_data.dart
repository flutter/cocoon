// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String webhookEventMock = '''{
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

String reviewsMock = '''[
  {
    "id": 80,
    "node_id": "MDE3OlB1bGxSZXF1ZXN0UmV2aWV3ODA=",
    "user": {
      "login": "octocat",
      "id": 1,
      "node_id": "MDQ6VXNlcjE=",
      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
      "gravatar_id": "",
      "url": "https://api.github.com/users/octocat",
      "html_url": "https://github.com/octocat",
      "followers_url": "https://api.github.com/users/octocat/followers",
      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
      "organizations_url": "https://api.github.com/users/octocat/orgs",
      "repos_url": "https://api.github.com/users/octocat/repos",
      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
      "received_events_url": "https://api.github.com/users/octocat/received_events",
      "type": "User",
      "site_admin": false
    },
    "body": "Here is the body for the review.",
    "state": "APPROVED",
    "html_url": "https://github.com/octocat/Hello-World/pull/12#pullrequestreview-80",
    "pull_request_url": "https://api.github.com/repos/octocat/Hello-World/pulls/12",
    "_links": {
      "html": {
        "href": "https://github.com/octocat/Hello-World/pull/12#pullrequestreview-80"
      },
      "pull_request": {
        "href": "https://api.github.com/repos/octocat/Hello-World/pulls/12"
      }
    },
    "submitted_at": "2019-11-17T17:43:43Z",
    "commit_id": "ecdd80bb57125d7ba9641ffaa4d7d2c19d3f3091",
    "author_association": "OWNER"
  }
]''';
