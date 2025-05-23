// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String workflowJobTemplate({
  int id = 40533761873,
  String action = 'completed',
  String name = 'generate-engine-content-hash',
  String workflowName = 'Generate a content aware hash for the Flutter Engine',
  String workflowStatus = 'completed',
  String workflowConclusion = 'success',
  String headBranch =
      'gh-readonly-queue/master/pr-12345-556243e34d75788370815810e1547d2f81d2772a', // sha1(codefu was here)
  String headSha =
      '27bfdee25949bc48044c4e16678f3449dd213b6e', // sha1(matanl was here)
  String senderLogin = 'fluttergithubbot',
  String repositoryFullName = 'flutter/flutter',
}) => '''{
   "action" : "$action",
   "enterprise" : {
      "avatar_url" : "https://avatars.githubusercontent.com/b/1732?v=4",
      "created_at" : "2019-12-19T00:30:52Z",
      "description" : "",
      "html_url" : "https://github.com/enterprises/alphabet",
      "id" : 1732,
      "name" : "Alphabet",
      "node_id" : "MDEwOkVudGVycHJpc2UxNzMy",
      "slug" : "alphabet",
      "updated_at" : "2024-07-18T11:54:37Z",
      "website_url" : "https://abc.xyz/"
   },
   "installation" : {
      "id" : 10381585,
      "node_id" : "MDIzOkludGVncmF0aW9uSW5zdGFsbGF0aW9uMTAzODE1ODU="
   },
   "organization" : {
      "avatar_url" : "https://avatars.githubusercontent.com/u/14101776?v=4",
      "description" : "Flutter is Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, desktop, and embedded devices from a single codebase.",
      "events_url" : "https://api.github.com/orgs/flutter/events",
      "hooks_url" : "https://api.github.com/orgs/flutter/hooks",
      "id" : 14101776,
      "issues_url" : "https://api.github.com/orgs/flutter/issues",
      "login" : "flutter",
      "members_url" : "https://api.github.com/orgs/flutter/members{/member}",
      "node_id" : "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
      "public_members_url" : "https://api.github.com/orgs/flutter/public_members{/member}",
      "repos_url" : "https://api.github.com/orgs/flutter/repos",
      "url" : "https://api.github.com/orgs/flutter"
   },
   "repository" : {
      "allow_forking" : true,
      "archive_url" : "https://api.github.com/repos/$repositoryFullName/{archive_format}{/ref}",
      "archived" : false,
      "assignees_url" : "https://api.github.com/repos/$repositoryFullName/assignees{/user}",
      "blobs_url" : "https://api.github.com/repos/$repositoryFullName/git/blobs{/sha}",
      "branches_url" : "https://api.github.com/repos/$repositoryFullName/branches{/branch}",
      "clone_url" : "https://github.com/$repositoryFullName.git",
      "collaborators_url" : "https://api.github.com/repos/$repositoryFullName/collaborators{/collaborator}",
      "comments_url" : "https://api.github.com/repos/$repositoryFullName/comments{/number}",
      "commits_url" : "https://api.github.com/repos/$repositoryFullName/commits{/sha}",
      "compare_url" : "https://api.github.com/repos/$repositoryFullName/compare/{base}...{head}",
      "contents_url" : "https://api.github.com/repos/$repositoryFullName/contents/{+path}",
      "contributors_url" : "https://api.github.com/repos/$repositoryFullName/contributors",
      "created_at" : "2015-03-06T22:54:58Z",
      "custom_properties" : {
         "requires_action_scanning" : "true",
         "requires_two_party_review" : "false"
      },
      "default_branch" : "master",
      "deployments_url" : "https://api.github.com/repos/$repositoryFullName/deployments",
      "description" : "Flutter makes it easy and fast to build beautiful apps for mobile and beyond",
      "disabled" : false,
      "downloads_url" : "https://api.github.com/repos/$repositoryFullName/downloads",
      "events_url" : "https://api.github.com/repos/$repositoryFullName/events",
      "fork" : false,
      "forks" : 28354,
      "forks_count" : 28354,
      "forks_url" : "https://api.github.com/repos/$repositoryFullName/forks",
      "full_name" : "$repositoryFullName",
      "git_commits_url" : "https://api.github.com/repos/$repositoryFullName/git/commits{/sha}",
      "git_refs_url" : "https://api.github.com/repos/$repositoryFullName/git/refs{/sha}",
      "git_tags_url" : "https://api.github.com/repos/$repositoryFullName/git/tags{/sha}",
      "git_url" : "git://github.com/$repositoryFullName.git",
      "has_discussions" : false,
      "has_downloads" : true,
      "has_issues" : true,
      "has_pages" : false,
      "has_projects" : true,
      "has_wiki" : true,
      "homepage" : "https://flutter.dev",
      "hooks_url" : "https://api.github.com/repos/$repositoryFullName/hooks",
      "html_url" : "https://github.com/$repositoryFullName",
      "id" : 31792824,
      "is_template" : false,
      "issue_comment_url" : "https://api.github.com/repos/$repositoryFullName/issues/comments{/number}",
      "issue_events_url" : "https://api.github.com/repos/$repositoryFullName/issues/events{/number}",
      "issues_url" : "https://api.github.com/repos/$repositoryFullName/issues{/number}",
      "keys_url" : "https://api.github.com/repos/$repositoryFullName/keys{/key_id}",
      "labels_url" : "https://api.github.com/repos/$repositoryFullName/labels{/name}",
      "language" : "Dart",
      "languages_url" : "https://api.github.com/repos/$repositoryFullName/languages",
      "license" : {
         "key" : "bsd-3-clause",
         "name" : "BSD 3-Clause \\"New\\" or \\"Revised\\" License",
         "node_id" : "MDc6TGljZW5zZTU=",
         "spdx_id" : "BSD-3-Clause",
         "url" : "https://api.github.com/licenses/bsd-3-clause"
      },
      "merges_url" : "https://api.github.com/repos/$repositoryFullName/merges",
      "milestones_url" : "https://api.github.com/repos/$repositoryFullName/milestones{/number}",
      "mirror_url" : null,
      "name" : "flutter",
      "node_id" : "MDEwOlJlcG9zaXRvcnkzMTc5MjgyNA==",
      "notifications_url" : "https://api.github.com/repos/$repositoryFullName/notifications{?since,all,participating}",
      "open_issues" : 13108,
      "open_issues_count" : 13108,
      "owner" : {
         "avatar_url" : "https://avatars.githubusercontent.com/u/14101776?v=4",
         "events_url" : "https://api.github.com/users/flutter/events{/privacy}",
         "followers_url" : "https://api.github.com/users/flutter/followers",
         "following_url" : "https://api.github.com/users/flutter/following{/other_user}",
         "gists_url" : "https://api.github.com/users/flutter/gists{/gist_id}",
         "gravatar_id" : "",
         "html_url" : "https://github.com/flutter",
         "id" : 14101776,
         "login" : "flutter",
         "node_id" : "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
         "organizations_url" : "https://api.github.com/users/flutter/orgs",
         "received_events_url" : "https://api.github.com/users/flutter/received_events",
         "repos_url" : "https://api.github.com/users/flutter/repos",
         "site_admin" : false,
         "starred_url" : "https://api.github.com/users/flutter/starred{/owner}{/repo}",
         "subscriptions_url" : "https://api.github.com/users/flutter/subscriptions",
         "type" : "Organization",
         "url" : "https://api.github.com/users/flutter",
         "user_view_type" : "public"
      },
      "private" : false,
      "pulls_url" : "https://api.github.com/repos/$repositoryFullName/pulls{/number}",
      "pushed_at" : "2025-04-14T19:38:19Z",
      "releases_url" : "https://api.github.com/repos/$repositoryFullName/releases{/id}",
      "size" : 307431,
      "ssh_url" : "git@github.com:$repositoryFullName.git",
      "stargazers_count" : 169751,
      "stargazers_url" : "https://api.github.com/repos/$repositoryFullName/stargazers",
      "statuses_url" : "https://api.github.com/repos/$repositoryFullName/statuses/{sha}",
      "subscribers_url" : "https://api.github.com/repos/$repositoryFullName/subscribers",
      "subscription_url" : "https://api.github.com/repos/$repositoryFullName/subscription",
      "svn_url" : "https://github.com/$repositoryFullName",
      "tags_url" : "https://api.github.com/repos/$repositoryFullName/tags",
      "teams_url" : "https://api.github.com/repos/$repositoryFullName/teams",
      "topics" : [
         "android",
         "app-framework",
         "cross-platform",
         "dart",
         "dart-platform",
         "desktop",
         "flutter",
         "flutter-package",
         "fuchsia",
         "ios",
         "linux-desktop",
         "macos",
         "material-design",
         "mobile",
         "mobile-development",
         "skia",
         "web",
         "web-framework",
         "windows"
      ],
      "trees_url" : "https://api.github.com/repos/$repositoryFullName/git/trees{/sha}",
      "updated_at" : "2025-04-14T19:29:51Z",
      "url" : "https://api.github.com/repos/$repositoryFullName",
      "visibility" : "public",
      "watchers" : 169751,
      "watchers_count" : 169751,
      "web_commit_signoff_required" : false
   },
   "sender" : {
      "avatar_url" : "https://avatars.githubusercontent.com/u/52682268?v=4",
      "events_url" : "https://api.github.com/users/fluttergithubbot/events{/privacy}",
      "followers_url" : "https://api.github.com/users/fluttergithubbot/followers",
      "following_url" : "https://api.github.com/users/fluttergithubbot/following{/other_user}",
      "gists_url" : "https://api.github.com/users/fluttergithubbot/gists{/gist_id}",
      "gravatar_id" : "",
      "html_url" : "https://github.com/fluttergithubbot",
      "id" : 52682268,
      "login" : "$senderLogin",
      "node_id" : "MDQ6VXNlcjUyNjgyMjY4",
      "organizations_url" : "https://api.github.com/users/fluttergithubbot/orgs",
      "received_events_url" : "https://api.github.com/users/fluttergithubbot/received_events",
      "repos_url" : "https://api.github.com/users/fluttergithubbot/repos",
      "site_admin" : false,
      "starred_url" : "https://api.github.com/users/fluttergithubbot/starred{/owner}{/repo}",
      "subscriptions_url" : "https://api.github.com/users/fluttergithubbot/subscriptions",
      "type" : "User",
      "url" : "https://api.github.com/users/fluttergithubbot",
      "user_view_type" : "public"
   },
   "workflow_job" : {
      "check_run_url" : "https://api.github.com/repos/flutter/flutter/check-runs/$id",
      "completed_at" : "2025-04-14T19:39:41Z",
      "conclusion" : "$workflowConclusion",
      "created_at" : "2025-04-14T19:39:01Z",
      "head_branch" : "$headBranch",
      "head_sha" : "$headSha",
      "html_url" : "https://github.com/flutter/flutter/actions/runs/14454255411/job/$id",
      "id" : $id,
      "labels" : [
         "ubuntu-latest"
      ],
      "name" : "$name",
      "node_id" : "CR_kwDOAeUeuM8AAAAJcAAfUQ",
      "run_attempt" : 1,
      "run_id" : 14454255411,
      "run_url" : "https://api.github.com/repos/flutter/flutter/actions/runs/14454255411",
      "runner_group_id" : 0,
      "runner_group_name" : "",
      "runner_id" : 1000899989,
      "runner_name" : "GitHub Actions",
      "started_at" : "2025-04-14T19:39:05Z",
      "status" : "$workflowStatus",
      "steps" : [
         {
            "completed_at" : "2025-04-14T19:39:06Z",
            "conclusion" : "success",
            "name" : "Set up job",
            "number" : 1,
            "started_at" : "2025-04-14T19:39:05Z",
            "status" : "completed"
         },
         {
            "completed_at" : "2025-04-14T19:39:13Z",
            "conclusion" : "success",
            "name" : "Checkout code",
            "number" : 2,
            "started_at" : "2025-04-14T19:39:06Z",
            "status" : "completed"
         },
         {
            "completed_at" : "2025-04-14T19:39:39Z",
            "conclusion" : "success",
            "name" : "Fetch base commit and origin/master",
            "number" : 3,
            "started_at" : "2025-04-14T19:39:13Z",
            "status" : "completed"
         },
         {
            "completed_at" : "2025-04-14T19:39:39Z",
            "conclusion" : "success",
            "name" : "Generate Hash",
            "number" : 4,
            "started_at" : "2025-04-14T19:39:39Z",
            "status" : "completed"
         },
         {
            "completed_at" : "2025-04-14T19:39:39Z",
            "conclusion" : "success",
            "name" : "Post Checkout code",
            "number" : 8,
            "started_at" : "2025-04-14T19:39:39Z",
            "status" : "completed"
         },
         {
            "completed_at" : "2025-04-14T19:39:39Z",
            "conclusion" : "success",
            "name" : "Complete job",
            "number" : 9,
            "started_at" : "2025-04-14T19:39:39Z",
            "status" : "completed"
         }
      ],
      "url" : "https://api.github.com/repos/flutter/flutter/actions/jobs/$id",
      "workflow_name" : "$workflowName"
   }
}''';
