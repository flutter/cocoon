import 'dart:convert' show jsonEncode;

import 'package:cocoon_service/src/datastore/cocoon_config.dart';
import 'package:http/http.dart' as http;
import 'package:graphql/client.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

const String _removeLabelMutation = r'''
mutation RemoveLabelAndComment($id: ID!, $sBody: String!, $labelId: ID!) {
  addComment(input: { subjectId:$id, body: $sBody }) {
    clientMutationId
  }
  removeLabelsFromLabelable(input: { labelableId: $id, labelIds: [$labelId] }) {
    clientMutationId
  }
}''';

Future<void> main() async {
  final HttpLink _httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  final AuthLink _authLink = AuthLink(
    getToken: () async => 'Bearer fabddf154d0d1d80289845e98b2416cce96641b8',
  );

  final Link _link = _authLink.concat(_httpLink);

  final GraphQLClient _client = GraphQLClient(
    cache: InMemoryCache(),
    link: _link,
  );

  const String _labeledPullRequestsWithReviewsQuery = r'''
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
            reviews(first: 100, states: [CHANGES_REQUESTED, APPROVED]) {
              nodes {
                state
                author {
                  login
                }
              }
            }
          }
        }
      }
    }
  }
}''';

  final QueryResult result = await _client.query(
    QueryOptions(
        document: _labeledPullRequestsWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'sOwner': 'flutter',
          'sName': 'flutter',
          'sLabelName': 'waiting for tree to go green',
        }),
  );

  if (result.hasErrors) {
    print(result.errors);
    return;
  }

  for (_AutoMergeQueryResult queryResult in _parseQueryData(result.data)) {
    print(queryResult);
    if (queryResult.shouldMerge) {
      // print('Will attempt to merge ${queryResult.number}');
      await _mergePullRequest(
        null,
        RepositorySlug('flutter', 'flutter'),
        queryResult.number,
        queryResult.sha,
      );
    } else if (queryResult.shouldRemoveLabel) {
      // print('Will remove label from ${queryResult.number}');
      // print(queryResult.removalMessage);
    } else {
      // print('Will try ${queryResult.number} again later.');
    }
    if (queryResult.number == 43959) {
      continue;
      await _removeLabel(
        queryResult.graphQLId,
        queryResult.removalMessage,
        queryResult.labelId,
        _client,
      );
    }
  }
  return;
}

Future<bool> _removeLabel(
  String id,
  String message,
  String labelId,
  GraphQLClient client,
) async {
  final QueryResult result = await client.mutate(MutationOptions(
    document: _removeLabelMutation,
    variables: <String, dynamic>{
      'id': id,
      'sBody': message,
      'labelId': labelId,
    },
  ));
  if (result.hasErrors) {
    print(result.errors);
    return false;
  }
  return true;
}

Future<void> _mergePullRequest(
  Config config,
  RepositorySlug slug,
  int number,
  String sha,
) async {
  final GitHub client = await config.createGitHubClient();
  // https://developer.github.com/v3/pulls/#merge-a-pull-request-merge-button
  final Map<String, dynamic> json = <String, dynamic>{
    'commit_message': '',
    'sha': sha,
    'merge_method': 'squash',
  };
  final http.Response response = await client.request(
    'PUT',
    '/repos/${slug.fullName}/pulls/$number/merge',
    body: jsonEncode(json),
  );
  switch (response.statusCode) {
    case 200:
      break;
    case 409:
      break;
    case 405:
    default:
      throw '';
  }
}

