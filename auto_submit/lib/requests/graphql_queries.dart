// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gql/ast.dart';
import 'package:gql/language.dart' as lang;

/// Provides a way to encapsulate the named variables that will be needed for
/// each request made via the graphql api.
abstract class GraphQLOperation {
  /// The list of variables that will be injected into the partner
  /// [DocumentNode] made in the graphql service.
  Map<String, dynamic> get variables;

  /// The document that contains the GraphQL operation.
  DocumentNode get documentNode;
}

/// [FindPullRequestsWithReviewsQuery] encapsulates the input variables and
/// [DocumentNode] needed to get a pull request with the last 30 reviews.
class FindPullRequestsWithReviewsQuery extends GraphQLOperation {
  FindPullRequestsWithReviewsQuery({
    required this.repositoryOwner,
    required this.repositoryName,
    required this.pullRequestNumber,
  });

  final String repositoryOwner;
  final String repositoryName;
  final int pullRequestNumber;

  @override
  Map<String, dynamic> get variables => <String, dynamic>{
        'sOwner': repositoryOwner,
        'sName': repositoryName,
        'sPrNumber': pullRequestNumber,
      };

  @override
  DocumentNode get documentNode => lang.parseString(r'''
query LabeledPullRequestWithReviews($sOwner: String!, $sName: String!, $sPrNumber: Int!) {
  repository(owner: $sOwner, name: $sName) {
    pullRequest(number: $sPrNumber) {
      author {
        login
      }
      authorAssociation
      id
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
                createdAt
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
}

/// [FindPullRequestNodeIdQuery] encapsulate the input variables and
/// [DocumentNode] needed to the query the Pull Request Node ID that github uses
/// to locate a pull request accross all repos.
class FindPullRequestNodeIdQuery extends GraphQLOperation {
  FindPullRequestNodeIdQuery({
    required this.repositoryOwner,
    required this.repositoryName,
    required this.pullRequestNumber,
  });

  final String repositoryOwner;
  final String repositoryName;
  final int pullRequestNumber;

  @override
  Map<String, dynamic> get variables => {
        'repoOwner': repositoryOwner,
        'repoName': repositoryName,
        'pullRequestNumber': pullRequestNumber,
      };

  @override
  DocumentNode get documentNode => lang.parseString(r'''
query FindPullRequestNodeId ($repoOwner:String!, $repoName:String!, $pullRequestNumber:Int!) {
  repository(owner:$repoOwner, name:$repoName) {
    pullRequest(number:$pullRequestNumber) {
      id
    }
  }
}
''');
}

/// [RevertPullRequestMutation] encapsulates the input variables and
/// [DocumentNode] needed to perform the revert request mutation to revert a
/// closed pull request.
class RevertPullRequestMutation extends GraphQLOperation {
  RevertPullRequestMutation(
    this.body,
    this.clientMutationId,
    this.draft,
    this.id,
    this.title,
  );

  final String body;
  final String? clientMutationId;
  final bool draft;
  final String id;
  final String title;

  @override
  Map<String, dynamic> get variables => {
        'revertBody': body,
        'clientMutationId': clientMutationId,
        'draft': draft,
        'pullRequestId': id,
        'revertTitle': title,
      };

  @override
  DocumentNode get documentNode => lang.parseString(r'''
mutation RevertPullFlutterPullRequest ($revertBody:String!, $clientMutationId:String!, $draft:Boolean, $pullRequestId:ID!, $revertTitle:String!) {
  revertPullRequest (
    input: {
      body:$revertBody,
      clientMutationId: $clientMutationId,
      draft: $draft,
      pullRequestId: $pullRequestId,
      title: $revertTitle
    }) {
      clientMutationId
      pullRequest {
        author {
          login
        }
        authorAssociation
        id
        title
        number
        repository {
          owner {
            login
          }
          name
        }
      }
      revertPullRequest {
        author {
          login
        }
        authorAssociation
        id
        title
        number
        repository {
          owner {
            login
          }
          name
        }
      }
  }
}
''');
}

/// Instructs Github to put a pull request in the merge queue.
///
/// Assumes the repository targeted by the pull request has merge queue enabled.
///
/// https://docs.github.com/en/graphql/reference/mutations#enqueuepullrequest
class EnqueuePullRequestMutation extends GraphQLOperation {
  EnqueuePullRequestMutation({
    required this.id,
    required this.jump,
  });

  final String id;
  final bool jump;

  @override
  Map<String, dynamic> get variables => {
        'pullRequestId': id,
        'jump': jump,
      };

  @override
  DocumentNode get documentNode => lang.parseString(r'''
mutation EnqueueFlutterPullRequest ($pullRequestId:ID!, $jump:Boolean!) {
  enqueuePullRequest (
    input: {
      pullRequestId: $pullRequestId,
      jump: $jump,
    }
  ) {
    clientMutationId
  }
}
''');
}
