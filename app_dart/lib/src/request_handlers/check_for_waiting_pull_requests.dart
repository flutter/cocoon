// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonEncode;

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

import 'check_for_waiting_pull_requests_queries.dart';

@immutable
class CheckForWaitingPullRequests extends ApiRequestHandler<Body> {
  const CheckForWaitingPullRequests(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LoggingProvider loggingProvider,
  })  : loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        super(config: config, authenticationProvider: authenticationProvider);

  final LoggingProvider loggingProvider;

  @override
  Future<Body> get() async {
    final Logging log = loggingProvider();
    final GraphQLClient client = await config.createGitHubGraphQLClient();

    await _checkPRs('flutter', 'flutter', log, client);
    await _checkPRs('flutter', 'engine', log, client);

    return Body.empty;
  }

  Future<void> _checkPRs(
    String owner,
    String name,
    Logging log,
    GraphQLClient client,
  ) async {
    bool hasMerged = false;
    final Map<String, dynamic> data = await _queryGraphQL(
      owner,
      name,
      log,
      client,
    );
    for (_AutoMergeQueryResult queryResult in _parseQueryData(data)) {
      if (!hasMerged && queryResult.shouldMerge) {
        hasMerged = await _mergePullRequest(
          queryResult.graphQLId,
          queryResult.sha,
          log,
          client,
        );
      } else if (queryResult.shouldRemoveLabel) {
        await _removeLabel(
          queryResult.graphQLId,
          queryResult.removalMessage,
          queryResult.labelId,
          client,
        );
      }
    }
  }

  Future<Map<String, dynamic>> _queryGraphQL(
    String owner,
    String name,
    Logging log,
    GraphQLClient client,
  ) async {
    final String labelName = await config.waitingForTreeToGoGreenLabelName;

    final QueryResult result = await client.query(
      QueryOptions(
        document: labeledPullRequestsWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'sOwner': owner,
          'sName': name,
          'sLabelName': labelName,
        },
      ),
    );

    if (result.hasErrors) {
      log.error(jsonEncode(result.errors));
      throw const BadRequestException('GraphQL query failed');
    }

    return result.data;
  }

  Future<bool> _removeLabel(
    String id,
    String message,
    String labelId,
    GraphQLClient client,
  ) async {
    final QueryResult result = await client.mutate(MutationOptions(
      document: removeLabelMutation,
      variables: <String, dynamic>{
        'id': id,
        'sBody': message,
        'labelId': labelId,
      },
    ));
    if (result.hasErrors) {
      log.error(jsonEncode(result.errors));
      return false;
    }
    return true;
  }

  Future<bool> _mergePullRequest(
    String id,
    String sha,
    Logging log,
    GraphQLClient client,
  ) async {
    final QueryResult result = await client.mutate(MutationOptions(
      document: mergePullRequestMutation,
      variables: <String, dynamic>{
        'id': id,
        'oid': sha,
      },
    ));

    if (result.hasErrors) {
      log.error(jsonEncode(result.errors));
      return false;
    }
    return true;
  }

  /// Parses a GraphQL query to a list of [_AutoMergeQueryResult]s.
  ///
  /// This method will not return null, but may return an empty list.
  List<_AutoMergeQueryResult> _parseQueryData(Map<String, dynamic> data) {
    final Map<String, dynamic> repository = data['repository'];
    if (repository == null || repository.isEmpty) {
      throw StateError('Query did not return a repository.');
    }

    final Map<String, dynamic> label = repository['labels']['nodes'].single;
    if (label == null || label.isEmpty) {
      throw StateError('Query did not find information about the waitingForTreeToGoGreen label.');
    }
    final String labelId = label['id'];
    final List<_AutoMergeQueryResult> list = <_AutoMergeQueryResult>[];
    final Iterable<Map<String, dynamic>> pullRequests = label['pullRequests']['nodes'].cast<Map<String, dynamic>>();
    for (Map<String, dynamic> pullRequest in pullRequests) {
      final Map<String, dynamic> commit = pullRequest['commits']['nodes'].single['commit'];
      // Skip commits that are less than an hour old.
      // Use the committedDate if pushedDate is null (commitedDate cannot be null).
      final DateTime utcDate = DateTime.parse(commit['pushedDate'] ?? commit['committedDate']);
      if (utcDate.add(const Duration(hours: 1)).isAfter(DateTime.now().toUtc())) {
        continue;
      }
      final String id = pullRequest['id'];
      final int number = pullRequest['number'];
      final bool mergeable = pullRequest['mergeable'] == 'MERGEABLE';
      final bool hasApproval = pullRequest['approvedReviews']['nodes'].isNotEmpty;
      final bool hasChangesRequested = pullRequest['changeRequestReviews']['nodes'].isNotEmpty;
      final String sha = commit['oid'];
      final bool ciSuccessful = commit['status']['state'] == 'SUCCESS';
      list.add(_AutoMergeQueryResult(
        graphQLId: id,
        ciSuccessful: ciSuccessful,
        hasApprovedReview: hasApproval,
        hasChangesRequested: hasChangesRequested,
        mergeable: mergeable,
        number: number,
        sha: sha,
        labelId: labelId,
      ));
    }
    return list;
  }
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
