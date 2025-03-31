// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String checkSuiteString = checkSuiteTemplate('requested');

String checkSuiteTemplate(String action) => '''\
{
    "action": "$action",
    "check_suite": {
        "id": 694267587,
        "node_id": "MDEwOkNoZWNrU3VpdGU2OTQyNjc1ODc=",
        "head_branch": "update_licenses",
        "head_sha": "dabc07b74c555c9952f7b63e139f2bb83b75250f",
        "status": "queued",
        "conclusion": "success",
        "url": "https://api.github.com/repos/flutter/cocoon/check-suites/694267587",
        "before": "5763f4c2b3b5e529f4b35c655761a7e818eced2e",
        "after": "dabc07b74c555c9952f7b63e139f2bb83b75250f",
        "pull_requests": [
            {
                "url": "https://api.github.com/repos/flutter/cocoon/pulls/758",
                "id": 409012032,
                "number": 758,
                "head": {
                    "ref": "update_licenses",
                    "sha": "5763f4c2b3b5e529f4b35c655761a7e818eced2e",
                    "repo": {
                        "id": 212688278,
                        "url": "https://api.github.com/repos/flutter/cocoon",
                        "name": "cocoon"
                    }
                },
                "base": {
                    "ref": "main",
                    "sha": "cc430b2e8d6448dfbacf5bcbbd6160cd1fe9dc0b",
                    "repo": {
                        "id": 63260554,
                        "url": "https://api.github.com/repos/flutter/cocoon",
                        "name": "cocoon",
                        "owner": {
                          "avatar_url": "",
                          "html_url": "",
                          "login": "flutter",
                          "id": 54371434
                        }
                    }
                }
            }
        ],
        "app": {
            "id": 64368,
            "slug": "test",
            "node_id": "MDM6QXBwNjQzNjg=",
            "owner": {
                "login": "abc",
                "id": 54371434,
                "node_id": "MDQ6VXNlcjU0MzcxNDM0",
                "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
                "gravatar_id": "",
                "url": "https://api.github.com/users/abc",
                "html_url": "https://github.com/abc",
                "followers_url": "https://api.github.com/users/abc/followers",
                "following_url": "https://api.github.com/users/abc/following{/other_user}",
                "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
                "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
                "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
                "organizations_url": "https://api.github.com/users/abc/orgs",
                "repos_url": "https://api.github.com/users/abc/repos",
                "events_url": "https://api.github.com/users/abc/events{/privacy}",
                "received_events_url": "https://api.github.com/users/abc/received_events",
                "type": "User",
                "site_admin": false
            },
            "name": "godofredo-test",
            "description": "",
            "external_url": "https://flutter-dashboard.appspot.com",
            "html_url": "https://github.com/apps/test",
            "created_at": "2020-05-10T00:32:46Z",
            "updated_at": "2020-05-10T00:32:46Z",
            "permissions": {
                "checks": "write",
                "contents": "read",
                "metadata": "read"
            },
            "events": [
                "check_run",
                "check_suite",
                "label"
            ]
        },
        "created_at": "2020-05-18T23:04:25Z",
        "updated_at": "2020-05-18T23:04:25Z",
        "latest_check_runs_count": 0,
        "check_runs_url": "https://api.github.com/repos/flutter/cocoon/check-suites/694267587/check-runs",
        "head_commit": {
            "id": "dabc07b74c555c9952f7b63e139f2bb83b75250f",
            "tree_id": "5f8bd91387bbb9b5db90ab63ac9229224d1b6044",
            "message": "Add checks and tests for license folder.",
            "timestamp": "2020-05-18T23:03:38Z",
            "author": {
                "name": "abc",
                "email": "abc@abcd.com"
            },
            "committer": {
                "name": "abc",
                "email": "abc@abcd.com"
            }
        }
    },
    "repository": {
        "id": 212688278,
        "node_id": "MDEwOlJlcG9zaXRvcnkyMTI2ODgyNzg=",
        "name": "cocoon",
        "full_name": "flutter/cocoon",
        "private": false,
        "owner": {
            "login": "abc",
            "id": 54371434,
            "node_id": "MDQ6VXNlcjU0MzcxNDM0",
            "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/abc",
            "html_url": "https://github.com/abc",
            "followers_url": "https://api.github.com/users/abc/followers",
            "following_url": "https://api.github.com/users/abc/following{/other_user}",
            "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
            "organizations_url": "https://api.github.com/users/abc/orgs",
            "repos_url": "https://api.github.com/users/abc/repos",
            "events_url": "https://api.github.com/users/abc/events{/privacy}",
            "received_events_url": "https://api.github.com/users/abc/received_events",
            "type": "User",
            "site_admin": false
        },
        "html_url": "https://github.com/flutter/cocoon",
        "description": "Flutter's build coordinator and aggregator",
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
        "created_at": "2019-10-03T21:57:12Z",
        "updated_at": "2019-10-03T21:57:14Z",
        "pushed_at": "2020-05-18T23:04:24Z",
        "git_url": "git://github.com/flutter/cocoon.git",
        "ssh_url": "git@github.com:flutter/cocoon.git",
        "clone_url": "https://github.com/flutter/cocoon.git",
        "svn_url": "https://github.com/flutter/cocoon",
        "homepage": null,
        "size": 3070,
        "stargazers_count": 0,
        "watchers_count": 0,
        "language": null,
        "has_issues": false,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": false,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 1,
        "license": {
            "key": "clause",
            "name": "License",
            "spdx_id": "",
            "url": "",
            "node_id": "MDc6TGljZW5zZTU="
        },
        "forks": 0,
        "open_issues": 1,
        "watchers": 0,
        "default_branch": "main"
    },
    "sender": {
        "login": "abc",
        "id": 54371434,
        "node_id": "MDQ6VXNlcjU0MzcxNDM0",
        "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/abc",
        "html_url": "https://github.com/abc",
        "followers_url": "https://api.github.com/users/abc/followers",
        "following_url": "https://api.github.com/users/abc/following{/other_user}",
        "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
        "organizations_url": "https://api.github.com/users/abc/orgs",
        "repos_url": "https://api.github.com/users/abc/repos",
        "events_url": "https://api.github.com/users/abc/events{/privacy}",
        "received_events_url": "https://api.github.com/users/abc/received_events",
        "type": "User",
        "site_admin": false
    },
    "installation": {
        "id": 8770981,
        "node_id": "MDIzOkludGVncmF0aW9uSW5zdGFsbGF0aW9uODc3MDk4MQ=="
    }
}
''';

