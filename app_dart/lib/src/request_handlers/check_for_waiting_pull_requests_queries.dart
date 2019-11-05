// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String labeledPullRequestsWithReviewsQuery = r'''
query LabeledPullRequestsWithReviews($sOwner: String!, $sName: String!, $sLabelName: String!) {
  repository(owner: $sOwner, name: $sName) {
    labels(first: 1, query: $sLabelName) {
      nodes {
        id
        pullRequests(first: 100, states: OPEN) {
          nodes {
            id
            number
            mergeable
            commits(last:1) {
              nodes {
                commit {
                  abbreviatedOid
                  oid
                  status {
                    state
                  }
                }
              }
            }
            changeRequestReviews: reviews(first: 1, states: [CHANGES_REQUESTED]) {
              nodes {
                state
              }
            }
            approvedReviews: reviews(first: 1, states: [APPROVED]) {
              nodes {
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
