// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

final String webhookEventMock = '''{
      "action": "open",
      "number": 1598,
      "pull_request": {
          "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
          "id": 1,
          "node_id": "MDExOlB1bGxSZXF1ZXN0MQ==",
          "html_url": "https://github.com/octocat/Hello-World/pull/1347",
          "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
          "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch",
          "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
          "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits",
          "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments",
          "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
          "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments",
          "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "number": 1347,
          "state": "open",
          "locked": true,
          "title": "Amazing new feature",
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
          "body": "Please pull these awesome changes in!",
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
          ],
          "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
            "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
            "id": 1002604,
            "node_id": "MDk6TWlsZXN0b25lMTAwMjYwNA==",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "Tracking milestone for version 1.0",
            "creator": {
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
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "updated_at": "2014-03-03T18:58:10Z",
            "closed_at": "2013-02-12T13:22:01Z",
            "due_on": "2012-10-09T23:39:01Z"
          },
          "active_lock_reason": "too heated",
          "created_at": "2011-01-26T19:01:12Z",
          "updated_at": "2011-01-26T19:01:12Z",
          "closed_at": "2011-01-26T19:01:12Z",
          "merged_at": "2011-01-26T19:01:12Z",
          "merge_commit_sha": "e5bd3914e2e596debea16f433f57875b5b90bcd6",
          "assignee": {
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
          "assignees": [
            {
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
            {
              "login": "hubot",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/hubot_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/hubot",
              "html_url": "https://github.com/hubot",
              "followers_url": "https://api.github.com/users/hubot/followers",
              "following_url": "https://api.github.com/users/hubot/following{/other_user}",
              "gists_url": "https://api.github.com/users/hubot/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/hubot/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/hubot/subscriptions",
              "organizations_url": "https://api.github.com/users/hubot/orgs",
              "repos_url": "https://api.github.com/users/hubot/repos",
              "events_url": "https://api.github.com/users/hubot/events{/privacy}",
              "received_events_url": "https://api.github.com/users/hubot/received_events",
              "type": "User",
              "site_admin": true
            }
          ],
          "requested_reviewers": [
            {
              "login": "other_user",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/other_user_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/other_user",
              "html_url": "https://github.com/other_user",
              "followers_url": "https://api.github.com/users/other_user/followers",
              "following_url": "https://api.github.com/users/other_user/following{/other_user}",
              "gists_url": "https://api.github.com/users/other_user/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/other_user/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/other_user/subscriptions",
              "organizations_url": "https://api.github.com/users/other_user/orgs",
              "repos_url": "https://api.github.com/users/other_user/repos",
              "events_url": "https://api.github.com/users/other_user/events{/privacy}",
              "received_events_url": "https://api.github.com/users/other_user/received_events",
              "type": "User",
              "site_admin": false
            }
          ],
          "requested_teams": [
            {
              "id": 1,
              "node_id": "MDQ6VGVhbTE=",
              "url": "https://api.github.com/teams/1",
              "html_url": "https://github.com/orgs/github/teams/justice-league",
              "name": "Justice League",
              "slug": "justice-league",
              "description": "A great team.",
              "privacy": "closed",
              "permission": "admin",
              "members_url": "https://api.github.com/teams/1/members{/member}",
              "repositories_url": "https://api.github.com/teams/1/repos"
            }
          ],
          "head": {
            "label": "octocat:new-topic",
            "ref": "new-topic",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "allow_forking": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "base": {
            "label": "octocat:master",
            "ref": "master",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "flutter",
              "full_name": "flutter/flutter",
              "owner": {
                "login": "flutter",
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "_links": {
            "self": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347"
            },
            "html": {
              "href": "https://github.com/octocat/Hello-World/pull/1347"
            },
            "issue": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347"
            },
            "comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments"
            },
            "review_comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments"
            },
            "review_comment": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}"
            },
            "commits": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits"
            },
            "statuses": {
              "href": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e"
            }
          },
          "author_association": "OWNER",
          "auto_merge": null,
          "draft": false,
          "merged": false,
          "mergeable": true,
          "rebaseable": true,
          "mergeable_state": "clean",
          "comments": 10,
          "review_comments": 0,
          "maintainer_can_modify": true,
          "commits": 3,
          "additions": 100,
          "deletions": 3,
          "changed_files": 5
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

final String webhookNoStatusRepoMock = '''{
      "action": "open",
      "number": 1598,
      "pull_request": {
          "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
          "id": 1,
          "node_id": "MDExOlB1bGxSZXF1ZXN0MQ==",
          "html_url": "https://github.com/octocat/Hello-World/pull/1347",
          "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
          "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch",
          "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
          "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits",
          "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments",
          "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
          "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments",
          "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "number": 1347,
          "state": "open",
          "locked": true,
          "title": "Amazing new feature",
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
          "body": "Please pull these awesome changes in!",
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
          ],
          "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
            "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
            "id": 1002604,
            "node_id": "MDk6TWlsZXN0b25lMTAwMjYwNA==",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "Tracking milestone for version 1.0",
            "creator": {
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
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "updated_at": "2014-03-03T18:58:10Z",
            "closed_at": "2013-02-12T13:22:01Z",
            "due_on": "2012-10-09T23:39:01Z"
          },
          "active_lock_reason": "too heated",
          "created_at": "2011-01-26T19:01:12Z",
          "updated_at": "2011-01-26T19:01:12Z",
          "closed_at": "2011-01-26T19:01:12Z",
          "merged_at": "2011-01-26T19:01:12Z",
          "merge_commit_sha": "e5bd3914e2e596debea16f433f57875b5b90bcd6",
          "assignee": {
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
          "assignees": [
            {
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
            {
              "login": "hubot",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/hubot_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/hubot",
              "html_url": "https://github.com/hubot",
              "followers_url": "https://api.github.com/users/hubot/followers",
              "following_url": "https://api.github.com/users/hubot/following{/other_user}",
              "gists_url": "https://api.github.com/users/hubot/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/hubot/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/hubot/subscriptions",
              "organizations_url": "https://api.github.com/users/hubot/orgs",
              "repos_url": "https://api.github.com/users/hubot/repos",
              "events_url": "https://api.github.com/users/hubot/events{/privacy}",
              "received_events_url": "https://api.github.com/users/hubot/received_events",
              "type": "User",
              "site_admin": true
            }
          ],
          "requested_reviewers": [
            {
              "login": "other_user",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/other_user_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/other_user",
              "html_url": "https://github.com/other_user",
              "followers_url": "https://api.github.com/users/other_user/followers",
              "following_url": "https://api.github.com/users/other_user/following{/other_user}",
              "gists_url": "https://api.github.com/users/other_user/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/other_user/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/other_user/subscriptions",
              "organizations_url": "https://api.github.com/users/other_user/orgs",
              "repos_url": "https://api.github.com/users/other_user/repos",
              "events_url": "https://api.github.com/users/other_user/events{/privacy}",
              "received_events_url": "https://api.github.com/users/other_user/received_events",
              "type": "User",
              "site_admin": false
            }
          ],
          "requested_teams": [
            {
              "id": 1,
              "node_id": "MDQ6VGVhbTE=",
              "url": "https://api.github.com/teams/1",
              "html_url": "https://github.com/orgs/github/teams/justice-league",
              "name": "Justice League",
              "slug": "justice-league",
              "description": "A great team.",
              "privacy": "closed",
              "permission": "admin",
              "members_url": "https://api.github.com/teams/1/members{/member}",
              "repositories_url": "https://api.github.com/teams/1/repos"
            }
          ],
          "head": {
            "label": "octocat:new-topic",
            "ref": "new-topic",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "allow_forking": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "base": {
            "label": "octocat:master",
            "ref": "master",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "octcat",
              "full_name": "octcat/Hello-wolrd",
              "owner": {
                "login": "Hello-wolrd",
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "_links": {
            "self": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347"
            },
            "html": {
              "href": "https://github.com/octocat/Hello-World/pull/1347"
            },
            "issue": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347"
            },
            "comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments"
            },
            "review_comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments"
            },
            "review_comment": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}"
            },
            "commits": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits"
            },
            "statuses": {
              "href": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e"
            }
          },
          "author_association": "OWNER",
          "auto_merge": null,
          "draft": false,
          "merged": false,
          "mergeable": true,
          "rebaseable": true,
          "mergeable_state": "clean",
          "comments": 10,
          "review_comments": 0,
          "maintainer_can_modify": true,
          "commits": 3,
          "additions": 100,
          "deletions": 3,
          "changed_files": 5
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

