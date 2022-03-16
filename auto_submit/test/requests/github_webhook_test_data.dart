// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String generateWebhookEvent(
    {String? labelName, String? autosubmitLabel, String? repoName, String? login, String? authorAssociation}) {
  return '''{
      "action": "open",
      "number": 1598,
      "pull_request": {
          "id": 1,
          "number": 1347,
          "state": "open",
          "title": "Amazing new feature",
          "user": {
            "login": "${login ?? "octocat"}",
            "id": 1
          },
          "body": "Please pull these awesome changes in!",
          "labels": [
            {
              "id": 487496476,
              "name": "${labelName ?? "cla: yes"}"
            },
            {
              "id": 284437560,
              "name": "${autosubmitLabel ?? "autosubmit"}"
            }
          ],
          "created_at": "2011-01-26T19:01:12Z",
          "head": {
            "label": "octocat:new-topic",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
            "repo": {
              "id": 1296269,
              "name": "Hello-World",
              "full_name": "octocat/Hello-World",
              "owner": {
                "login": "octocat",
                "id": 1,
                "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                "html_url": "https://github.com/octocat"
              }
            }
          },
          "base": {
            "label": "octocat:master",
            "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
            "repo": {
              "id": 1296269,
              "name": "${repoName ?? "flutter"}",
              "full_name": "${login ?? "flutter"}/${repoName ?? "flutter"}",
              "owner": {
                "login": "${login ?? "flutter"}",
                "id": 1,
                "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                "html_url": "https://github.com/octocat"
              }
            } 
          },
          "author_association": "${authorAssociation ?? "OWNER"}",
          "mergeable": true,
          "mergeable_state": "clean"
      }
    }''';
}

final String reviewsMock = '''[
  {
    "id": 80,
    "user": {
      "login": "octocat2",
      "id": 1
    },
    "body": "Here is the body for the review.",
    "state": "APPROVED",
    "author_association": "OWNER"
  }
]''';

String unApprovedReviewsMock = '''[
  {
    "id": 81,
    "user": {
      "login": "octocat",
      "id": 1
    },
    "body": "Here is the body for the review.",
    "state": "CHANGES_REQUESTED",
    "author_association": "OWNER"
  }
]''';

final String checkRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 1,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "completed",
      "conclusion": "success",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "mighty_readme",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

final String failedCheckRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 2,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "completed",
      "conclusion": "failure",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "failed_checkrun",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

String inProgressCheckRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 3,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "conclusion": "neutral",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "inprogress_checkrun",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

final String emptyCheckRunsMock = '''{"check_runs": [{}]}''';

// repositoryStatusesMock is from the official Github API: https://developer.github.com/v3/repos/statuses/#list-statuses-for-a-specific-ref
final String repositoryStatusesMock = '''{
  "state": "success",
  "statuses": [
    {
      "state": "success",
      "context": "luci-flutter"
    },
    {
      "state": "success",
      "context": "luci-flutter/flutter"
    }
  ]
}''';

String failedAuthorsStatusesMock = '''{
  "state": "failure",
  "statuses": [
    {
      "state": "failure",
      "context": "luci-flutter",
      "target_url": "https://ci.example.com/1000/output"
    },
    {
      "state": "failure",
      "context": "luci-engine",
      "target_url": "https://ci.example.com/2000/output"
    }
  ]
}''';

String failedNonAuthorsStatusesMock = '''{
  "state": "failure",
  "statuses": [
    {
      "state": "failure",
      "context": "luci-flutter",
      "target_url": "https://ci.example.com/1000/output"
    },
    {
      "state": "failure",
      "context": "flutter-cocoon",
      "target_url": "https://ci.example.com/2000/output"
    }
  ]
}''';

final String emptyStatusesMock = '''{"statuses": [{}]}''';

// commitMock is from the official Github API: https://docs.github.com/en/rest/reference/commits#get-a-commit
final String commitMock = '''{
  "sha": "HEAD~",
  "commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "message": "Fix all the bugs"
  }
}''';

// compareTowCOmmitsMock is from the official Github API: https://docs.github.com/en/rest/reference/commits#compare-two-commits
final String compareTowCommitsMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
  "status": "behind",
  "ahead_by": 1,
  "behind_by": 2,
  "total_commits": 1,
  "files": [
    {
      "sha": "bbcd538c8e72b8c175046e27cc8f907076331401",
      "filename": "file1.txt",
      "status": "added",
      "changes": 124
    }
  ]
}''';

final String compareToTCommitsMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
  "status": "behind",
  "ahead_by": 1,
  "behind_by": 2,
  "total_commits": 1,
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
  "id": 10,
  "position": 1,
  "commit_id": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "user": {
    "login": "octocat",
    "id": 1
  },
  "body": "Great stuff!"
}''';
