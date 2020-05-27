import 'dart:convert';
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:github/github.dart' show PullRequest;
import 'package:test/test.dart';

void main() {
  group('CheckSuiteEvent', () {
    test('deserialize', () async {
      final CheckSuiteEvent checkSuiteEvent = CheckSuiteEvent.fromJson(
          json.decode(checkSuiteString) as Map<String, dynamic>);
      // Top level properties.
      expect(checkSuiteEvent.action, 'requested');
      expect(checkSuiteEvent.checkSuite, isA<CheckSuite>());
      final CheckSuite suite = checkSuiteEvent.checkSuite;
      // CheckSuite properties.
      expect(suite.headSha, equals('dabc07b74c555c9952f7b63e139f2bb83b75250f'));
      expect(suite.headBranch, equals('update_licenses'));
      // PullRequestProperties.
      expect(suite.pullRequests, hasLength(1));
      final PullRequest pullRequest = suite.pullRequests[0];
      expect(pullRequest.base.ref, equals('master'));
      expect(pullRequest.base.sha,
          equals('cc430b2e8d6448dfbacf5bcbbd6160cd1fe9dc0b'));
      expect(pullRequest.base.repo.name, equals('cocoon'));
      expect(pullRequest.head.ref, equals('update_licenses'));
      expect(pullRequest.head.sha,
          equals('5763f4c2b3b5e529f4b35c655761a7e818eced2e'));
      expect(pullRequest.head.repo.name, equals('cocoon'));
    });
  });
}

const String checkSuiteString = '''\
{
    "action": "requested",
    "check_suite": {
        "id": 694267587,
        "node_id": "MDEwOkNoZWNrU3VpdGU2OTQyNjc1ODc=",
        "head_branch": "update_licenses",
        "head_sha": "dabc07b74c555c9952f7b63e139f2bb83b75250f",
        "status": "queued",
        "conclusion": null,
        "url": "https://api.github.com/repos/abc/cocoon/check-suites/694267587",
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
                        "url": "https://api.github.com/repos/abc/cocoon",
                        "name": "cocoon"
                    }
                },
                "base": {
                    "ref": "master",
                    "sha": "cc430b2e8d6448dfbacf5bcbbd6160cd1fe9dc0b",
                    "repo": {
                        "id": 63260554,
                        "url": "https://api.github.com/repos/flutter/cocoon",
                        "name": "cocoon"
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
        "check_runs_url": "https://api.github.com/repos/abc/cocoon/check-suites/694267587/check-runs",
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
        "full_name": "abc/cocoon",
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
        "html_url": "https://github.com/abc/cocoon",
        "description": "Flutter's build coordinator and aggregator",
        "fork": true,
        "url": "https://api.github.com/repos/abc/cocoon",
        "forks_url": "https://api.github.com/repos/abc/cocoon/forks",
        "keys_url": "https://api.github.com/repos/abc/cocoon/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/abc/cocoon/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/abc/cocoon/teams",
        "hooks_url": "https://api.github.com/repos/abc/cocoon/hooks",
        "issue_events_url": "https://api.github.com/repos/abc/cocoon/issues/events{/number}",
        "events_url": "https://api.github.com/repos/abc/cocoon/events",
        "assignees_url": "https://api.github.com/repos/abc/cocoon/assignees{/user}",
        "branches_url": "https://api.github.com/repos/abc/cocoon/branches{/branch}",
        "tags_url": "https://api.github.com/repos/abc/cocoon/tags",
        "blobs_url": "https://api.github.com/repos/abc/cocoon/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/abc/cocoon/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/abc/cocoon/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/abc/cocoon/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/abc/cocoon/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/abc/cocoon/languages",
        "stargazers_url": "https://api.github.com/repos/abc/cocoon/stargazers",
        "contributors_url": "https://api.github.com/repos/abc/cocoon/contributors",
        "subscribers_url": "https://api.github.com/repos/abc/cocoon/subscribers",
        "subscription_url": "https://api.github.com/repos/abc/cocoon/subscription",
        "commits_url": "https://api.github.com/repos/abc/cocoon/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/abc/cocoon/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/abc/cocoon/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/abc/cocoon/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/abc/cocoon/contents/{+path}",
        "compare_url": "https://api.github.com/repos/abc/cocoon/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/abc/cocoon/merges",
        "archive_url": "https://api.github.com/repos/abc/cocoon/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/abc/cocoon/downloads",
        "issues_url": "https://api.github.com/repos/abc/cocoon/issues{/number}",
        "pulls_url": "https://api.github.com/repos/abc/cocoon/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/abc/cocoon/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/abc/cocoon/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/abc/cocoon/labels{/name}",
        "releases_url": "https://api.github.com/repos/abc/cocoon/releases{/id}",
        "deployments_url": "https://api.github.com/repos/abc/cocoon/deployments",
        "created_at": "2019-10-03T21:57:12Z",
        "updated_at": "2019-10-03T21:57:14Z",
        "pushed_at": "2020-05-18T23:04:24Z",
        "git_url": "git://github.com/abc/cocoon.git",
        "ssh_url": "git@github.com:abc/cocoon.git",
        "clone_url": "https://github.com/abc/cocoon.git",
        "svn_url": "https://github.com/abc/cocoon",
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
        "default_branch": "master"
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