/// Parses a GraphQL query to a list of [_AutoMergeQueryResult]s.
///
/// This method will not return null, but may return an empty list.
List<_AutoMergeQueryResult> _parseQueryData(Map<String, dynamic> data) {
  final Map<String, dynamic> repository = data['repository'];
  if (repository == null || repository.isEmpty) {
    return <_AutoMergeQueryResult>[];
  }
  final Map<String, dynamic> label = repository['labels']['nodes'].single;
  if (label == null || label.isEmpty) {
    return <_AutoMergeQueryResult>[];
  }
  final String labelId = label['id'];
  return label['pullRequests']['nodes']
      .cast<Map<String, dynamic>>()
      .map<_AutoMergeQueryResult>((Map<String, dynamic> pullRequest) {
    final String id = pullRequest['id'];
    final int number = pullRequest['number'];
    final bool mergeable = pullRequest['mergeable'] == 'MERGEABLE';
    print(pullRequest['mergeable']);
    final List<Map<String, dynamic>> reviews =
        pullRequest['reviews']['nodes'].cast<Map<String, dynamic>>();
    bool hasApproval = false;
    bool hasChangesRequested = false;
    for (Map<String, dynamic> review in reviews) {
      switch (review['state']) {
        case 'APPROVED':
          hasApproval = true;
          break;
        case 'CHANGES_REQUESTED':
          hasChangesRequested = true;
          break;
      }
    }
    final Map<String, dynamic> commit = pullRequest['commits']['nodes'].single['commit'];
    final String sha = commit['oid'];
    final bool ciSuccessful = commit['status']['state'] == 'SUCCESS';

    return _AutoMergeQueryResult(
      ciSuccessful: ciSuccessful,
      hasApprovedReview: hasApproval,
      hasChangesRequested: hasChangesRequested,
      mergeable: mergeable,
      number: number,
      sha: sha,
      labelId: labelId,
      graphQLId: id,
    );
  }).toList();
}

/// A model class describing the state of a pull request that has the "waiting
/// for tree to go green" label on it.
@immutable
class _AutoMergeQueryResult {
  const _AutoMergeQueryResult({
    @required this.graphQLId,
    @required this.hasApprovedReview,
    @required this.hasChangesRequested,
    @required this.mergeable,
    @required this.ciSuccessful,
    @required this.number,
    @required this.sha,
    @required this.labelId,
  })  : assert(graphQLId != null),
        assert(hasApprovedReview != null),
        assert(hasChangesRequested != null),
        assert(mergeable != null),
        assert(ciSuccessful != null),
        assert(number != null),
        assert(sha != null),
        assert(labelId != null);

  /// The GitHub GraphQL ID of this pull request.
  final String graphQLId;

  /// Whether the pull request has at least one approved review.
  final bool hasApprovedReview;

  /// Whether the pull request has at least one change request review.
  final bool hasChangesRequested;

  /// Whether the pull request is mergeable, i.e. has merge conflicts or not.
  final bool mergeable;

  /// Whether CI has run successfully on the pull request.
  final bool ciSuccessful;

  /// The pull request number.
  final int number;

  /// The git SHA to be merged.
  final String sha;

  /// The GitHub GraphQL ID of the waiting label.
  final String labelId;

  /// Whether it is sane to automatically merge this PR.
  bool get shouldMerge => ciSuccessful && mergeable && hasApprovedReview && !hasChangesRequested;

  /// Whether the auto-merge label should be removed from this PR.
  bool get shouldRemoveLabel => !mergeable || !hasApprovedReview || hasChangesRequested;

  /// An appropriate message to leave when removing the label.
  String get removalMessage {
    if (!shouldRemoveLabel) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('This pull request is not suitable for automatic merging in its '
        'current state.');
    buffer.writeln();
    if (!mergeable) {
      buffer.writeln('- Please resolve merge conflicts before re-applying this label.');
    }
    if (!hasApprovedReview) {
      buffer.writeln('- Please get at least one approved review before re-applying this '
          'label. __Reviewers__: If you left a comment approving, please use '
          'the "approve" review action instead.');
    }
    if (hasChangesRequested) {
      buffer.writeln('- This pull request has changes requested. Please resolve those '
          'before re-applying the label.');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return '$runtimeType{PR#$number, '
        'id: $graphQLId, '
        'sha: $sha, '
        'ciSuccessful: $ciSuccessful, '
        'hasApprovedReview: $hasApprovedReview, '
        'hasChangesRequested: $hasChangesRequested, '
        'mergeable: $mergeable, '
        'labelId: $labelId, '
        'shouldMerge: $shouldMerge}';
  }
}
