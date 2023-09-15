// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String queryResultRepositoryOwnerJson = '''
{
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "Revert Trailing comma analysis",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[

                  ]
                }
              }
            }
          ]
        },
        "reviews": {

        }
      }
    }
  }
''';

const String queryResultRepositoryContributorJson = '''
{
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "Revert Trailing comma analysis",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[

                  ]
                }
              }
            }
          ]
        },
        "reviews": {

        }
      }
    }
  }
''';

const String revertPullRequestJson = '''
  {
  "url": "https://api.github.com/repos/flutter/cocoon/pulls/2047",
  "id": 1023297178,
  "node_id": "PR_kwDOA8VHis48_kaa",
  "number": 2047,
  "state": "open",
  "locked": false,
  "title": "Revert Trailing comma analysis",
  "user": {
    "login": "ricardoamador",
    "id": 32242716
  },
  "body": "Reverts flutter/cocoon#2024",
  "created_at": "2022-08-10T23:27:49Z",
  "updated_at": "2022-08-12T16:57:35Z",
  "labels": [],
  "head": {
    "label": "flutter:revert-2024-trailing_comma_analysis",
    "ref": "revert-2024-trailing_comma_analysis",
    "sha": "8c8d14b5eda928e25b43fc76da94f78ab11d99d7",
    "user": {
      "login": "flutter",
      "id": 14101776,
      "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2"
    },
    "repo": {
      "id": 63260554,
      "node_id": "MDEwOlJlcG9zaXRvcnk2MzI2MDU1NA==",
      "name": "cocoon",
      "full_name": "flutter/cocoon",
      "private": false,
      "owner": {
        "login": "flutter",
        "id": 14101776,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
        "avatar_url": "https://avatars.githubusercontent.com/u/14101776?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "type": "Organization",
        "site_admin": false
      },
      "default_branch": "main"
    }
  },
  "base": {
    "label": "flutter:main",
    "ref": "main",
    "sha": "04a33c0719e114a8afffb2e31e29c38ac6c9f0a7",
    "user": {
      "login": "flutter",
      "id": 14101776,
      "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2"
    },
    "repo": {
      "id": 63260554,
      "node_id": "MDEwOlJlcG9zaXRvcnk2MzI2MDU1NA==",
      "name": "cocoon",
      "full_name": "flutter/cocoon",
      "private": false,
      "owner": {
        "login": "flutter",
        "id": 14101776,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
        "avatar_url": "https://avatars.githubusercontent.com/u/14101776?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "type": "Organization",
        "site_admin": false
      },
      "default_branch": "main"
    }
  },
  "author": "ricardoamador",
  "auto_merge": null,
  "active_lock_reason": null,
  "merged": false,
  "mergeable": true,
  "rebaseable": true,
  "mergeable_state": "blocked",
  "merged_by": null,
  "comments": 1,
  "review_comments": 0,
  "maintainer_can_modify": false,
  "commits": 1,
  "additions": 325,
  "deletions": 472,
  "changed_files": 25
}
''';

const String revertPullRequestFilesJson = '''
  [
    {
      "filename": "dashboard/analysis_options.yaml",
      "additions": 0,
      "deletions": 1,
      "changes": 1
    },
    {
      "filename": "dashboard/lib/build_dashboard_page.dart",
      "additions": 35,
      "deletions": 45,
      "changes": 80
    },
    {
      "filename": "dashboard/lib/index_page.dart",
      "additions": 10,
      "deletions": 12,
      "changes": 22
    },
    {
      "filename": "dashboard/lib/logic/brooks.dart",
      "additions": 18,
      "deletions": 20,
      "changes": 38
    },
    {
      "filename": "dashboard/lib/logic/links.dart",
      "additions": 15,
      "deletions": 18,
      "changes": 33
    },
    {
      "filename": "dashboard/lib/logic/task_grid_filter.dart",
      "additions": 4,
      "deletions": 12,
      "changes": 16
    },
    {
      "filename": "dashboard/lib/main.dart",
      "additions": 6,
      "deletions": 7,
      "changes": 13
    },
    {
      "filename": "dashboard/lib/service/appengine_cocoon.dart",
      "additions": 16,
      "deletions": 23,
      "changes": 39
    },
    {
      "filename": "dashboard/lib/service/dev_cocoon.dart",
      "additions": 8,
      "deletions": 15,
      "changes": 23
    },
    {
      "filename": "dashboard/lib/widgets/lattice.dart",
      "additions": 18,
      "deletions": 22,
      "changes": 40
    },
    {
      "filename": "dashboard/lib/widgets/luci_task_attempt_summary.dart",
      "additions": 4,
      "deletions": 5,
      "changes": 9
    },
    {
      "filename": "dashboard/lib/widgets/sign_in_button.dart",
      "additions": 10,
      "deletions": 12,
      "changes": 22
    },
    {
      "filename": "dashboard/lib/widgets/task_grid.dart",
      "additions": 13,
      "deletions": 17,
      "changes": 30
    },
    {
      "filename": "dashboard/lib/widgets/task_overlay.dart",
      "additions": 2,
      "deletions": 3,
      "changes": 5
    },
    {
      "filename": "dashboard/pubspec.lock",
      "additions": 1,
      "deletions": 1,
      "changes": 2
    },
    {
      "filename": "dashboard/test/build_dashboard_page_test.dart",
      "additions": 21,
      "deletions": 33,
      "changes": 54
    },
    {
      "filename": "dashboard/test/index_page_test.dart",
      "additions": 4,
      "deletions": 7,
      "changes": 11
    },
    {
      "filename": "dashboard/test/logic/qualified_task_test.dart",
      "additions": 9,
      "deletions": 16,
      "changes": 25
    },
    {
      "filename": "dashboard/test/logic/task_grid_filter_test.dart",
      "additions": 11,
      "deletions": 18,
      "changes": 29
    },
    {
      "filename": "dashboard/test/service/appengine_cocoon_test.dart",
      "additions": 74,
      "deletions": 112,
      "changes": 186
    },
    {
      "filename": "dashboard/test/service/google_authentication_test.dart",
      "additions": 2,
      "deletions": 4,
      "changes": 6
    },
    {
      "filename": "dashboard/test/state/build_test.dart",
      "additions": 20,
      "deletions": 31,
      "changes": 51
    },
    {
      "filename": "dashboard/test/utils/fake_build.dart",
      "additions": 6,
      "deletions": 10,
      "changes": 16
    },
    {
      "filename": "dashboard/test/utils/golden.dart",
      "additions": 4,
      "deletions": 6,
      "changes": 10
    },
    {
      "filename": "dashboard/test/widgets/accessibility_test.dart",
      "additions": 14,
      "deletions": 22,
      "changes": 36
    }
  ]