final String webhookAutoRollerMock = '''{
      "action": "open",
      "number": 1598,
      "pull_request": {
          "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
          "id": 1,
          "node_id": "MDExOlB1bGxSZXF1ZXN0MQ==",
          "html_url": "https://github.com/octocat/Hello-World/pull/1347",
          "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
          "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch",
          "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
          "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits",
          "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments",
          "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
          "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments",
          "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "number": 1347,
          "state": "open",
          "locked": true,
          "title": "Amazing new feature",
          "user": {
            "login": "engine-flutter-autoroll",
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
          "body": "Please pull these awesome changes in!",
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
          ],
          "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
            "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
            "id": 1002604,
            "node_id": "MDk6TWlsZXN0b25lMTAwMjYwNA==",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "Tracking milestone for version 1.0",
            "creator": {
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
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "updated_at": "2014-03-03T18:58:10Z",
            "closed_at": "2013-02-12T13:22:01Z",
            "due_on": "2012-10-09T23:39:01Z"
          },
          "active_lock_reason": "too heated",
          "created_at": "2011-01-26T19:01:12Z",
          "updated_at": "2011-01-26T19:01:12Z",
          "closed_at": "2011-01-26T19:01:12Z",
          "merged_at": "2011-01-26T19:01:12Z",
          "merge_commit_sha": "e5bd3914e2e596debea16f433f57875b5b90bcd6",
          "assignee": {
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
          "assignees": [
            {
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
            {
              "login": "hubot",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/hubot_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/hubot",
              "html_url": "https://github.com/hubot",
              "followers_url": "https://api.github.com/users/hubot/followers",
              "following_url": "https://api.github.com/users/hubot/following{/other_user}",
              "gists_url": "https://api.github.com/users/hubot/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/hubot/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/hubot/subscriptions",
              "organizations_url": "https://api.github.com/users/hubot/orgs",
              "repos_url": "https://api.github.com/users/hubot/repos",
              "events_url": "https://api.github.com/users/hubot/events{/privacy}",
              "received_events_url": "https://api.github.com/users/hubot/received_events",
              "type": "User",
              "site_admin": true
            }
          ],
          "requested_reviewers": [
            {
              "login": "other_user",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/other_user_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/other_user",
              "html_url": "https://github.com/other_user",
              "followers_url": "https://api.github.com/users/other_user/followers",
              "following_url": "https://api.github.com/users/other_user/following{/other_user}",
              "gists_url": "https://api.github.com/users/other_user/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/other_user/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/other_user/subscriptions",
              "organizations_url": "https://api.github.com/users/other_user/orgs",
              "repos_url": "https://api.github.com/users/other_user/repos",
              "events_url": "https://api.github.com/users/other_user/events{/privacy}",
              "received_events_url": "https://api.github.com/users/other_user/received_events",
              "type": "User",
              "site_admin": false
            }
          ],
          "requested_teams": [
            {
              "id": 1,
              "node_id": "MDQ6VGVhbTE=",
              "url": "https://api.github.com/teams/1",
              "html_url": "https://github.com/orgs/github/teams/justice-league",
              "name": "Justice League",
              "slug": "justice-league",
              "description": "A great team.",
              "privacy": "closed",
              "permission": "admin",
              "members_url": "https://api.github.com/teams/1/members{/member}",
              "repositories_url": "https://api.github.com/teams/1/repos"
            }
          ],
          "head": {
            "label": "octocat:new-topic",
            "ref": "new-topic",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "allow_forking": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "base": {
            "label": "octocat:master",
            "ref": "master",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "_links": {
            "self": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347"
            },
            "html": {
              "href": "https://github.com/octocat/Hello-World/pull/1347"
            },
            "issue": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347"
            },
            "comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments"
            },
            "review_comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments"
            },
            "review_comment": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}"
            },
            "commits": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits"
            },
            "statuses": {
              "href": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e"
            }
          },
          "author_association": "OWNER",
          "auto_merge": null,
          "draft": false,
          "merged": false,
          "mergeable": true,
          "rebaseable": true,
          "mergeable_state": "clean",
          "comments": 10,
          "review_comments": 0,
          "maintainer_can_modify": true,
          "commits": 3,
          "additions": 100,
          "deletions": 3,
          "changed_files": 5
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

String webhookOverrideTreeStatusLabelMock = '''{
  "action": "opened",
  "number": 2,
  "pull_request": {
    "url": "https://api.github.com/repos/flutter/cocoon/pulls/2",
    "id": 294034,
    "node_id": "MDExOlB1bGxSZXF1ZXN0Mjk0MDMzODQx",
    "html_url": "https://github.com/flutter/cocoon/pull/2",
    "diff_url": "https://github.com/flutter/cocoon/pull/2.diff",
    "patch_url": "https://github.com/flutter/cocoon/pull/2.patch",
    "issue_url": "https://api.github.com/repos/flutter/cocoon/issues/2",
    "number": 2,
    "state": "open",
    "locked": false,
    "title": "Defer reassemble until reload is finished",
    "user": {
      "login": "flutter",
      "id": 862741,
      "node_id": "MDQ6VXNlcjg2MjA3NDE=",
      "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/flutter",
      "html_url": "https://github.com/flutter",
      "followers_url": "https://api.github.com/users/flutter/followers",
      "following_url": "https://api.github.com/users/flutter/following{/other_user}",
      "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
      "organizations_url": "https://api.github.com/users/flutter/orgs",
      "repos_url": "https://api.github.com/users/flutter/repos",
      "events_url": "https://api.github.com/users/flutter/events{/privacy}",
      "received_events_url": "https://api.github.com/users/flutter/received_events",
      "type": "User",
      "site_admin": false
    },
    "draft" : "false",
    "body": "The body",
    "created_at": "2019-07-03T07:14:35Z",
    "updated_at": "2019-07-03T16:34:53Z",
    "closed_at": null,
    "merged_at": "2019-07-03T16:34:53Z",
    "merge_commit_sha": "d22ab7ced21d3b2a5be00cf576d383eb5ffddb8a",
    "assignee": null,
    "assignees": [],
    "requested_reviewers": [],
    "requested_teams": [],
    "labels": [
      {
        "id": 487496476,
        "node_id": "MDU6TGFiZWw0ODc0OTY0NzY=",
        "url": "https://api.github.com/repos/flutter/cocoon/labels/cla:%20yes",
        "name": "warning: land on red to fix tree breakage",
        "color": "ffffff",
        "default": false
      },
      {
        "id": 284437560,
        "node_id": "MDU6TGFiZWwyODQ0Mzc1NjA=",
        "url": "https://api.github.com/repos/flutter/cocoon/labels/framework",
        "name": "autosubmit",
        "color": "207de5",
        "default": false
      }
    ],
    "milestone": null,
    "commits_url": "https://api.github.com/repos/flutter/cocoon/pulls/2/commits",
    "review_comments_url": "https://api.github.com/repos/flutter/cocoon/pulls/2/comments",
    "review_comment_url": "https://api.github.com/repos/flutter/cocoon/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/flutter/cocoon/issues/2/comments",
    "statuses_url": "https://api.github.com/repos/flutter/cocoon/statuses/be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
    "head": {
      "label": "cocoon:changes",
      "ref": "changes",
      "sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "user": {
        "login": "cocoon",
        "id": 8620741,
        "node_id": "MDQ6VXNlcjg2MjA3NDE=",
        "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "followers_url": "https://api.github.com/users/flutter/followers",
        "following_url": "https://api.github.com/users/flutter/following{/other_user}",
        "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
        "organizations_url": "https://api.github.com/users/flutter/orgs",
        "repos_url": "https://api.github.com/users/flutter/repos",
        "events_url": "https://api.github.com/users/flutter/events{/privacy}",
        "received_events_url": "https://api.github.com/users/flutter/received_events",
        "type": "User",
        "site_admin": false
      },
      "repo": {
        "id": 131232406,
        "node_id": "MDEwOlJlcG9zaXRvcnkxMzEyMzI0MDY=",
        "name": "cocoon",
        "full_name": "flutter/cocoon",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 8620741,
          "node_id": "MDQ6VXNlcjg2MjA3NDE=",
          "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/flutter",
          "html_url": "https://github.com/flutter",
          "followers_url": "https://api.github.com/users/flutter/followers",
          "following_url": "https://api.github.com/users/flutter/following{/other_user}",
          "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
          "organizations_url": "https://api.github.com/users/flutter/orgs",
          "repos_url": "https://api.github.com/users/flutter/repos",
          "events_url": "https://api.github.com/users/flutter/events{/privacy}",
          "received_events_url": "https://api.github.com/users/flutter/received_events",
          "type": "User",
          "site_admin": false
        },
        "html_url": "https://github.com/flutter/cocoon",
        "description": "Flutter makes it easy and fast to build beautiful mobile apps.",
        "fork": true,
        "url": "https://api.github.com/repos/flutter/cocoon",
        "forks_url": "https://api.github.com/repos/flutter/cocoon/forks",
        "keys_url": "https://api.github.com/repos/flutter/cocoon/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/flutter/cocoon/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/flutter/cocoon/teams",
        "hooks_url": "https://api.github.com/repos/flutter/cocoon/hooks",
        "issue_events_url": "https://api.github.com/repos/flutter/cocoon/issues/events{/number}",
        "events_url": "https://api.github.com/repos/flutter/cocoon/events",
        "assignees_url": "https://api.github.com/repos/flutter/cocoon/assignees{/user}",
        "branches_url": "https://api.github.com/repos/flutter/cocoon/branches{/branch}",
        "tags_url": "https://api.github.com/repos/flutter/cocoon/tags",
        "blobs_url": "https://api.github.com/repos/flutter/cocoon/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/flutter/cocoon/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/flutter/cocoon/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/flutter/cocoon/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/flutter/cocoon/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/flutter/cocoon/languages",
        "stargazers_url": "https://api.github.com/repos/flutter/cocoon/stargazers",
        "contributors_url": "https://api.github.com/repos/flutter/cocoon/contributors",
        "subscribers_url": "https://api.github.com/repos/flutter/cocoon/subscribers",
        "subscription_url": "https://api.github.com/repos/flutter/cocoon/subscription",
        "commits_url": "https://api.github.com/repos/flutter/cocoon/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/flutter/cocoon/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/flutter/cocoon/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/flutter/cocoon/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/flutter/cocoon/contents/{+path}",
        "compare_url": "https://api.github.com/repos/flutter/cocoon/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/flutter/cocoon/merges",
        "archive_url": "https://api.github.com/repos/flutter/cocoon/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/flutter/cocoon/downloads",
        "issues_url": "https://api.github.com/repos/flutter/cocoon/issues{/number}",
        "pulls_url": "https://api.github.com/repos/flutter/cocoon/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/flutter/cocoon/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/flutter/cocoon/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/flutter/cocoon/labels{/name}",
        "releases_url": "https://api.github.com/repos/flutter/cocoon/releases{/id}",
        "deployments_url": "https://api.github.com/repos/flutter/cocoon/deployments",
        "created_at": "2018-04-27T02:03:08Z",
        "updated_at": "2019-06-27T06:56:59Z",
        "pushed_at": "2019-07-03T19:40:11Z",
        "git_url": "git://github.com/flutter/cocoon.git",
        "ssh_url": "git@github.com:flutter/cocoon.git",
        "clone_url": "https://github.com/flutter/cocoon.git",
        "svn_url": "https://github.com/flutter/cocoon",
        "homepage": "https://flutter.io",
        "size": 94508,
        "stargazers_count": 1,
        "watchers_count": 1,
        "language": "Dart",
        "has_issues": false,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 0,
        "license": {
          "key": "other",
          "name": "Other",
          "spdx_id": "NOASSERTION",
          "url": null,
          "node_id": "MDc6TGljZW5zZTA="
        },
        "forks": 0,
        "open_issues": 0,
        "watchers": 1,
        "default_branch": "main"
      }
    },
    "base": {
      "label": "flutter:master",
      "ref": "master",
      "sha": "4cd12fc8b7d4cc2d8609182e1c4dea5cddc86890",
      "user": {
        "login": "flutter",
        "id": 14101776,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
        "avatar_url": "https://avatars3.githubblahblahblah",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "followers_url": "https://api.github.com/users/flutter/followers",
        "following_url": "https://api.github.com/users/flutter/following{/other_user}",
        "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
        "organizations_url": "https://api.github.com/users/flutter/orgs",
        "repos_url": "https://api.github.com/users/flutter/repos",
        "events_url": "https://api.github.com/users/flutter/events{/privacy}",
        "received_events_url": "https://api.github.com/users/flutter/received_events",
        "type": "Organization",
        "site_admin": false
      },
      "repo": {
        "id": 31792824,
        "node_id": "MDEwOlJlcG9zaXRvcnkzMTc5MjgyNA==",
        "name": "cocoon",
        "full_name": "flutter/cocoon",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 14101776,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
          "avatar_url": "https://avatars3.githubblahblahblah",
          "gravatar_id": "",
          "url": "https://api.github.com/users/flutter",
          "html_url": "https://github.com/flutter",
          "followers_url": "https://api.github.com/users/flutter/followers",
          "following_url": "https://api.github.com/users/flutter/following{/other_user}",
          "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
          "organizations_url": "https://api.github.com/users/flutter/orgs",
          "repos_url": "https://api.github.com/users/flutter/repos",
          "events_url": "https://api.github.com/users/flutter/events{/privacy}",
          "received_events_url": "https://api.github.com/users/flutter/received_events",
          "type": "Organization",
          "site_admin": false
        },
        "html_url": "https://github.com/flutter/cocoon",
        "description": "Flutter makes it easy and fast to build beautiful mobile apps.",
        "fork": false,
        "url": "https://api.github.com/repos/flutter/cocoon",
        "forks_url": "https://api.github.com/repos/flutter/cocoon/forks",
        "keys_url": "https://api.github.com/repos/flutter/cocoon/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/flutter/cocoon/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/flutter/cocoon/teams",
        "hooks_url": "https://api.github.com/repos/flutter/cocoon/hooks",
        "issue_events_url": "https://api.github.com/repos/flutter/cocoon/issues/events{/number}",
        "events_url": "https://api.github.com/repos/flutter/cocoon/events",
        "assignees_url": "https://api.github.com/repos/flutter/cocoon/assignees{/user}",
        "branches_url": "https://api.github.com/repos/flutter/cocoon/branches{/branch}",
        "tags_url": "https://api.github.com/repos/flutter/cocoon/tags",
        "blobs_url": "https://api.github.com/repos/flutter/cocoon/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/flutter/cocoon/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/flutter/cocoon/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/flutter/cocoon/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/flutter/cocoon/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/flutter/cocoon/languages",
        "stargazers_url": "https://api.github.com/repos/flutter/cocoon/stargazers",
        "contributors_url": "https://api.github.com/repos/flutter/cocoon/contributors",
        "subscribers_url": "https://api.github.com/repos/flutter/cocoon/subscribers",
        "subscription_url": "https://api.github.com/repos/flutter/cocoon/subscription",
        "commits_url": "https://api.github.com/repos/flutter/cocoon/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/flutter/cocoon/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/flutter/cocoon/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/flutter/cocoon/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/flutter/cocoon/contents/{+path}",
        "compare_url": "https://api.github.com/repos/flutter/cocoon/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/flutter/cocoon/merges",
        "archive_url": "https://api.github.com/repos/flutter/cocoon/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/flutter/cocoon/downloads",
        "issues_url": "https://api.github.com/repos/flutter/cocoon/issues{/number}",
        "pulls_url": "https://api.github.com/repos/flutter/cocoon/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/flutter/cocoon/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/flutter/cocoon/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/flutter/cocoon/labels{/name}",
        "releases_url": "https://api.github.com/repos/flutter/cocoon/releases{/id}",
        "deployments_url": "https://api.github.com/repos/flutter/cocoon/deployments",
        "created_at": "2015-03-06T22:54:58Z",
        "updated_at": "2019-07-04T02:08:44Z",
        "pushed_at": "2019-07-04T02:03:04Z",
        "git_url": "git://github.com/flutter/cocoon.git",
        "ssh_url": "git@github.com:flutter/cocoon.git",
        "clone_url": "https://github.com/flutter/cocoon.git",
        "svn_url": "https://github.com/flutter/cocoon",
        "homepage": "https://flutter.dev",
        "size": 65507,
        "stargazers_count": 68944,
        "watchers_count": 68944,
        "language": "Dart",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 7987,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 6536,
        "license": {
          "key": "other",
          "name": "Other",
          "spdx_id": "NOASSERTION",
          "url": null,
          "node_id": "MDc6TGljZW5zZTA="
        },
        "forks": 7987,
        "open_issues": 6536,
        "watchers": 68944,
        "default_branch": "main"
      }
    },
    "_links": {
      "self": {
        "href": "https://api.github.com/repos/flutter/cocoon/pulls/2"
      },
      "html": {
        "href": "https://github.com/flutter/cocoon/pull/2"
      },
      "issue": {
        "href": "https://api.github.com/repos/flutter/cocoon/issues/2"
      },
      "comments": {
        "href": "https://api.github.com/repos/flutter/cocoon/issues/2/comments"
      },
      "review_comments": {
        "href": "https://api.github.com/repos/flutter/cocoon/pulls/2/comments"
      },
      "review_comment": {
        "href": "https://api.github.com/repos/flutter/cocoon/pulls/comments{/number}"
      },
      "commits": {
        "href": "https://api.github.com/repos/flutter/cocoon/pulls/2/commits"
      },
      "statuses": {
        "href": "https://api.github.com/repos/flutter/cocoon/statuses/deadbeef"
      }
    },
    "author_association": "MEMBER",
    "draft" : false,
    "merged": false,
    "mergeable": null,
    "rebaseable": true,
    "mergeable_state": "draft",
    "merged_by": null,
    "comments": 1,
    "review_comments": 0,
    "maintainer_can_modify": true,
    "commits": 5,
    "additions": 55,
    "deletions": 36,
    "changed_files": 5
  },
  "repository": {
    "id": 1868532,
    "node_id": "MDEwOlJlcG9zaXRvcnkxODY4NTMwMDI=",
    "name": "cocoon",
    "full_name": "flutter/cocoon",
    "private": false,
    "owner": {
      "login": "flutter",
      "id": 21031067,
      "node_id": "MDQ6VXNlcjIxMDMxMDY3",
      "avatar_url": "https://avatars1.githubusercontent.com/u/21031067?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/flutter",
      "html_url": "https://github.com/flutter",
      "followers_url": "https://api.github.com/users/flutter/followers",
      "following_url": "https://api.github.com/users/flutter/following{/other_user}",
      "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
      "organizations_url": "https://api.github.com/users/flutter/orgs",
      "repos_url": "https://api.github.com/users/flutter/repos",
      "events_url": "https://api.github.com/users/flutter/events{/privacy}",
      "received_events_url": "https://api.github.com/users/flutter/received_events",
      "type": "User",
      "site_admin": false
    },
    "html_url": "https://github.com/flutter/cocoon",
    "description": null,
    "fork": false,
    "url": "https://api.github.com/repos/flutter/cocoon",
    "forks_url": "https://api.github.com/repos/flutter/cocoon/forks",
    "keys_url": "https://api.github.com/repos/flutter/cocoon/keys{/key_id}",
    "collaborators_url": "https://api.github.com/repos/flutter/cocoon/collaborators{/collaborator}",
    "teams_url": "https://api.github.com/repos/flutter/cocoon/teams",
    "hooks_url": "https://api.github.com/repos/flutter/cocoon/hooks",
    "issue_events_url": "https://api.github.com/repos/flutter/cocoon/issues/events{/number}",
    "events_url": "https://api.github.com/repos/flutter/cocoon/events",
    "assignees_url": "https://api.github.com/repos/flutter/cocoon/assignees{/user}",
    "branches_url": "https://api.github.com/repos/flutter/cocoon/branches{/branch}",
    "tags_url": "https://api.github.com/repos/flutter/cocoon/tags",
    "blobs_url": "https://api.github.com/repos/flutter/cocoon/git/blobs{/sha}",
    "git_tags_url": "https://api.github.com/repos/flutter/cocoon/git/tags{/sha}",
    "git_refs_url": "https://api.github.com/repos/flutter/cocoon/git/refs{/sha}",
    "trees_url": "https://api.github.com/repos/flutter/cocoon/git/trees{/sha}",
    "statuses_url": "https://api.github.com/repos/flutter/cocoon/statuses/{sha}",
    "languages_url": "https://api.github.com/repos/flutter/cocoon/languages",
    "stargazers_url": "https://api.github.com/repos/flutter/cocoon/stargazers",
    "contributors_url": "https://api.github.com/repos/flutter/cocoon/contributors",
    "subscribers_url": "https://api.github.com/repos/flutter/cocoon/subscribers",
    "subscription_url": "https://api.github.com/repos/flutter/cocoon/subscription",
    "commits_url": "https://api.github.com/repos/flutter/cocoon/commits{/sha}",
    "git_commits_url": "https://api.github.com/repos/flutter/cocoon/git/commits{/sha}",
    "comments_url": "https://api.github.com/repos/flutter/cocoon/comments{/number}",
    "issue_comment_url": "https://api.github.com/repos/flutter/cocoon/issues/comments{/number}",
    "contents_url": "https://api.github.com/repos/flutter/cocoon/contents/{+path}",
    "compare_url": "https://api.github.com/repos/flutter/cocoon/compare/{base}...{head}",
    "merges_url": "https://api.github.com/repos/flutter/cocoon/merges",
    "archive_url": "https://api.github.com/repos/flutter/cocoon/{archive_format}{/ref}",
    "downloads_url": "https://api.github.com/repos/flutter/cocoon/downloads",
    "issues_url": "https://api.github.com/repos/flutter/cocoon/issues{/number}",
    "pulls_url": "https://api.github.com/repos/flutter/cocoon/pulls{/number}",
    "milestones_url": "https://api.github.com/repos/flutter/cocoon/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/flutter/cocoon/notifications{?since,all,participating}",
    "labels_url": "https://api.github.com/repos/flutter/cocoon/labels{/name}",
    "releases_url": "https://api.github.com/repos/flutter/cocoon/releases{/id}",
    "deployments_url": "https://api.github.com/repos/flutter/cocoon/deployments",
    "created_at": "2019-05-15T15:19:25Z",
    "updated_at": "2019-05-15T15:19:27Z",
    "pushed_at": "2019-05-15T15:20:32Z",
    "git_url": "git://github.com/flutter/cocoon.git",
    "ssh_url": "git@github.com:flutter/cocoon.git",
    "clone_url": "https://github.com/flutter/cocoon.git",
    "svn_url": "https://github.com/flutter/cocoon",
    "homepage": null,
    "size": 0,
    "stargazers_count": 0,
    "watchers_count": 0,
    "language": null,
    "has_issues": true,
    "has_projects": true,
    "has_downloads": true,
    "has_wiki": true,
    "has_pages": true,
    "forks_count": 0,
    "mirror_url": null,
    "archived": false,
    "disabled": false,
    "open_issues_count": 2,
    "license": null,
    "forks": 0,
    "open_issues": 2,
    "watchers": 0,
    "default_branch": "master"
  },
  "sender": {
    "login": "cocoon",
    "id": 21031067,
    "node_id": "MDQ6VXNlcjIxMDMxMDY3",
    "avatar_url": "https://avatars1.githubusercontent.com/u/21031067?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/flutter",
    "html_url": "https://github.com/flutter",
    "followers_url": "https://api.github.com/users/flutter/followers",
    "following_url": "https://api.github.com/users/flutter/following{/other_user}",
    "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
    "organizations_url": "https://api.github.com/users/flutter/orgs",
    "repos_url": "https://api.github.com/users/flutter/repos",
    "events_url": "https://api.github.com/users/flutter/events{/privacy}",
    "received_events_url": "https://api.github.com/users/flutter/received_events",
    "type": "User",
    "site_admin": false
  }
}''';

final String webhookNoneAuthorMock = '''{
      "action": "open",
      "number": 1598,
      "pull_request": {
          "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
          "id": 1,
          "node_id": "MDExOlB1bGxSZXF1ZXN0MQ==",
          "html_url": "https://github.com/octocat/Hello-World/pull/1347",
          "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
          "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch",
          "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
          "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits",
          "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments",
          "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
          "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments",
          "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "number": 1347,
          "state": "open",
          "locked": true,
          "title": "Amazing new feature",
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
          "body": "Please pull these awesome changes in!",
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
          ],
          "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
            "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
            "id": 1002604,
            "node_id": "MDk6TWlsZXN0b25lMTAwMjYwNA==",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "Tracking milestone for version 1.0",
            "creator": {
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
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "updated_at": "2014-03-03T18:58:10Z",
            "closed_at": "2013-02-12T13:22:01Z",
            "due_on": "2012-10-09T23:39:01Z"
          },
          "active_lock_reason": "too heated",
          "created_at": "2011-01-26T19:01:12Z",
          "updated_at": "2011-01-26T19:01:12Z",
          "closed_at": "2011-01-26T19:01:12Z",
          "merged_at": "2011-01-26T19:01:12Z",
          "merge_commit_sha": "e5bd3914e2e596debea16f433f57875b5b90bcd6",
          "assignee": {
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
          "assignees": [
            {
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
            {
              "login": "hubot",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/hubot_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/hubot",
              "html_url": "https://github.com/hubot",
              "followers_url": "https://api.github.com/users/hubot/followers",
              "following_url": "https://api.github.com/users/hubot/following{/other_user}",
              "gists_url": "https://api.github.com/users/hubot/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/hubot/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/hubot/subscriptions",
              "organizations_url": "https://api.github.com/users/hubot/orgs",
              "repos_url": "https://api.github.com/users/hubot/repos",
              "events_url": "https://api.github.com/users/hubot/events{/privacy}",
              "received_events_url": "https://api.github.com/users/hubot/received_events",
              "type": "User",
              "site_admin": true
            }
          ],
          "requested_reviewers": [
            {
              "login": "other_user",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/other_user_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/other_user",
              "html_url": "https://github.com/other_user",
              "followers_url": "https://api.github.com/users/other_user/followers",
              "following_url": "https://api.github.com/users/other_user/following{/other_user}",
              "gists_url": "https://api.github.com/users/other_user/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/other_user/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/other_user/subscriptions",
              "organizations_url": "https://api.github.com/users/other_user/orgs",
              "repos_url": "https://api.github.com/users/other_user/repos",
              "events_url": "https://api.github.com/users/other_user/events{/privacy}",
              "received_events_url": "https://api.github.com/users/other_user/received_events",
              "type": "User",
              "site_admin": false
            }
          ],
          "requested_teams": [
            {
              "id": 1,
              "node_id": "MDQ6VGVhbTE=",
              "url": "https://api.github.com/teams/1",
              "html_url": "https://github.com/orgs/github/teams/justice-league",
              "name": "Justice League",
              "slug": "justice-league",
              "description": "A great team.",
              "privacy": "closed",
              "permission": "admin",
              "members_url": "https://api.github.com/teams/1/members{/member}",
              "repositories_url": "https://api.github.com/teams/1/repos"
            }
          ],
          "head": {
            "label": "octocat:new-topic",
            "ref": "new-topic",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "allow_forking": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "base": {
            "label": "octocat:master",
            "ref": "master",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "_links": {
            "self": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347"
            },
            "html": {
              "href": "https://github.com/octocat/Hello-World/pull/1347"
            },
            "issue": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347"
            },
            "comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments"
            },
            "review_comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments"
            },
            "review_comment": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}"
            },
            "commits": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits"
            },
            "statuses": {
              "href": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e"
            }
          },
          "author_association": "NONE",
          "auto_merge": null,
          "draft": false,
          "merged": false,
          "mergeable": true,
          "rebaseable": true,
          "mergeable_state": "clean",
          "comments": 10,
          "review_comments": 0,
          "maintainer_can_modify": true,
          "commits": 3,
          "additions": 100,
          "deletions": 3,
          "changed_files": 5
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

