// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/config.dart';
import 'package:github/github.dart';

String generateWebhookEvent({
  String? labelName,
  String? autosubmitLabel,
  String? repoName,
  String? login,
  String? authorAssociation,
}) {
  return '''{
      "action": "open",
      "number": 1598,
      "sender": {
        "login": "matanlurey",
        "id": 168174,
        "node_id": "MDQ6VXNlcjE2ODE3NA=="
      },
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

PullRequest generatePullRequest({
  String labelName = 'cla: yes',
  String? autosubmitLabel = Config.kAutosubmitLabel,
  String repoName = 'flutter',
  String login = 'flutter',
  String authorAssociation = 'OWNER',
  String author = 'octocat',
  int prNumber = 1347,
  String state = 'open',
  String? body = 'Please pull these awesome changes in!',
  String title = 'Amazing new feature',
  bool? mergeable = true,
  String baseRef = 'main',
}) {
  return PullRequest.fromJson(
    json.decode('''{
      "id": 1,
      "number": $prNumber,
      "state": "$state",
      "title": ${jsonEncode(title)},
      "user": {
        "login": "$author",
        "id": 1
      },
      "body": "$body",
      "labels": [
        {
          "id": 487496476,
          "name": "$labelName"
        },
        {
          "id": 284437560,
          "name": "$autosubmitLabel"
        }
      ],
      "created_at": "2011-01-26T19:01:12Z",
      "closed_at": "2011-01-26T19:10:12Z",
      "head": {
        "label": "octocat:new-topic",
        "ref": "new-topic",
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
        "label": "octocat:main",
        "ref": "$baseRef",
        "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "repo": {
          "id": 1296269,
          "name": "$repoName",
          "full_name": "$login/$repoName",
          "owner": {
            "login": "$login",
            "id": 1,
            "avatar_url": "https://github.com/images/error/octocat_happy.gif",
            "html_url": "https://github.com/octocat"
          }
        }
      },
      "author_association": "$authorAssociation",
      "mergeable": $mergeable,
      "mergeable_state": "clean"
  }''') as Map<String, dynamic>,
  );
}

const String reviewsMock = '''[
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

const String unApprovedReviewsMock = '''[
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

const String checkRunsMock = '''{
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

const String failedCheckRunsMock = '''{
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

const String neutralCheckRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 2,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "completed",
      "conclusion": "neutral",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "neutral_checkrun",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

const String inProgressCheckRunsMock = '''{
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

const String skippedCheckRunsMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 6,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "conclusion": "skipped",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "inprogress_checkrun",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

const String multipleCheckRunsMock = '''{
  "total_count": 3,
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
    },
    {
      "id": 2,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "completed",
      "conclusion": "neutral",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "neutral_checkrun",
      "check_suite": {
        "id": 5
      }
    },
    {
      "id": 6,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "conclusion": "skipped",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "inprogress_checkrun",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

const String multipleCheckRunsWithFailureMock = '''{
  "total_count": 3,
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
    },
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
    },
    {
      "id": 6,
      "head_sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "conclusion": "skipped",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "inprogress_checkrun",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

const String inprogressAndNotFailedCheckRunMock = '''{
  "total_count": 1,
  "check_runs": [
    {
      "id": 6,
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

const String emptyCheckRunsMock = '''{"check_runs": [{}]}''';

// repositoryStatusesMock is from the official Github API: https://developer.github.com/v3/repos/statuses/#list-statuses-for-a-specific-ref
// state can be error, failure, pending, success
const String repositoryStatusesMock = '''{
  "state": "success",
  "statuses": [
    {
      "state": "success",
      "context": "tree-status"
    },
    {
      "state": "success",
      "context": "tree-status/flutter"
    }
  ]
}''';

const String repositoryStatusesWithGoldMock = '''{
  "state": "success",
  "statuses": [
    {
      "state": "success",
      "context": "tree-status"
    },
    {
      "state": "PENDING",
      "context": "flutter-gold"
    }
  ]
}''';

const String repositoryStatusesWithFailedGoldMock = '''{
  "state": "success",
  "statuses": [
    {
      "state": "success",
      "context": "tree-status"
    },
    {
      "state": "failure",
      "context": "flutter-gold",
      "targetUrl": "https://ci.example.com/1000/output"
    }
  ]
}''';

const String repositoryStatusesNonLuciFlutterMock = '''{
  "state": "success",
  "statuses": [
    {
      "state": "success",
      "context": "infra"
    },
    {
      "state": "success",
      "context": "config"
    }
  ]
}''';

const String failedAuthorsStatusesMock = '''{
  "state": "failure",
  "statuses": [
    {
      "state": "failure",
      "context": "tree-status",
      "targetUrl": "https://ci.example.com/1000/output"
    },
    {
      "state": "failure",
      "context": "tree-status",
      "targetUrl": "https://ci.example.com/2000/output"
    }
  ]
}''';

const String failedNonAuthorsStatusesMock = '''{
  "state": "failure",
  "statuses": [
    {
      "state": "failure",
      "context": "flutter-engine",
      "targetUrl": "https://ci.example.com/1000/output"
    },
    {
      "state": "failure",
      "context": "flutter-infra",
      "targetUrl": "https://ci.example.com/2000/output"
    }
  ]
}''';

const String emptyStatusesMock = '''{"statuses": [{}]}''';

// commitMock is from the official Github API: https://docs.github.com/en/rest/reference/commits#get-a-commit
const String commitMock = '''{
  "sha": "HEAD~",
  "commit": {
    "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "message": "Fix all the bugs"
  }
}''';

const String shouldRebaseMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
  "status": "behind",
  "ahead_by": 1,
  "behind_by": 11,
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

// compareTwoCommitsMock is from the official Github API: https://docs.github.com/en/rest/reference/commits#compare-two-commits
const String compareTwoCommitsMock = '''{
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

const String compareToTCommitsMock = '''{
  "url": "https://api.github.com/repos/octocat/Hello-World/compare/master...topic",
  "status": "behind",
  "ahead_by": 1,
  "behind_by": 2,
  "total_commits": 1,
  "files": []
}''';

// successMergeMock is from the offcial github API: https://docs.github.com/en/rest/reference/pulls#merge-a-pull-request.
const String successMergeMock = '''
{
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "merged": true
}''';

// createCommentMock is from the offcial github API: https://docs.github.com/en/rest/reference/pulls#create-a-review-comment-for-a-pull-request.
const String createCommentMock = '''
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

const String pullRequestMergeMock = '''
{
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "merged": true
}''';
