// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gql/ast.dart';
import 'package:gql/language.dart' as lang;

final DocumentNode labeledPullRequestsWithReviewsQuery = lang.parseString(r'''
query LabeledPullRequestsWithReviews($sOwner: String!, $sName: String!, $sLabelName: String!) {
  repository(owner: $sOwner, name: $sName) {
    pullRequests(first: 20, states: OPEN, labels: [$sLabelName], orderBy: {direction: ASC, field: CREATED_AT}) {
      nodes {
        author {
          login
        }
        authorAssociation
        id
        baseRepository {
          nameWithOwner
        }
        number
        title
        mergeable
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
              # (appId: 64368) == flutter-dashbord. We only care about
              # flutter-dashboard checks.
              checkSuites(last:1, filterBy: { appId: 64368 } ) {
                nodes {
                  checkRuns(first:100) {
                    nodes {
                      name
                      status
                      conclusion
                      detailsUrl
                    }
                  }
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
        labels(first: 10) {
          nodes {
            name
            id
          }
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

final DocumentNode removeLabelMutation = lang.parseString(r'''
mutation RemoveLabelAndComment($id: ID!, $sBody: String!, $labelId: ID!) {
  addComment(input: { subjectId:$id, body: $sBody }) {
    clientMutationId
  }
  removeLabelsFromLabelable(input: { labelableId: $id, labelIds: [$labelId] }) {
    clientMutationId
  }
}''');