final String webhookNoLabelMock = '''{
      "action": "open",
      "number": 1598,
      "pull_request": {
          "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
          "id": 1,
          "node_id": "MDExOlB1bGxSZXF1ZXN0MQ==",
          "html_url": "https://github.com/octocat/Hello-World/pull/1347",
          "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
          "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch",
          "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
          "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits",
          "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments",
          "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}",
          "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments",
          "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "number": 1347,
          "state": "open",
          "locked": true,
          "title": "Amazing new feature",
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
          "body": "Please pull these awesome changes in!",
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
              "name": "hihihi",
              "color": "207de5",
              "default": false
            }
          ],
          "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
            "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
            "id": 1002604,
            "node_id": "MDk6TWlsZXN0b25lMTAwMjYwNA==",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "Tracking milestone for version 1.0",
            "creator": {
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
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "updated_at": "2014-03-03T18:58:10Z",
            "closed_at": "2013-02-12T13:22:01Z",
            "due_on": "2012-10-09T23:39:01Z"
          },
          "active_lock_reason": "too heated",
          "created_at": "2011-01-26T19:01:12Z",
          "updated_at": "2011-01-26T19:01:12Z",
          "closed_at": "2011-01-26T19:01:12Z",
          "merged_at": "2011-01-26T19:01:12Z",
          "merge_commit_sha": "e5bd3914e2e596debea16f433f57875b5b90bcd6",
          "assignee": {
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
          "assignees": [
            {
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
            {
              "login": "hubot",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/hubot_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/hubot",
              "html_url": "https://github.com/hubot",
              "followers_url": "https://api.github.com/users/hubot/followers",
              "following_url": "https://api.github.com/users/hubot/following{/other_user}",
              "gists_url": "https://api.github.com/users/hubot/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/hubot/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/hubot/subscriptions",
              "organizations_url": "https://api.github.com/users/hubot/orgs",
              "repos_url": "https://api.github.com/users/hubot/repos",
              "events_url": "https://api.github.com/users/hubot/events{/privacy}",
              "received_events_url": "https://api.github.com/users/hubot/received_events",
              "type": "User",
              "site_admin": true
            }
          ],
          "requested_reviewers": [
            {
              "login": "other_user",
              "id": 1,
              "node_id": "MDQ6VXNlcjE=",
              "avatar_url": "https://github.com/images/error/other_user_happy.gif",
              "gravatar_id": "",
              "url": "https://api.github.com/users/other_user",
              "html_url": "https://github.com/other_user",
              "followers_url": "https://api.github.com/users/other_user/followers",
              "following_url": "https://api.github.com/users/other_user/following{/other_user}",
              "gists_url": "https://api.github.com/users/other_user/gists{/gist_id}",
              "starred_url": "https://api.github.com/users/other_user/starred{/owner}{/repo}",
              "subscriptions_url": "https://api.github.com/users/other_user/subscriptions",
              "organizations_url": "https://api.github.com/users/other_user/orgs",
              "repos_url": "https://api.github.com/users/other_user/repos",
              "events_url": "https://api.github.com/users/other_user/events{/privacy}",
              "received_events_url": "https://api.github.com/users/other_user/received_events",
              "type": "User",
              "site_admin": false
            }
          ],
          "requested_teams": [
            {
              "id": 1,
              "node_id": "MDQ6VGVhbTE=",
              "url": "https://api.github.com/teams/1",
              "html_url": "https://github.com/orgs/github/teams/justice-league",
              "name": "Justice League",
              "slug": "justice-league",
              "description": "A great team.",
              "privacy": "closed",
              "permission": "admin",
              "members_url": "https://api.github.com/teams/1/members{/member}",
              "repositories_url": "https://api.github.com/teams/1/repos"
            }
          ],
          "head": {
            "label": "octocat:new-topic",
            "ref": "new-topic",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "allow_forking": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "base": {
            "label": "octocat:master",
            "ref": "master",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
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
            "repo": {
              "id": 1296269,
              "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
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
              "private": false,
              "html_url": "https://github.com/octocat/Hello-World",
              "description": "This your first repo!",
              "fork": false,
              "url": "https://api.github.com/repos/octocat/Hello-World",
              "homepage": "https://github.com",
              "language": null,
              "forks_count": 9,
              "stargazers_count": 80,
              "watchers_count": 80,
              "size": 108,
              "default_branch": "master",
              "open_issues_count": 0,
              "topics": [
                "octocat",
                "atom",
                "electron",
                "api"
              ],
              "has_issues": true,
              "has_projects": true,
              "has_wiki": true,
              "has_pages": false,
              "has_downloads": true,
              "archived": false,
              "disabled": false,
              "pushed_at": "2011-01-26T19:06:43Z",
              "created_at": "2011-01-26T19:01:12Z",
              "updated_at": "2011-01-26T19:14:43Z",
              "permissions": {
                "admin": false,
                "push": false,
                "pull": true
              },
              "allow_rebase_merge": true,
              "temp_clone_token": "ABTLWHOULUVAXGTRYU7OC2876QJ2O",
              "allow_squash_merge": true,
              "allow_merge_commit": true,
              "forks": 123,
              "open_issues": 123,
              "license": {
                "key": "mit",
                "name": "MIT License",
                "url": "https://api.github.com/licenses/mit",
                "spdx_id": "MIT",
                "node_id": "MDc6TGljZW5zZW1pdA=="
              },
              "watchers": 123
            }
          },
          "_links": {
            "self": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347"
            },
            "html": {
              "href": "https://github.com/octocat/Hello-World/pull/1347"
            },
            "issue": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347"
            },
            "comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments"
            },
            "review_comments": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/comments"
            },
            "review_comment": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments{/number}"
            },
            "commits": {
              "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1347/commits"
            },
            "statuses": {
              "href": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e"
            }
          },
          "author_association": "OWNER",
          "auto_merge": null,
          "draft": false,
          "merged": false,
          "mergeable": true,
          "rebaseable": true,
          "mergeable_state": "clean",
          "comments": 10,
          "review_comments": 0,
          "maintainer_can_modify": true,
          "commits": 3,
          "additions": 100,
          "deletions": 3,
          "changed_files": 5
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

// reviewsMock is from the official Github API: https://docs.github.com/en/rest/reference/pulls#list-reviews-for-a-pull-request
final String reviewsMock = '''[
  {
    "id": 80,
    "node_id": "MDE3OlB1bGxSZXF1ZXN0UmV2aWV3ODA=",
    "user": {
      "login": "octocat2",
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

String unApprovedReviewsMock = '''[
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
    "state": "CHANGES_REQUESTED",
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

// checkRunsMock is from the official Github API: https://docs.github.com/en/rest/reference/checks#list-check-runs-for-a-git-reference
final String checkRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 4,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "node_id": "MDg6Q2hlY2tSdW40",
      "external_id": "",
      "url": "https://api.github.com/repos/github/hello-world/check-runs/4",
      "html_url": "https://github.com/github/hello-world/runs/4",
      "details_url": "https://example.com",
      "status": "completed",
      "conclusion": "success",
      "started_at": "2018-05-04T01:14:52Z",
      "completed_at": "2018-05-04T01:14:52Z",
      "output": {
        "title": "Mighty Readme report",
        "summary": "There are 0 failures, 2 warnings, and 1 notice.",
        "text": "You may have some misspelled words on lines 2 and 4. You also may want to add a section in your README about how to install your app.",
        "annotations_count": 2,
        "annotations_url": "https://api.github.com/repos/github/hello-world/check-runs/4/annotations"
      },
      "name": "mighty_readme",
      "check_suite": {
        "id": 5
      },
      "app": {
        "id": 1,
        "slug": "octoapp",
        "node_id": "MDExOkludGVncmF0aW9uMQ==",
        "owner": {
          "login": "github",
          "id": 1,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjE=",
          "url": "https://api.github.com/orgs/github",
          "repos_url": "https://api.github.com/orgs/github/repos",
          "events_url": "https://api.github.com/orgs/github/events",
          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
          "gravatar_id": "",
          "html_url": "https://github.com/octocat",
          "followers_url": "https://api.github.com/users/octocat/followers",
          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
          "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
          "organizations_url": "https://api.github.com/users/octocat/orgs",
          "received_events_url": "https://api.github.com/users/octocat/received_events",
          "type": "User",
          "site_admin": true
        },
        "name": "Octocat App",
        "description": "",
        "external_url": "https://example.com",
        "html_url": "https://github.com/apps/octoapp",
        "created_at": "2017-07-08T16:18:44-04:00",
        "updated_at": "2017-07-08T16:18:44-04:00",
        "permissions": {
          "metadata": "read",
          "contents": "read",
          "issues": "write",
          "single_file": "write"
        },
        "events": [
          "push",
          "pull_request"
        ]
      },
      "pull_requests": [
        {
          "url": "https://api.github.com/repos/github/hello-world/pulls/1",
          "id": 1934,
          "number": 3956,
          "head": {
            "ref": "say-hello",
            "sha": "3dca65fa3e8d4b3da3f3d056c59aee1c50f41390",
            "repo": {
              "id": 526,
              "url": "https://api.github.com/repos/github/hello-world",
              "name": "hello-world"
            }
          },
          "base": {
            "ref": "master",
            "sha": "e7fdf7640066d71ad16a86fbcbb9c6a10a18af4f",
            "repo": {
              "id": 526,
              "url": "https://api.github.com/repos/github/hello-world",
              "name": "hello-world"
            }
          }
        }
      ]
    }
  ]
}''';

final String failedCheckRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 4,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "node_id": "MDg6Q2hlY2tSdW40",
      "external_id": "",
      "url": "https://api.github.com/repos/github/hello-world/check-runs/4",
      "html_url": "https://github.com/github/hello-world/runs/4",
      "details_url": "https://example.com",
      "status": "completed",
      "conclusion": "failure",
      "started_at": "2018-05-04T01:14:52Z",
      "completed_at": "2018-05-04T01:14:52Z",
      "output": {
        "title": "Mighty Readme report",
        "summary": "There are 0 failures, 2 warnings, and 1 notice.",
        "text": "You may have some misspelled words on lines 2 and 4. You also may want to add a section in your README about how to install your app.",
        "annotations_count": 2,
        "annotations_url": "https://api.github.com/repos/github/hello-world/check-runs/4/annotations"
      },
      "name": "mighty_readme",
      "check_suite": {
        "id": 5
      },
      "app": {
        "id": 1,
        "slug": "octoapp",
        "node_id": "MDExOkludGVncmF0aW9uMQ==",
        "owner": {
          "login": "github",
          "id": 1,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjE=",
          "url": "https://api.github.com/orgs/github",
          "repos_url": "https://api.github.com/orgs/github/repos",
          "events_url": "https://api.github.com/orgs/github/events",
          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
          "gravatar_id": "",
          "html_url": "https://github.com/octocat",
          "followers_url": "https://api.github.com/users/octocat/followers",
          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
          "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
          "organizations_url": "https://api.github.com/users/octocat/orgs",
          "received_events_url": "https://api.github.com/users/octocat/received_events",
          "type": "User",
          "site_admin": true
        },
        "name": "Octocat App",
        "description": "",
        "external_url": "https://example.com",
        "html_url": "https://github.com/apps/octoapp",
        "created_at": "2017-07-08T16:18:44-04:00",
        "updated_at": "2017-07-08T16:18:44-04:00",
        "permissions": {
          "metadata": "read",
          "contents": "read",
          "issues": "write",
          "single_file": "write"
        },
        "events": [
          "push",
          "pull_request"
        ]
      },
      "pull_requests": [
        {
          "url": "https://api.github.com/repos/github/hello-world/pulls/1",
          "id": 1934,
          "number": 3956,
          "head": {
            "ref": "say-hello",
            "sha": "3dca65fa3e8d4b3da3f3d056c59aee1c50f41390",
            "repo": {
              "id": 526,
              "url": "https://api.github.com/repos/github/hello-world",
              "name": "hello-world"
            }
          },
          "base": {
            "ref": "master",
            "sha": "e7fdf7640066d71ad16a86fbcbb9c6a10a18af4f",
            "repo": {
              "id": 526,
              "url": "https://api.github.com/repos/github/hello-world",
              "name": "hello-world"
            }
          }
        }
      ]
    }
  ]
}''';

String inProgressCheckRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 4,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "node_id": "MDg6Q2hlY2tSdW40",
      "external_id": "",
      "url": "https://api.github.com/repos/github/hello-world/check-runs/4",
      "html_url": "https://github.com/github/hello-world/runs/4",
      "details_url": "https://example.com",
      "status": "in_progress",
      "conclusion": "neutral",
      "started_at": "2018-05-04T01:14:52Z",
      "completed_at": "2018-05-04T01:14:52Z",
      "output": {
        "title": "Mighty Readme report",
        "summary": "There are 0 failures, 2 warnings, and 1 notice.",
        "text": "You may have some misspelled words on lines 2 and 4. You also may want to add a section in your README about how to install your app.",
        "annotations_count": 2,
        "annotations_url": "https://api.github.com/repos/github/hello-world/check-runs/4/annotations"
      },
      "name": "mighty_readme",
      "check_suite": {
        "id": 5
      },
      "app": {
        "id": 1,
        "slug": "octoapp",
        "node_id": "MDExOkludGVncmF0aW9uMQ==",
        "owner": {
          "login": "github",
          "id": 1,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjE=",
          "url": "https://api.github.com/orgs/github",
          "repos_url": "https://api.github.com/orgs/github/repos",
          "events_url": "https://api.github.com/orgs/github/events",
          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
          "gravatar_id": "",
          "html_url": "https://github.com/octocat",
          "followers_url": "https://api.github.com/users/octocat/followers",
          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
          "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
          "organizations_url": "https://api.github.com/users/octocat/orgs",
          "received_events_url": "https://api.github.com/users/octocat/received_events",
          "type": "User",
          "site_admin": true
        },
        "name": "Octocat App",
        "description": "",
        "external_url": "https://example.com",
        "html_url": "https://github.com/apps/octoapp",
        "created_at": "2017-07-08T16:18:44-04:00",
        "updated_at": "2017-07-08T16:18:44-04:00",
        "permissions": {
          "metadata": "read",
          "contents": "read",
          "issues": "write",
          "single_file": "write"
        },
        "events": [
          "push",
          "pull_request"
        ]
      },
      "pull_requests": [
        {
          "url": "https://api.github.com/repos/github/hello-world/pulls/1",
          "id": 1934,
          "number": 3956,
          "head": {
            "ref": "say-hello",
            "sha": "3dca65fa3e8d4b3da3f3d056c59aee1c50f41390",
            "repo": {
              "id": 526,
              "url": "https://api.github.com/repos/github/hello-world",
              "name": "hello-world"
            }
          },
          "base": {
            "ref": "master",
            "sha": "e7fdf7640066d71ad16a86fbcbb9c6a10a18af4f",
            "repo": {
              "id": 526,
              "url": "https://api.github.com/repos/github/hello-world",
              "name": "hello-world"
            }
          }
        }
      ]
    }
  ]
}''';

