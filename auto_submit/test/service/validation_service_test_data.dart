// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Return data for revert mutation call.
const String revertMutationResult = '''
{
  "revertPullRequest": {
    "clientMutationId": "ra186026",
    "pullRequest": {
      "author": {
        "login": "ricardoamador"
      },
      "authorAssociation": "OWNER",
      "id": "PR_kwDOIRxr_M5MQ7mV",
      "title": "Adding a TODO comment for testing pull request auto approval.",
      "number": 18,
      "body": "",
      "repository": {
        "owner": {
          "login": "ricardoamador"
        },
        "name": "flutter_test"
      }
    },
    "revertPullRequest": {
      "author": {
        "login": "ricardoamador"
      },
      "authorAssociation": "OWNER",
      "id": "PR_kwDOIRxr_M5RXQgj",
      "title": "Revert comment in configuration file.",
      "number": 24,
      "body": "Testing revert mutation",
      "repository": {
        "owner": {
          "login": "ricardoamador"
        },
        "name": "flutter_test"
      }
    }
  }
}
''';