String checkRunString({String repository = 'cocoon'}) => '''
{
    "action": "rerequested",
    "check_run": {
        "id": 660053389,
        "node_id": "MDg6Q2hlY2tSdW42NjAwNTMzODk=",
        "head_sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
        "external_id": "",
        "url": "https://api.github.com/repos/flutter/$repository/check-runs/660053389",
        "html_url": "https://github.com/flutter/$repository/runs/660053389",
        "details_url": "https://flutter-dashboard.appspot.com",
        "status": "completed",
        "conclusion": "success",
        "started_at": "2020-05-10T02:49:31Z",
        "completed_at": "2020-05-10T03:11:08Z",
        "output": {
            "title": null,
            "summary": null,
            "text": null,
            "annotations_count": 0,
            "annotations_url": "https://api.github.com/repos/flutter/$repository/check-runs/660053389/annotations"
        },
        "name": "test1",
        "check_suite": {
            "id": 668083231,
            "node_id": "MDEwOkNoZWNrU3VpdGU2NjgwODMyMzE=",
            "head_branch": "independent_agent",
            "head_sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
            "status": "queued",
            "conclusion": null,
            "url": "https://api.github.com/repos/flutter/$repository/check-suites/668083231",
            "before": "918f7fdf0337dac0fca0254e1b0e46e79f8e7a37",
            "after": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
            "pull_requests": [
                {
                    "url": "https://api.github.com/repos/flutter/$repository/pulls/1",
                    "id": 415645312,
                    "number": 1,
                    "head": {
                        "ref": "independent_agent",
                        "sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
                        "repo": {
                            "id": 212688278,
                            "url": "https://api.github.com/repos/flutter/$repository",
                            "name": "$repository"
                        }
                    },
                    "base": {
                        "ref": "main",
                        "sha": "96b953d99588ade4a2b5e9c920813f8f3841b7fb",
                        "repo": {
                            "id": 212688278,
                            "url": "https://api.github.com/repos/flutter/$repository",
                            "name": "$repository",
                            "owner": {
                              "avatar_url": "",
                              "html_url": "",
                              "login": "flutter",
                              "id": 54371434
                            }
                        }
                    }
                }
            ],
            "app": {
                "id": 64368,
                "slug": "godofredo-test",
                "node_id": "MDM6QXBwNjQzNjg=",
                "owner": {
                    "login": "abc",
                    "id": 54371434,
                    "node_id": "MDQ6VXNlcjU0MzcxNDM0",
                    "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
                    "gravatar_id": "",
                    "url": "https://api.github.com/users/abc",
                    "html_url": "https://github.com/abc",
                    "followers_url": "https://api.github.com/users/abc/followers",
                    "following_url": "https://api.github.com/users/abc/following{/other_user}",
                    "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
                    "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
                    "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
                    "organizations_url": "https://api.github.com/users/abc/orgs",
                    "repos_url": "https://api.github.com/users/abc/repos",
                    "events_url": "https://api.github.com/users/abc/events{/privacy}",
                    "received_events_url": "https://api.github.com/users/abc/received_events",
                    "type": "User",
                    "site_admin": false
                },
                "name": "godofredo-test",
                "description": "",
                "external_url": "https://flutter-dashboard.appspot.com",
                "html_url": "https://github.com/apps/godofredo-test",
                "created_at": "2020-05-10T00:32:46Z",
                "updated_at": "2020-05-10T00:32:46Z",
                "permissions": {
                    "checks": "write",
                    "contents": "read",
                    "metadata": "read"
                },
                "events": [
                    "check_run",
                    "check_suite",
                    "label"
                ]
            },
            "created_at": "2020-05-10T01:59:58Z",
            "updated_at": "2020-05-10T01:59:58Z"
        },
        "app": {
            "id": 64368,
            "slug": "godofredo-test",
            "node_id": "MDM6QXBwNjQzNjg=",
            "owner": {
                "login": "abc",
                "id": 54371434,
                "node_id": "MDQ6VXNlcjU0MzcxNDM0",
                "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
                "gravatar_id": "",
                "url": "https://api.github.com/users/abc",
                "html_url": "https://github.com/abc",
                "followers_url": "https://api.github.com/users/abc/followers",
                "following_url": "https://api.github.com/users/abc/following{/other_user}",
                "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
                "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
                "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
                "organizations_url": "https://api.github.com/users/abc/orgs",
                "repos_url": "https://api.github.com/users/abc/repos",
                "events_url": "https://api.github.com/users/abc/events{/privacy}",
                "received_events_url": "https://api.github.com/users/abc/received_events",
                "type": "User",
                "site_admin": false
            },
            "name": "godofredo-test",
            "description": "",
            "external_url": "https://flutter-dashboard.appspot.com",
            "html_url": "https://github.com/apps/godofredo-test",
            "created_at": "2020-05-10T00:32:46Z",
            "updated_at": "2020-05-10T00:32:46Z",
            "permissions": {
                "checks": "write",
                "contents": "read",
                "metadata": "read"
            },
            "events": [
                "check_run",
                "check_suite",
                "label"
            ]
        },
        "pull_requests": [
            {
                "url": "https://api.github.com/repos/flutter/$repository/pulls/1",
                "id": 415645312,
                "number": 1,
                "head": {
                    "ref": "independent_agent",
                    "sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
                    "repo": {
                        "id": 212688278,
                        "url": "https://api.github.com/repos/flutter/$repository",
                        "name": "$repository"
                    }
                },
                "base": {
                    "ref": "main",
                    "sha": "96b953d99588ade4a2b5e9c920813f8f3841b7fb",
                    "repo": {
                        "id": 212688278,
                        "url": "https://api.github.com/repos/flutter/$repository",
                        "name": "$repository",
                        "owner": {
                          "avatar_url": "",
                          "html_url": "",
                          "login": "flutter",
                          "id": 54371434
                        }
                    }
                }
            }
        ]
    },
    "repository": {
        "id": 212688278,
        "node_id": "MDEwOlJlcG9zaXRvcnkyMTI2ODgyNzg=",
        "name": "$repository",
        "full_name": "flutter/$repository",
        "private": false,
        "owner": {
            "login": "flutter",
            "id": 54371434,
            "node_id": "MDQ6VXNlcjU0MzcxNDM0",
            "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/abc",
            "html_url": "https://github.com/abc",
            "followers_url": "https://api.github.com/users/abc/followers",
            "following_url": "https://api.github.com/users/abc/following{/other_user}",
            "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
            "organizations_url": "https://api.github.com/users/abc/orgs",
            "repos_url": "https://api.github.com/users/abc/repos",
            "events_url": "https://api.github.com/users/abc/events{/privacy}",
            "received_events_url": "https://api.github.com/users/abc/received_events",
            "type": "User",
            "site_admin": false
        },
        "html_url": "https://github.com/flutter/$repository",
        "description": "Flutter's build coordinator and aggregator",
        "fork": true,
        "url": "https://api.github.com/repos/flutter/$repository",
        "forks_url": "https://api.github.com/repos/flutter/$repository/forks",
        "keys_url": "https://api.github.com/repos/flutter/$repository/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/flutter/$repository/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/flutter/$repository/teams",
        "hooks_url": "https://api.github.com/repos/flutter/$repository/hooks",
        "issue_events_url": "https://api.github.com/repos/flutter/$repository/issues/events{/number}",
        "events_url": "https://api.github.com/repos/flutter/$repository/events",
        "assignees_url": "https://api.github.com/repos/flutter/$repository/assignees{/user}",
        "branches_url": "https://api.github.com/repos/flutter/$repository/branches{/branch}",
        "tags_url": "https://api.github.com/repos/flutter/$repository/tags",
        "blobs_url": "https://api.github.com/repos/flutter/$repository/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/flutter/$repository/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/flutter/$repository/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/flutter/$repository/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/flutter/$repository/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/flutter/$repository/languages",
        "stargazers_url": "https://api.github.com/repos/flutter/$repository/stargazers",
        "contributors_url": "https://api.github.com/repos/flutter/$repository/contributors",
        "subscribers_url": "https://api.github.com/repos/flutter/$repository/subscribers",
        "subscription_url": "https://api.github.com/repos/flutter/$repository/subscription",
        "commits_url": "https://api.github.com/repos/flutter/$repository/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/flutter/$repository/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/flutter/$repository/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/flutter/$repository/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/flutter/$repository/contents/{+path}",
        "compare_url": "https://api.github.com/repos/flutter/$repository/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/flutter/$repository/merges",
        "archive_url": "https://api.github.com/repos/flutter/$repository/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/flutter/$repository/downloads",
        "issues_url": "https://api.github.com/repos/flutter/$repository/issues{/number}",
        "pulls_url": "https://api.github.com/repos/flutter/$repository/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/flutter/$repository/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/flutter/$repository/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/flutter/$repository/labels{/name}",
        "releases_url": "https://api.github.com/repos/flutter/$repository/releases{/id}",
        "deployments_url": "https://api.github.com/repos/flutter/$repository/deployments",
        "created_at": "2019-10-03T21:57:12Z",
        "updated_at": "2019-10-03T21:57:14Z",
        "pushed_at": "2020-05-09T23:42:23Z",
        "git_url": "git://github.com/flutter/$repository.git",
        "ssh_url": "git@github.com:flutter/$repository.git",
        "clone_url": "https://github.com/flutter/$repository.git",
        "svn_url": "https://github.com/flutter/$repository",
        "homepage": null,
        "size": 2941,
        "stargazers_count": 0,
        "watchers_count": 0,
        "language": null,
        "has_issues": false,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": false,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 1,
        "license": {
            "key": "",
            "name": "",
            "spdx_id": "",
            "url": "",
            "node_id": "MDc6TGljZW5zZTU="
        },
        "forks": 0,
        "open_issues": 1,
        "watchers": 0,
        "default_branch": "main"
    },
    "sender": {
        "login": "abc",
        "id": 54371434,
        "node_id": "MDQ6VXNlcjU0MzcxNDM0",
        "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/abc",
        "html_url": "https://github.com/abc",
        "followers_url": "https://api.github.com/users/abc/followers",
        "following_url": "https://api.github.com/users/abc/following{/other_user}",
        "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
        "organizations_url": "https://api.github.com/users/abc/orgs",
        "repos_url": "https://api.github.com/users/abc/repos",
        "events_url": "https://api.github.com/users/abc/events{/privacy}",
        "received_events_url": "https://api.github.com/users/abc/received_events",
        "type": "User",
        "site_admin": false
    },
    "installation": {
        "id": 8770981,
        "node_id": "MDIzOkludGVncmF0aW9uSW5zdGFsbGF0aW9uODc3MDk4MQ=="
    }
}
''';