final String emptyCheckRunsMock = '''{"check_runs": [{}]}''';

// repositoryStatusesMock is from the official Github API: https://developer.github.com/v3/repos/statuses/#list-statuses-for-a-specific-ref
final String repositoryStatusesMock = '''{
  "state": "success",
  "statuses": [
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "avatar_url": "https://github.com/images/error/hubot_happy.gif",
      "id": 1,
      "node_id": "MDY6U3RhdHVzMQ==",
      "state": "success",
      "description": "Build has completed successfully",
      "target_url": "https://ci.example.com/1000/output",
      "context": "luci-flutter",
      "created_at": "2012-07-20T01:19:13Z",
      "updated_at": "2012-07-20T01:19:13Z"
    },
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "avatar_url": "https://github.com/images/error/other_user_happy.gif",
      "id": 2,
      "node_id": "MDY6U3RhdHVzMg==",
      "state": "success",
      "description": "Testing has completed successfully",
      "target_url": "https://ci.example.com/2000/output",
      "context": "luci-flutter/flutter",
      "created_at": "2012-08-20T01:19:13Z",
      "updated_at": "2012-08-20T01:19:13Z"
    }
  ],
  "sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
  "total_count": 2,
  "repository": {
    "id": 1296269,
    "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
    "name": "Hello-World",
    "full_name": "octocat/Hello-World",
    "owner": {
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
    "private": false,
    "html_url": "https://github.com/octocat/Hello-World",
    "description": "This your first repo!",
    "fork": false,
    "url": "https://api.github.com/repos/octocat/Hello-World",
    "archive_url": "https://api.github.com/repos/octocat/Hello-World/{archive_format}{/ref}",
    "assignees_url": "https://api.github.com/repos/octocat/Hello-World/assignees{/user}",
    "blobs_url": "https://api.github.com/repos/octocat/Hello-World/git/blobs{/sha}",
    "branches_url": "https://api.github.com/repos/octocat/Hello-World/branches{/branch}",
    "collaborators_url": "https://api.github.com/repos/octocat/Hello-World/collaborators{/collaborator}",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/comments{/number}",
    "commits_url": "https://api.github.com/repos/octocat/Hello-World/commits{/sha}",
    "compare_url": "https://api.github.com/repos/octocat/Hello-World/compare/{base}...{head}",
    "contents_url": "https://api.github.com/repos/octocat/Hello-World/contents/{+path}",
    "contributors_url": "https://api.github.com/repos/octocat/Hello-World/contributors",
    "deployments_url": "https://api.github.com/repos/octocat/Hello-World/deployments",
    "downloads_url": "https://api.github.com/repos/octocat/Hello-World/downloads",
    "events_url": "https://api.github.com/repos/octocat/Hello-World/events",
    "forks_url": "https://api.github.com/repos/octocat/Hello-World/forks",
    "git_commits_url": "https://api.github.com/repos/octocat/Hello-World/git/commits{/sha}",
    "git_refs_url": "https://api.github.com/repos/octocat/Hello-World/git/refs{/sha}",
    "git_tags_url": "https://api.github.com/repos/octocat/Hello-World/git/tags{/sha}",
    "git_url": "git:github.com/octocat/Hello-World.git",
    "issue_comment_url": "https://api.github.com/repos/octocat/Hello-World/issues/comments{/number}",
    "issue_events_url": "https://api.github.com/repos/octocat/Hello-World/issues/events{/number}",
    "issues_url": "https://api.github.com/repos/octocat/Hello-World/issues{/number}",
    "keys_url": "https://api.github.com/repos/octocat/Hello-World/keys{/key_id}",
    "labels_url": "https://api.github.com/repos/octocat/Hello-World/labels{/name}",
    "languages_url": "https://api.github.com/repos/octocat/Hello-World/languages",
    "merges_url": "https://api.github.com/repos/octocat/Hello-World/merges",
    "milestones_url": "https://api.github.com/repos/octocat/Hello-World/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/octocat/Hello-World/notifications{?since,all,participating}",
    "pulls_url": "https://api.github.com/repos/octocat/Hello-World/pulls{/number}",
    "releases_url": "https://api.github.com/repos/octocat/Hello-World/releases{/id}",
    "ssh_url": "git@github.com:octocat/Hello-World.git",
    "stargazers_url": "https://api.github.com/repos/octocat/Hello-World/stargazers",
    "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/{sha}",
    "subscribers_url": "https://api.github.com/repos/octocat/Hello-World/subscribers",
    "subscription_url": "https://api.github.com/repos/octocat/Hello-World/subscription",
    "tags_url": "https://api.github.com/repos/octocat/Hello-World/tags",
    "teams_url": "https://api.github.com/repos/octocat/Hello-World/teams",
    "trees_url": "https://api.github.com/repos/octocat/Hello-World/git/trees{/sha}",
    "hooks_url": "http://api.github.com/repos/octocat/Hello-World/hooks"
  },
  "commit_url": "https://api.github.com/repos/octocat/Hello-World/6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "url": "https://api.github.com/repos/octocat/Hello-World/6dcb09b5b57875f334f61aebed695e2e4193db5e/status"
}''';