''';

const String originalPullRequestJson = '''
  {
  "url": "https://api.github.com/repos/flutter/cocoon/pulls/2024",
  "id": 1012225049,
  "node_id": "PR_kwDOA8VHis48VVQZ",
  "number": 2024,
  "state": "closed",
  "locked": false,
  "title": "Trailing comma analysis",
  "user": {
    "login": "ricardoamador",
    "id": 32242716
  },
  "body": "## Description Add trailing comma requirement to analysis file. * if you had to change anything in the [flutter/tests] repo, include a link to the migration guide as per the [breaking change policy].* ## Pre-launch Checklist - [x] I read the [Contributor Guide] and followed the process outlined there for submitting PRs. - [x]  I read the [Tree Hygiene] wiki page, which explains my responsibilities. - [x] I read the [Flutter Style Guide] _recently_, and have followed its advice. - [x] I signed the [CLA]. - [x] I listed at least one issue that this PR fixes in the description above. - [x] I updated/added relevant documentation (doc comments with `///`). - [x] I added new tests to check the change I am making, or this PR is [test-exempt]. - [x] All existing and new tests are passing. If you need help, consider asking for advice on the #hackers-new channel on [Discord]. <!-- Links --> [Contributor Guide]: https://github.com/flutter/flutter/wiki/Tree-hygiene#overview [Tree Hygiene]: https://github.com/flutter/flutter/wiki/Tree-hygiene [test-exempt]: https://github.com/flutter/flutter/wiki/Tree-hygiene#tests [Flutter Style Guide]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo [CLA]: https://cla.developers.google.com/ [flutter/tests]: https://github.com/flutter/tests [breaking change policy]: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes [Discord]: https://github.com/flutter/flutter/wiki/Chat",
  "created_at": "2022-07-29T17:56:31Z",
  "labels": [
    {
      "id": 3960015931,
      "node_id": "LA_kwDOA8VHis7sCQw7",
      "url": "https://api.github.com/repos/flutter/cocoon/labels/autosubmit",
      "name": "autosubmit",
      "color": "0E8A16",
      "default": false,
      "description": "Merge PR when tree becomes green via auto submit App"
    }
  ],
  "head": {
    "label": "ricardoamador:trailing_comma_analysis",
    "ref": "trailing_comma_analysis",
    "sha": "8f2f3d7157345fc1d1c497e1b8106a1d9716fac8",
    "user": {
      "login": "ricardoamador",
      "id": 32242716,
      "node_id": "MDQ6VXNlcjMyMjQyNzE2"
    },
    "repo": {
      "id": 494596620,
      "node_id": "R_kgDOHXryDA",
      "name": "cocoon",
      "full_name": "ricardoamador/cocoon",
      "private": false,
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
      "default_branch": "main"
    }
  },
  "base": {
    "label": "flutter:main",
    "ref": "main",
    "sha": "bb71fb95db4b1ac61194cd2a12134e9a469960a9",
    "user": {
      "login": "flutter",
      "id": 14101776,
      "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2"
    },
    "repo": {
      "id": 63260554,
      "node_id": "MDEwOlJlcG9zaXRvcnk2MzI2MDU1NA==",
      "name": "cocoon",
      "full_name": "flutter/cocoon",
      "private": false,
      "owner": {
        "login": "flutter",
        "id": 14101776,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
        "avatar_url": "https://avatars.githubusercontent.com/u/14101776?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "type": "Organization",
        "site_admin": false
      },
      "default_branch": "main"
    }
  },
  "auto_merge": null,
  "active_lock_reason": null,
  "merged": true,
  "mergeable": null,
  "rebaseable": null,
  "mergeable_state": "unknown",
  "merged_by": {
    "login": "auto-submit[bot]",
    "id": 98614782,
    "node_id": "BOT_kgDOBeC9_g",
    "avatar_url": "https://avatars.githubusercontent.com/u/14101776?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/auto-submit%5Bbot%5D",
    "html_url": "https://github.com/apps/auto-submit",
    "type": "Bot",
    "site_admin": false
  },
  "comments": 0,
  "review_comments": 0,
  "maintainer_can_modify": false,
  "commits": 4,
  "additions": 472,
  "deletions": 325,
  "changed_files": 25
}
''';

const String originalPullRequestFilesJson = '''
  [
    {
      "filename": "dashboard/analysis_options.yaml",
      "additions": 1,
      "deletions": 0,
      "changes": 1
    },
    {
      "filename": "dashboard/lib/build_dashboard_page.dart",
      "additions": 45,
      "deletions": 35,
      "changes": 80
    },
    {
      "filename": "dashboard/lib/index_page.dart",
      "additions": 12,
      "deletions": 10,
      "changes": 22
    },
    {
      "filename": "dashboard/lib/logic/brooks.dart",
      "additions": 20,
      "deletions": 18,
      "changes": 38
    },
    {
      "filename": "dashboard/lib/logic/links.dart",
      "additions": 18,
      "deletions": 15,
      "changes": 33
    },
    {
      "filename": "dashboard/lib/logic/task_grid_filter.dart",
      "additions": 12,
      "deletions": 4,
      "changes": 16
    },
    {
      "filename": "dashboard/lib/main.dart",
      "additions": 7,
      "deletions": 6,
      "changes": 13
    },
    {
      "filename": "dashboard/lib/service/appengine_cocoon.dart",
      "additions": 23,
      "deletions": 16,
      "changes": 39
    },
    {
      "filename": "dashboard/lib/service/dev_cocoon.dart",
      "additions": 15,
      "deletions": 8,
      "changes": 23
    },
    {
      "filename": "dashboard/lib/widgets/lattice.dart",
      "additions": 22,
      "deletions": 18,
      "changes": 40
    },
    {
      "filename": "dashboard/lib/widgets/luci_task_attempt_summary.dart",
      "additions": 5,
      "deletions": 4,
      "changes": 9
    },
    {
      "filename": "dashboard/lib/widgets/sign_in_button.dart",
      "additions": 12,
      "deletions": 10,
      "changes": 22
    },
    {
      "filename": "dashboard/lib/widgets/task_grid.dart",
      "additions": 17,
      "deletions": 13,
      "changes": 30
    },
    {
      "filename": "dashboard/lib/widgets/task_overlay.dart",
      "additions": 3,
      "deletions": 2,
      "changes": 5
    },
    {
      "filename": "dashboard/pubspec.lock",
      "additions": 1,
      "deletions": 1,
      "changes": 2
    },
    {
      "filename": "dashboard/test/build_dashboard_page_test.dart",
      "additions": 33,
      "deletions": 21,
      "changes": 54
    },
    {
      "filename": "dashboard/test/index_page_test.dart",
      "additions": 7,
      "deletions": 4,
      "changes": 11
    },
    {
      "filename": "dashboard/test/logic/qualified_task_test.dart",
      "additions": 16,
      "deletions": 9,
      "changes": 25
    },
    {
      "filename": "dashboard/test/logic/task_grid_filter_test.dart",
      "additions": 18,
      "deletions": 11,
      "changes": 29
    },
    {
      "filename": "dashboard/test/service/appengine_cocoon_test.dart",
      "additions": 112,
      "deletions": 74,
      "changes": 186
    },
    {
      "filename": "dashboard/test/service/google_authentication_test.dart",
      "additions": 4,
      "deletions": 2,
      "changes": 6
    },
    {
      "filename": "dashboard/test/state/build_test.dart",
      "additions": 31,
      "deletions": 20,
      "changes": 51
    },
    {
      "filename": "dashboard/test/utils/fake_build.dart",
      "additions": 10,
      "deletions": 6,
      "changes": 16
    },
    {
      "filename": "dashboard/test/utils/golden.dart",
      "additions": 6,
      "deletions": 4,
      "changes": 10
    },
    {
      "filename": "dashboard/test/widgets/accessibility_test.dart",
      "additions": 22,
      "deletions": 14,
      "changes": 36
    }
  ]
