// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String commentOnNonPullRequestIssuePayload = '''
{
  "action": "created",
  "issue": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/10",
    "repository_url": "https://api.github.com/repos/ricardoamador/flutter_test",
    "html_url": "https://github.com/ricardoamador/flutter_test/issues/10",
    "id": 1578819463,
    "node_id": "I_kwDOIRxr_M5eGt-H",
    "number": 10,
    "title": "Test issue to see if these differ from pull requests via github.",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ricardoamador",
      "html_url": "https://github.com/ricardoamador",
      "type": "User",
      "site_admin": false
    },
    "labels": [
    ],
    "state": "open",
    "locked": false,
    "assignee": null,
    "milestone": null,
    "comments": 1,
    "created_at": "2023-02-10T00:44:37Z",
    "updated_at": "2023-02-10T00:45:07Z",
    "closed_at": null,
    "author_association": "OWNER",
    "active_lock_reason": null,
    "body": null,
    "reactions": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/10/reactions",
      "total_count": 0
    },
    "timeline_url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/10/timeline",
    "performed_via_github_app": null,
    "state_reason": null
  },
  "comment": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/comments/1425024464",
    "html_url": "https://github.com/ricardoamador/flutter_test/issues/10#issuecomment-1425024464",
    "issue_url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/10",
    "id": 1425024464,
    "node_id": "IC_kwDOIRxr_M5U8CXQ",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ricardoamador",
      "html_url": "https://github.com/ricardoamador",
      "type": "User",
      "site_admin": false
    },
    "created_at": "2023-02-10T00:45:07Z",
    "updated_at": "2023-02-10T00:45:07Z",
    "author_association": "OWNER",
    "body": "Test comment on a non pull request.",
    "reactions": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/comments/1425024464/reactions",
      "total_count": 0
    },
    "performed_via_github_app": null
  },
  "repository": {
    "id": 555510780,
    "node_id": "R_kgDOIRxr_A",
    "name": "flutter_test",
    "full_name": "ricardoamador/flutter_test",
    "private": true,
    "owner": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ricardoamador",
      "html_url": "https://github.com/ricardoamador",
      "type": "User",
      "site_admin": false
    },
    "html_url": "https://github.com/ricardoamador/flutter_test",
    "description": "Test repository for checking git commands",
    "fork": false,
    "url": "https://api.github.com/repos/ricardoamador/flutter_test",
    "created_at": "2022-10-21T18:20:42Z",
    "updated_at": "2022-10-21T18:22:20Z",
    "pushed_at": "2022-12-14T22:44:11Z",
    "default_branch": "main"
  },
  "sender": {
    "login": "ricardoamador",
    "id": 32242716,
    "node_id": "MDQ6VXNlcjMyMjQyNzE2",
    "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/ricardoamador",
    "html_url": "https://github.com/ricardoamador",
    "type": "User",
    "site_admin": false
  }
}
''';

const String commentOnPullRequestPayload = '''
{
  "action": "created",
  "issue": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9",
    "repository_url": "https://api.github.com/repos/ricardoamador/flutter_test",
    "html_url": "https://github.com/ricardoamador/flutter_test/pull/9",
    "id": 1497518469,
    "node_id": "PR_kwDOIRxr_M5Ff1-I",
    "number": 9,
    "title": "Revert Updated readme",
    "user": {
      "login": "revert[bot]",
      "id": 120533631,
      "node_id": "BOT_kgDOBy8yfw",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/revert%5Bbot%5D",
      "html_url": "https://github.com/apps/revert",
      "type": "Bot",
      "site_admin": false
    },
    "labels": [
    ],
    "state": "open",
    "locked": false,
    "assignee": null,
    "assignees": [
    ],
    "milestone": null,
    "comments": 1,
    "created_at": "2022-12-14T22:44:10Z",
    "updated_at": "2023-02-08T22:43:26Z",
    "closed_at": null,
    "author_association": "NONE",
    "active_lock_reason": null,
    "draft": false,
    "pull_request": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/pulls/9",
      "html_url": "https://github.com/ricardoamador/flutter_test/pull/9",
      "diff_url": "https://github.com/ricardoamador/flutter_test/pull/9.diff",
      "patch_url": "https://github.com/ricardoamador/flutter_test/pull/9.patch",
      "merged_at": null
    },
    "body": null,
    "reactions": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9/reactions",
      "total_count": 0
    },
    "timeline_url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9/timeline",
    "performed_via_github_app": null,
    "state_reason": null
  },
  "comment": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/comments/1423335532",
    "html_url": "https://github.com/ricardoamador/flutter_test/pull/9#issuecomment-1423335532",
    "issue_url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9",
    "id": 1423335532,
    "node_id": "IC_kwDOIRxr_M5U1mBs",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ricardoamador",
      "html_url": "https://github.com/ricardoamador",
      "type": "User",
      "site_admin": false
    },
    "created_at": "2023-02-08T22:43:26Z",
    "updated_at": "2023-02-08T22:43:26Z",
    "author_association": "OWNER",
    "body": "Issue comment payload test.",
    "reactions": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/comments/1423335532/reactions",
      "total_count": 0
    },
    "performed_via_github_app": null
  },
  "repository": {
    "id": 555510780,
    "node_id": "R_kgDOIRxr_A",
    "name": "flutter_test",
    "full_name": "ricardoamador/flutter_test",
    "private": true,
    "owner": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ricardoamador",
      "html_url": "https://github.com/ricardoamador",
      "type": "User",
      "site_admin": false
    },
    "html_url": "https://github.com/ricardoamador/flutter_test",
    "description": "Test repository for checking git commands",
    "fork": false,
    "url": "https://api.github.com/repos/ricardoamador/flutter_test",
    "created_at": "2022-10-21T18:20:42Z",
    "updated_at": "2022-10-21T18:22:20Z",
    "pushed_at": "2022-12-14T22:44:11Z",
    "default_branch": "main"
  },
  "sender": {
    "login": "ricardoamador",
    "id": 32242716,
    "node_id": "MDQ6VXNlcjMyMjQyNzE2",
    "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/ricardoamador",
    "html_url": "https://github.com/ricardoamador",
    "type": "User",
    "site_admin": false
  }
}
''';

const String nonCreateCommentPayload = '''
{
  "action": "edited",
  "issue": {
    "id": 1497518469,
    "node_id": "PR_kwDOIRxr_M5Ff1-I",
    "number": 9,
    "title": "Revert Updated readme",
    "user": {
      "login": "revert[bot]",
      "id": 120533631,
      "node_id": "BOT_kgDOBy8yfw"
    },
    "state": "open",
    "locked": false
  },
  "comment": {
    "id": 1423335532,
    "node_id": "IC_kwDOIRxr_M5U1mBs",
    "created_at": "2023-02-08T22:43:26Z",
    "updated_at": "2023-02-08T22:43:26Z",
    "author_association": "OWNER",
    "body": "Issue comment payload test."
  },
  "repository": {
    "id": 555510780,
    "node_id": "R_kgDOIRxr_A",
    "name": "flutter_test",
    "full_name": "ricardoamador/flutter_test",
    "private": true,
    "owner": {
      "login": "ricardoamador",
      "id": 32242716
    }
  },
  "sender": {
    "login": "ricardoamador",
    "id": 32242716,
    "node_id": "MDQ6VXNlcjMyMjQyNzE2"
  }
}
''';

const String partialPayload = '''
{
  "action": "created",
  "issue": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9",
    "repository_url": "https://api.github.com/repos/ricardoamador/flutter_test",
    "html_url": "https://github.com/ricardoamador/flutter_test/pull/9",
    "id": 1497518469,
    "node_id": "PR_kwDOIRxr_M5Ff1-I",
    "number": 9,
    "title": "Revert Updated readme",
    "user": {
      "login": "revert[bot]",
      "id": 120533631,
      "node_id": "BOT_kgDOBy8yfw",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/revert%5Bbot%5D",
      "html_url": "https://github.com/apps/revert",
      "type": "Bot",
      "site_admin": false
    },
    "labels": [
    ],
    "state": "open",
    "locked": false,
    "assignee": null,
    "assignees": [
    ],
    "milestone": null,
    "comments": 1,
    "created_at": "2022-12-14T22:44:10Z",
    "updated_at": "2023-02-08T22:43:26Z",
    "closed_at": null,
    "author_association": "NONE",
    "active_lock_reason": null,
    "draft": false,
    "pull_request": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/pulls/9",
      "html_url": "https://github.com/ricardoamador/flutter_test/pull/9",
      "diff_url": "https://github.com/ricardoamador/flutter_test/pull/9.diff",
      "patch_url": "https://github.com/ricardoamador/flutter_test/pull/9.patch",
      "merged_at": null
    },
    "body": null,
    "reactions": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9/reactions"
    },
    "timeline_url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9/timeline",
    "performed_via_github_app": null,
    "state_reason": null
  },
  "comment": {
    "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/comments/1423335532",
    "html_url": "https://github.com/ricardoamador/flutter_test/pull/9#issuecomment-1423335532",
    "issue_url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/9",
    "id": 1423335532,
    "node_id": "IC_kwDOIRxr_M5U1mBs",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2",
      "avatar_url": "https://avatars.githubusercontent.com/u/32242716?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/ricardoamador",
      "html_url": "https://github.com/ricardoamador",
      "type": "User",
      "site_admin": false
    },
    "created_at": "2023-02-08T22:43:26Z",
    "updated_at": "2023-02-08T22:43:26Z",
    "author_association": "OWNER",
    "body": "Issue comment payload test.",
    "reactions": {
      "url": "https://api.github.com/repos/ricardoamador/flutter_test/issues/comments/1423335532/reactions",
      "total_count": 0
    },
    "performed_via_github_app": null
  }
}
''';

const String gitReference = '''
{
  "ref": "refs/heads/main",
  "node_id": "MDM6UmVmNjMyNjA1NTQ6cmVmcy9oZWFkcy9tYWlu",
  "url": "https://api.github.com/repos/flutter/cocoon/git/refs/heads/main",
  "object": {
    "sha": "6c49dbe90ff3e73b2989619b7760b644c1ed96fe",
    "type": "commit",
    "url": "https://api.github.com/repos/flutter/cocoon/git/commits/6c49dbe90ff3e73b2989619b7760b644c1ed96fe"
  }
}
''';