String failedRepositoryStatusesMock = '''{
  "state": "failure",
  "statuses": [
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "avatar_url": "https://github.com/images/error/hubot_happy.gif",
      "id": 1,
      "node_id": "MDY6U3RhdHVzMQ==",
      "state": "failure",
      "description": "Build has completed successfully",
      "target_url": "https://ci.example.com/1000/output",
      "context": "luci-flutter",
      "created_at": "2012-07-20T01:19:13Z",
      "updated_at": "2012-07-20T01:19:13Z"
    },
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "avatar_url": "https://github.com/images/error/other_user_happy.gif",
      "id": 2,
      "node_id": "MDY6U3RhdHVzMg==",
      "state": "failure",
      "description": "Testing has completed successfully",
      "target_url": "https://ci.example.com/2000/output",
      "context": "luci-engine",
      "created_at": "2012-08-20T01:19:13Z",
      "updated_at": "2012-08-20T01:19:13Z"
    }
  ],
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "total_count": 2,
  "repository": {
    "id": 1296269,
    "node_id": "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
    "name": "Hello-World",
    "full_name": "octocat/Hello-World",
    "owner": {
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
    "private": false,
    "html_url": "https://github.com/octocat/Hello-World",
    "description": "This your first repo!",
    "fork": false,
    "url": "https://api.github.com/repos/octocat/Hello-World",
    "archive_url": "https://api.github.com/repos/octocat/Hello-World/{archive_format}{/ref}",
    "assignees_url": "https://api.github.com/repos/octocat/Hello-World/assignees{/user}",
    "blobs_url": "https://api.github.com/repos/octocat/Hello-World/git/blobs{/sha}",
    "branches_url": "https://api.github.com/repos/octocat/Hello-World/branches{/branch}",
    "collaborators_url": "https://api.github.com/repos/octocat/Hello-World/collaborators{/collaborator}",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/comments{/number}",
    "commits_url": "https://api.github.com/repos/octocat/Hello-World/commits{/sha}",
    "compare_url": "https://api.github.com/repos/octocat/Hello-World/compare/{base}...{head}",
    "contents_url": "https://api.github.com/repos/octocat/Hello-World/contents/{+path}",
    "contributors_url": "https://api.github.com/repos/octocat/Hello-World/contributors",
    "deployments_url": "https://api.github.com/repos/octocat/Hello-World/deployments",
    "downloads_url": "https://api.github.com/repos/octocat/Hello-World/downloads",
    "events_url": "https://api.github.com/repos/octocat/Hello-World/events",
    "forks_url": "https://api.github.com/repos/octocat/Hello-World/forks",
    "git_commits_url": "https://api.github.com/repos/octocat/Hello-World/git/commits{/sha}",
    "git_refs_url": "https://api.github.com/repos/octocat/Hello-World/git/refs{/sha}",
    "git_tags_url": "https://api.github.com/repos/octocat/Hello-World/git/tags{/sha}",
    "git_url": "git:github.com/octocat/Hello-World.git",
    "issue_comment_url": "https://api.github.com/repos/octocat/Hello-World/issues/comments{/number}",
    "issue_events_url": "https://api.github.com/repos/octocat/Hello-World/issues/events{/number}",
    "issues_url": "https://api.github.com/repos/octocat/Hello-World/issues{/number}",
    "keys_url": "https://api.github.com/repos/octocat/Hello-World/keys{/key_id}",
    "labels_url": "https://api.github.com/repos/octocat/Hello-World/labels{/name}",
    "languages_url": "https://api.github.com/repos/octocat/Hello-World/languages",
    "merges_url": "https://api.github.com/repos/octocat/Hello-World/merges",
    "milestones_url": "https://api.github.com/repos/octocat/Hello-World/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/octocat/Hello-World/notifications{?since,all,participating}",
    "pulls_url": "https://api.github.com/repos/octocat/Hello-World/pulls{/number}",
    "releases_url": "https://api.github.com/repos/octocat/Hello-World/releases{/id}",
    "ssh_url": "git@github.com:octocat/Hello-World.git",
    "stargazers_url": "https://api.github.com/repos/octocat/Hello-World/stargazers",
    "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/{sha}",
    "subscribers_url": "https://api.github.com/repos/octocat/Hello-World/subscribers",
    "subscription_url": "https://api.github.com/repos/octocat/Hello-World/subscription",
    "tags_url": "https://api.github.com/repos/octocat/Hello-World/tags",
    "teams_url": "https://api.github.com/repos/octocat/Hello-World/teams",
    "trees_url": "https://api.github.com/repos/octocat/Hello-World/git/trees{/sha}",
    "hooks_url": "http://api.github.com/repos/octocat/Hello-World/hooks"
  },
  "commit_url": "https://api.github.com/repos/octocat/Hello-World/6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "url": "https://api.github.com/repos/octocat/Hello-World/6dcb09b5b57875f334f61aebed695e2e4193db5e/status"
}''';

