// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
