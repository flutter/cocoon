// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String labeledPullRequestsWithReviewsQuery = r'''
query LabeledPullRequcodeestsWithReviews($sOwner: String!, $sName: String!, $sLabelName: String!) {
  repository(owner: $sOwner, name: $sName) {
    labels(first: 1, query: $sLabelName) {
      nodes {
        id
        pullRequests(first: 100, states: OPEN, orderBy: {direction: ASC, field: CREATED_AT}) {
          nodes {
            author {
              login
            }
            id
            number
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
                    }
                  }
                  checkSuites(first: 10) {
                    nodes {
                      app {
                        name
                      }
                      checkRuns(last: 100) {
                        nodes {
                          id
                          name
                          status
                          conclusion
                        }
                      }
                    }
                  }
                }
              }
            }
            reviews(first: 100, states: [APPROVED, CHANGES_REQUESTED]) {
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
      }
    }
  }
}''';

const String mergePullRequestMutation = r'''
mutation MergePR($id: ID!, $oid: GitObjectID!) {
  mergePullRequest(input: {
    pullRequestId: $id,
    expectedHeadOid: $oid,
    mergeMethod: SQUASH,
    commitBody: ""
  }) {
    clientMutationId
  }
}''';

const String removeLabelMutation = r'''
mutation RemoveLabelAndComment($id: ID!, $sBody: String!, $labelId: ID!) {
  addComment(input: { subjectId:$id, body: $sBody }) {
    clientMutationId
  }
  removeLabelsFromLabelable(input: { labelableId: $id, labelIds: [$labelId] }) {
    clientMutationId
  }
}''';