final String emptyStatusesMock = '''{"statuses": [{}]}''';

// commitMock is from the official Github API: https://docs.github.com/en/rest/reference/commits#get-a-commit
final String commitMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "sha": "HEAD~",
  "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
  "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
  "commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "author": {
      "name": "Monalisa Octocat",
      "email": "mona@github.com",
      "date": "2011-04-14T16:00:49Z"
    },
    "committer": {
      "name": "Monalisa Octocat",
      "email": "mona@github.com",
      "date": "2011-04-14T16:00:49Z"
    },
    "message": "Fix all the bugs",
    "tree": {
      "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
    },
    "comment_count": 0,
    "verification": {
      "verified": false,
      "reason": "unsigned",
      "signature": null,
      "payload": null
    }
  },
  "author": {
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
  "committer": {
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
  "parents": [
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
    }
  ],
  "stats": {
    "additions": 104,
    "deletions": 4,
    "total": 108
  },
  "files": [
    {
      "filename": "file1.txt",
      "additions": 10,
      "deletions": 2,
      "changes": 12,
      "status": "modified",
      "raw_url": "https://github.com/octocat/Hello-World/raw/7ca483543807a51b6079e54ac4cc392bc29ae284/file1.txt",
      "blob_url": "https://github.com/octocat/Hello-World/blob/7ca483543807a51b6079e54ac4cc392bc29ae284/file1.txt",
      "patch": "@@ -29,7 +29,7 @@ ....."
    }
  ]
}''';

// compareTowCOmmitsMock is from the official Github API: https://docs.github.com/en/rest/reference/commits#compare-two-commits
final String compareTowCommitsMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
  "html_url": "https://github.com/octocat/Hello-World/compare/master...topic",
  "permalink_url": "https://github.com/octocat/Hello-World/compare/octocat:bbcd538c8e72b8c175046e27cc8f907076331401...octocat:0328041d1152db8ae77652d1618a02e57f745f17",
  "diff_url": "https://github.com/octocat/Hello-World/compare/master...topic.diff",
  "patch_url": "https://github.com/octocat/Hello-World/compare/master...topic.patch",
  "base_commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
    "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
    "commit": {
      "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "author": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "committer": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "message": "Fix all the bugs",
      "tree": {
        "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      },
      "comment_count": 0,
      "verification": {
        "verified": false,
        "reason": "unsigned",
        "signature": null,
        "payload": null
      }
    },
    "author": {
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
    "committer": {
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
    "parents": [
      {
        "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      }
    ]
  },
  "merge_base_commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
    "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
    "commit": {
      "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "author": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "committer": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "message": "Fix all the bugs",
      "tree": {
        "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      },
      "comment_count": 0,
      "verification": {
        "verified": false,
        "reason": "unsigned",
        "signature": null,
        "payload": null
      }
    },
    "author": {
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
    "committer": {
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
    "parents": [
      {
        "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      }
    ]
  },
  "status": "behind",
  "ahead_by": 1,
  "behind_by": 2,
  "total_commits": 1,
  "commits": [
    {
      "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
      "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
      "commit": {
        "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "author": {
          "name": "Monalisa Octocat",
          "email": "mona@github.com",
          "date": "2011-04-14T16:00:49Z"
        },
        "committer": {
          "name": "Monalisa Octocat",
          "email": "mona@github.com",
          "date": "2011-04-14T16:00:49Z"
        },
        "message": "Fix all the bugs",
        "tree": {
          "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
        },
        "comment_count": 0,
        "verification": {
          "verified": false,
          "reason": "unsigned",
          "signature": null,
          "payload": null
        }
      },
      "author": {
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
      "committer": {
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
      "parents": [
        {
          "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
          "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
        }
      ]
    }
  ],
  "files": [
    {
      "sha": "bbcd538c8e72b8c175046e27cc8f907076331401",
      "filename": "file1.txt",
      "status": "added",
      "additions": 103,
      "deletions": 21,
      "changes": 124,
      "blob_url": "https://github.com/octocat/Hello-World/blob/6dcb09b5b57875f334f61aebed695e2e4193db5e/file1.txt",
      "raw_url": "https://github.com/octocat/Hello-World/raw/6dcb09b5b57875f334f61aebed695e2e4193db5e/file1.txt",
      "contents_url": "https://api.github.com/repos/octocat/Hello-World/contents/file1.txt?ref=6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "patch": "@@ -132,7 +132,7 @@ module Test @@ -1000,7 +1000,7 @@ module Test"
    }
  ]
}''';