const String checkRunWithEmptyPullRequests = '''
{
    "action": "rerequested",
    "check_run": {
        "id": 660053389,
        "node_id": "MDg6Q2hlY2tSdW42NjAwNTMzODk=",
        "head_sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
        "external_id": "",
        "url": "https://api.github.com/repos/flutter/cocoon/check-runs/660053389",
        "html_url": "https://github.com/flutter/cocoon/runs/660053389",
        "details_url": "https://flutter-dashboard.appspot.com",
        "status": "completed",
        "conclusion": "success",
        "started_at": "2020-05-10T02:49:31Z",
        "completed_at": "2020-05-10T03:11:08Z",
        "output": {
            "title": null,
            "summary": null,
            "text": null,
            "annotations_count": 0,
            "annotations_url": "https://api.github.com/repos/flutter/cocoon/check-runs/660053389/annotations"
        },
        "name": "test1",
        "check_suite": {
            "id": 668083231,
            "node_id": "MDEwOkNoZWNrU3VpdGU2NjgwODMyMzE=",
            "head_branch": "independent_agent",
            "head_sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
            "status": "queued",
            "conclusion": null,
            "url": "https://api.github.com/repos/flutter/cocoon/check-suites/668083231",
            "before": "918f7fdf0337dac0fca0254e1b0e46e79f8e7a37",
            "after": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
            "pull_requests": [
                {
                    "url": "https://api.github.com/repos/flutter/cocoon/pulls/1",
                    "id": 415645312,
                    "number": 1,
                    "head": {
                        "ref": "independent_agent",
                        "sha": "66d6bd9a3f79a36fe4f5178ccefbc781488a596c",
                        "repo": {
                            "id": 212688278,
                            "url": "https://api.github.com/repos/flutter/cocoon",
                            "name": "cocoon"
                        }
                    },
                    "base": {
                        "ref": "main",
                        "sha": "96b953d99588ade4a2b5e9c920813f8f3841b7fb",
                        "repo": {
                            "id": 212688278,
                            "url": "https://api.github.com/repos/flutter/cocoon",
                            "name": "cocoon",
                            "owner": {
                              "avatar_url": "",
                              "html_url": "",
                              "login": "flutter",
                              "id": 54371434
                            }
                        }
                    }
                }
            ],
            "app": {
                "id": 64368,
                "slug": "godofredo-test",
                "node_id": "MDM6QXBwNjQzNjg=",
                "owner": {
                    "login": "abc",
                    "id": 54371434,
                    "node_id": "MDQ6VXNlcjU0MzcxNDM0",
                    "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
                    "gravatar_id": "",
                    "url": "https://api.github.com/users/abc",
                    "html_url": "https://github.com/abc",
                    "followers_url": "https://api.github.com/users/abc/followers",
                    "following_url": "https://api.github.com/users/abc/following{/other_user}",
                    "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
                    "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
                    "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
                    "organizations_url": "https://api.github.com/users/abc/orgs",
                    "repos_url": "https://api.github.com/users/abc/repos",
                    "events_url": "https://api.github.com/users/abc/events{/privacy}",
                    "received_events_url": "https://api.github.com/users/abc/received_events",
                    "type": "User",
                    "site_admin": false
                },
                "name": "godofredo-test",
                "description": "",
                "external_url": "https://flutter-dashboard.appspot.com",
                "html_url": "https://github.com/apps/godofredo-test",
                "created_at": "2020-05-10T00:32:46Z",
                "updated_at": "2020-05-10T00:32:46Z",
                "permissions": {
                    "checks": "write",
                    "contents": "read",
                    "metadata": "read"
                },
                "events": [
                    "check_run",
                    "check_suite",
                    "label"
                ]
            },
            "created_at": "2020-05-10T01:59:58Z",
            "updated_at": "2020-05-10T01:59:58Z"
        },
        "app": {
            "id": 64368,
            "slug": "godofredo-test",
            "node_id": "MDM6QXBwNjQzNjg=",
            "owner": {
                "login": "abc",
                "id": 54371434,
                "node_id": "MDQ6VXNlcjU0MzcxNDM0",
                "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
                "gravatar_id": "",
                "url": "https://api.github.com/users/abc",
                "html_url": "https://github.com/abc",
                "followers_url": "https://api.github.com/users/abc/followers",
                "following_url": "https://api.github.com/users/abc/following{/other_user}",
                "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
                "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
                "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
                "organizations_url": "https://api.github.com/users/abc/orgs",
                "repos_url": "https://api.github.com/users/abc/repos",
                "events_url": "https://api.github.com/users/abc/events{/privacy}",
                "received_events_url": "https://api.github.com/users/abc/received_events",
                "type": "User",
                "site_admin": false
            },
            "name": "godofredo-test",
            "description": "",
            "external_url": "https://flutter-dashboard.appspot.com",
            "html_url": "https://github.com/apps/godofredo-test",
            "created_at": "2020-05-10T00:32:46Z",
            "updated_at": "2020-05-10T00:32:46Z",
            "permissions": {
                "checks": "write",
                "contents": "read",
                "metadata": "read"
            },
            "events": [
                "check_run",
                "check_suite",
                "label"
            ]
        },
        "pull_requests": []
    },
    "repository": {
        "id": 212688278,
        "node_id": "MDEwOlJlcG9zaXRvcnkyMTI2ODgyNzg=",
        "name": "cocoon",
        "full_name": "flutter/cocoon",
        "private": false,
        "owner": {
            "login": "abc",
            "id": 54371434,
            "node_id": "MDQ6VXNlcjU0MzcxNDM0",
            "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/abc",
            "html_url": "https://github.com/abc",
            "followers_url": "https://api.github.com/users/abc/followers",
            "following_url": "https://api.github.com/users/abc/following{/other_user}",
            "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
            "organizations_url": "https://api.github.com/users/abc/orgs",
            "repos_url": "https://api.github.com/users/abc/repos",
            "events_url": "https://api.github.com/users/abc/events{/privacy}",
            "received_events_url": "https://api.github.com/users/abc/received_events",
            "type": "User",
            "site_admin": false
        },
        "html_url": "https://github.com/flutter/cocoon",
        "description": "Flutter's build coordinator and aggregator",
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
        "created_at": "2019-10-03T21:57:12Z",
        "updated_at": "2019-10-03T21:57:14Z",
        "pushed_at": "2020-05-09T23:42:23Z",
        "git_url": "git://github.com/flutter/cocoon.git",
        "ssh_url": "git@github.com:flutter/cocoon.git",
        "clone_url": "https://github.com/flutter/cocoon.git",
        "svn_url": "https://github.com/flutter/cocoon",
        "homepage": null,
        "size": 2941,
        "stargazers_count": 0,
        "watchers_count": 0,
        "language": null,
        "has_issues": false,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": false,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 1,
        "license": {
            "key": "",
            "name": "",
            "spdx_id": "",
            "url": "",
            "node_id": "MDc6TGljZW5zZTU="
        },
        "forks": 0,
        "open_issues": 1,
        "watchers": 0,
        "default_branch": "main"
    },
    "sender": {
        "login": "abc",
        "id": 54371434,
        "node_id": "MDQ6VXNlcjU0MzcxNDM0",
        "avatar_url": "https://avatars3.githubusercontent.com/u/54371434?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/abc",
        "html_url": "https://github.com/abc",
        "followers_url": "https://api.github.com/users/abc/followers",
        "following_url": "https://api.github.com/users/abc/following{/other_user}",
        "gists_url": "https://api.github.com/users/abc/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/abc/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/abc/subscriptions",
        "organizations_url": "https://api.github.com/users/abc/orgs",
        "repos_url": "https://api.github.com/users/abc/repos",
        "events_url": "https://api.github.com/users/abc/events{/privacy}",
        "received_events_url": "https://api.github.com/users/abc/received_events",
        "type": "User",
        "site_admin": false
    },
    "installation": {
        "id": 8770981,
        "node_id": "MDIzOkludGVncmF0aW9uSW5zdGFsbGF0aW9uODc3MDk4MQ=="
    }
}
''';
