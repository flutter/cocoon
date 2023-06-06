// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:github/github.dart' as github;
import 'package:auto_submit/model/auto_submit_query_result.dart';

const String oid = '6dcb09b5b57875f334f61aebed695e2e4193db5e';
const String title = 'some_title';

/// Helper for Github statuses.
@immutable
class StatusHelper {
  const StatusHelper(this.name, this.state);

  static const StatusHelper flutterBuildSuccess = StatusHelper('luci-flutter', 'SUCCESS');
  static const StatusHelper flutterBuildFailure = StatusHelper('luci-flutter', 'FAILURE');
  static const StatusHelper otherStatusFailure = StatusHelper('other status', 'FAILURE');

  final String name;
  final String state;
}

/// Helper to generate Github pull requests.
class PullRequestHelper {
  PullRequestHelper({
    this.author = 'author1',
    this.prNumber = 0,
    this.id = 'PR_kwDOA8VHis5QCyt7',
    this.repo = 'flutter',
    this.authorAssociation = 'MEMBER',
    this.title = 'some_title',
    this.reviews = const <PullRequestReviewHelper>[
      PullRequestReviewHelper(authorName: 'member', state: ReviewState.APPROVED, memberType: MemberType.MEMBER)
    ],
    this.lastCommitHash = 'oid',
    this.lastCommitStatuses = const <StatusHelper>[StatusHelper.flutterBuildSuccess],
    this.lastCommitMessage = '',
    this.dateTime,
    this.state = 'open',
  });

  final int prNumber;
  final String id;
  final String repo;
  final String author;
  final String authorAssociation;
  final List<PullRequestReviewHelper> reviews;
  final String lastCommitHash;
  List<StatusHelper>? lastCommitStatuses;
  final String? lastCommitMessage;
  final DateTime? dateTime;
  final String title;
  final String state;

  github.RepositorySlug get slug => github.RepositorySlug('flutter', repo);

  Map<String, dynamic> toEntry() {
    return <String, dynamic>{
      'author': <String, dynamic>{'login': author},
      'authorAssociation': authorAssociation,
      'number': prNumber,
      'id': id,
      'title': title,
      'state': state,
      'reviews': <String, dynamic>{
        'nodes': reviews.map((PullRequestReviewHelper review) {
          return <String, dynamic>{
            'author': <String, dynamic>{'login': review.authorName},
            'authorAssociation': review.memberType.toString().replaceFirst('MemberType.', ''),
            'state': review.state.toString().replaceFirst('ReviewState.', ''),
          };
        }).toList(),
      },
      'commits': <String, dynamic>{
        'nodes': <dynamic>[
          <String, dynamic>{
            'commit': <String, dynamic>{
              'oid': lastCommitHash,
              'pushedDate': (dateTime ?? DateTime.now().add(const Duration(hours: -2))).toUtc().toIso8601String(),
              'message': lastCommitMessage,
              'status': <String, dynamic>{
                'contexts': lastCommitStatuses != null
                    ? lastCommitStatuses!.map((StatusHelper status) {
                        return <String, dynamic>{
                          'context': status.name,
                          'state': status.state,
                          'targetUrl': 'https://${status.name}',
                        };
                      }).toList()
                    : <dynamic>[]
              },
            },
          }
        ],
      },
    };
  }
}

/// Generate `QueryResult` model as in auto submit.
QueryResult createQueryResult(PullRequestHelper pullRequest) {
  return QueryResult.fromJson(<String, dynamic>{
    'repository': <String, dynamic>{
      'pullRequest': pullRequest.toEntry().cast<String, dynamic>(),
    }
  });
}

// /// Generate a revert mutation result.
// RevertPullRequestData createMutationResult(
//   PullRequestHelper closedPullRequest,
//   PullRequestHelper revertPullRequest,
//   String clientMutationId,
// ) {
//   return RevertPullRequestData.fromJson(<String, dynamic>{
//     'revertPullRequest': <String, dynamic>{
//       "clientMutationId": clientMutationId,
//       'pullRequest': closedPullRequest.toEntry().cast<String, dynamic>(),
//       'revertPullRequest': revertPullRequest.toEntry().cast<String, dynamic>(),
//     }
//   });
// }

/// List of review state from a github pull request.
enum ReviewState {
  APPROVED,
  CHANGES_REQUESTED,
}

/// List of member type of a github pull request author/reviewer.
enum MemberType {
  OWNER,
  MEMBER,
  OTHER,
}

/// Details of a github pull request review.
@immutable
class PullRequestReviewHelper {
  const PullRequestReviewHelper({
    required this.authorName,
    required this.state,
    required this.memberType,
  });

  final String authorName;
  final ReviewState state;
  final MemberType memberType;
}