final String compareToTCommitsMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
  "html_url": "https://github.com/octocat/Hello-World/compare/master...topic",
  "permalink_url": "https://github.com/octocat/Hello-World/compare/octocat:bbcd538c8e72b8c175046e27cc8f907076331401...octocat:0328041d1152db8ae77652d1618a02e57f745f17",
  "diff_url": "https://github.com/octocat/Hello-World/compare/master...topic.diff",
  "patch_url": "https://github.com/octocat/Hello-World/compare/master...topic.patch",
  "base_commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
    "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
    "commit": {
      "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "author": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "committer": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "message": "Fix all the bugs",
      "tree": {
        "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      },
      "comment_count": 0,
      "verification": {
        "verified": false,
        "reason": "unsigned",
        "signature": null,
        "payload": null
      }
    },
    "author": {
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
    "committer": {
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
    "parents": [
      {
        "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      }
    ]
  },
  "merge_base_commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "node_id": "MDY6Q29tbWl0NmRjYjA5YjViNTc4NzVmMzM0ZjYxYWViZWQ2OTVlMmU0MTkzZGI1ZQ==",
    "html_url": "https://github.com/octocat/Hello-World/commit/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "comments_url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e/comments",
    "commit": {
      "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "author": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "committer": {
        "name": "Monalisa Octocat",
        "email": "mona@github.com",
        "date": "2011-04-14T16:00:49Z"
      },
      "message": "Fix all the bugs",
      "tree": {
        "url": "https://api.github.com/repos/octocat/Hello-World/tree/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      },
      "comment_count": 0,
      "verification": {
        "verified": false,
        "reason": "unsigned",
        "signature": null,
        "payload": null
      }
    },
    "author": {
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
    "committer": {
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
    "parents": [
      {
        "url": "https://api.github.com/repos/octocat/Hello-World/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e"
      }
    ]
  },
  "files": []
}''';

// successMergeMock is from the offcial github API: https://docs.github.com/en/rest/reference/pulls#merge-a-pull-request.
final String successMergeMock = '''
{
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "merged": true
}''';

// createCommentMock is from the offcial github API: https://docs.github.com/en/rest/reference/pulls#create-a-review-comment-for-a-pull-request.
final String createCommentMock = '''
{
  "url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments/1",
  "pull_request_review_id": 42,
  "id": 10,
  "node_id": "MDI0OlB1bGxSZXF1ZXN0UmV2aWV3Q29tbWVudDEw",
  "diff_hunk": "@@ -16,33 +16,40 @@ public class Connection : IConnection...",
  "path": "file1.txt",
  "position": 1,
  "original_position": 4,
  "commit_id": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "original_commit_id": "9c48853fa3dc5c1c3d6f1f1cd1f2743e72652840",
  "in_reply_to_id": 8,
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
  "body": "Great stuff!",
  "created_at": "2011-04-14T16:00:49Z",
  "updated_at": "2011-04-14T16:00:49Z",
  "html_url": "https://github.com/octocat/Hello-World/pull/1#discussion-diff-1",
  "pull_request_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1",
  "author_association": "NONE",
  "_links": {
    "self": {
      "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments/1"
    },
    "html": {
      "href": "https://github.com/octocat/Hello-World/pull/1#discussion-diff-1"
    },
    "pull_request": {
      "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1"
    }
  },
  "start_line": 1,
  "original_start_line": 1,
  "start_side": "RIGHT",
  "line": 2,
  "original_line": 2,
  "side": "RIGHT"
}''';