''';

const String originalPullRequestFilesSubsetJson = '''
  [
    {
      "filename": "dashboard/analysis_options.yaml",
      "additions": 1,
      "deletions": 0,
      "changes": 1
    },
    {
      "filename": "dashboard/lib/build_dashboard_page.dart",
      "additions": 45,
      "deletions": 35,
      "changes": 80
    },
    {
      "filename": "dashboard/lib/index_page.dart",
      "additions": 12,
      "deletions": 10,
      "changes": 22
    },
    {
      "filename": "dashboard/lib/logic/brooks.dart",
      "additions": 20,
      "deletions": 18,
      "changes": 38
    },
    {
      "filename": "dashboard/lib/logic/links.dart",
      "additions": 18,
      "deletions": 15,
      "changes": 33
    },
    {
      "filename": "dashboard/lib/logic/task_grid_filter.dart",
      "additions": 12,
      "deletions": 4,
      "changes": 16
    },
    {
      "filename": "dashboard/lib/service/appengine_cocoon.dart",
      "additions": 23,
      "deletions": 16,
      "changes": 39
    },
    {
      "filename": "dashboard/lib/service/dev_cocoon.dart",
      "additions": 15,
      "deletions": 8,
      "changes": 23
    },
    {
      "filename": "dashboard/lib/widgets/lattice.dart",
      "additions": 22,
      "deletions": 18,
      "changes": 40
    },
    {
       "filename": "dashboard/lib/widgets/sign_in_button.dart",
      "additions": 12,
      "deletions": 10,
      "changes": 22
    },
    {
      "filename": "dashboard/lib/widgets/task_grid.dart",
      "additions": 17,
      "deletions": 13,
      "changes": 30
    },
    {
      "filename": "dashboard/lib/widgets/task_overlay.dart",
      "additions": 3,
      "deletions": 2,
      "changes": 5
    },
    {
      "filename": "dashboard/pubspec.lock",
      "additions": 1,
      "deletions": 1,
      "changes": 2
    },
    {
      "filename": "dashboard/test/build_dashboard_page_test.dart",
      "additions": 33,
      "deletions": 21,
      "changes": 54
    },
    {
      "filename": "dashboard/test/index_page_test.dart",
      "additions": 7,
      "deletions": 4,
      "changes": 11
    },
    {
      "filename": "dashboard/test/logic/qualified_task_test.dart",
      "additions": 16,
      "deletions": 9,
      "changes": 25
    },
    {
      "filename": "dashboard/test/logic/task_grid_filter_test.dart",
      "additions": 18,
      "deletions": 11,
      "changes": 29
    },
    {
      "filename": "dashboard/test/service/appengine_cocoon_test.dart",
      "additions": 112,
      "deletions": 74,
      "changes": 186
    },
    {
      "filename": "dashboard/test/service/google_authentication_test.dart",
      "additions": 4,
      "deletions": 2,
      "changes": 6
    },
    {
      "filename": "dashboard/test/state/build_test.dart",
      "additions": 31,
      "deletions": 20,
      "changes": 51
    },
    {
      "filename": "dashboard/test/utils/fake_build.dart",
      "additions": 10,
      "deletions": 6,
      "changes": 16
    },
    {
      "filename": "dashboard/test/utils/golden.dart",
      "additions": 6,
      "deletions": 4,
      "changes": 10
    },
    {
      "filename": "dashboard/test/widgets/accessibility_test.dart",
      "additions": 22,
      "deletions": 14,
      "changes": 36
    }
  ]
''';

const String ciyamlCheckRun = '''
{
  "total_count": 1,
  "check_runs": [
    {
      "id": 8752872923,
      "name": "ci.yaml validation",
      "head_sha": "60612a38d705d00a234e0aabba08247fc0dda1ac",
      "status": "completed",
      "conclusion": "success",
      "started_at": "2022-10-06T20:50:57Z",
      "completed_at": "2022-10-06T20:51:40Z",
      "check_suite": {
        "id": 8654966141
      }
    }
  ]
}
''';

const String ciyamlCheckRunNotComplete = '''
{
  "total_count": 1,
  "check_runs": [
    {
      "id": 8752872923,
      "name": "ci.yaml validation",
      "head_sha": "60612a38d705d00a234e0aabba08247fc0dda1ac",
      "status": "in_progress",
      "started_at": "2022-10-06T20:50:57Z",
      "completed_at": "2022-10-06T20:51:40Z",
      "check_suite": {
        "id": 8654966141
      }
    }
  ]
}
''';
