// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gql/ast.dart';
import 'package:gql/language.dart' as lang;

final DocumentNode pullRequestWithReviewsQuery = lang.parseString(r'''
query LabeledPullRequcodeestWithReviews($sOwner: String!, $sName: String!, $sPrNumber: Int!) {
  repository(owner: $sOwner, name: $sName) {
    pullRequest(number: $sPrNumber) {
      author {
        login
      }
      authorAssociation
      id
      title
      commits(last:1) {
        nodes {
          commit {
            abbreviatedOid
            oid
            committedDate
            pushedDate
            status {
              contexts {
                context
                state
                targetUrl
              }
            }
          }
        }
      }
      reviews(last: 30, states: [APPROVED, CHANGES_REQUESTED]) {
        nodes {
          author {
            login
          }
          authorAssociation
          state
        }
      }
    }
  }
}''');

final DocumentNode mergePullRequestMutation = lang.parseString(r'''
mutation MergePR($id: ID!, $oid: GitObjectID!, $title: String) {
  mergePullRequest(input: {
    pullRequestId: $id,
    expectedHeadOid: $oid,
    mergeMethod: SQUASH,
    commitBody: "",
    commitHeadline: $title
  }) {
    clientMutationId
  }
}''');
