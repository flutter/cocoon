// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
import 'refresh_cirrus_status.dart';

/// Maximum number of pull requests to merge on each check.
/// This should be kept reasonably low to avoid flooding infra when the tree
/// goes green.
const int _kMergeCountPerCycle = 2;

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
    int mergeCount = 0;
    final Map<String, dynamic> data = await _queryGraphQL(
      owner,
      name,
      log,
      client,
    );
    for (_AutoMergeQueryResult queryResult
        in await _parseQueryData(data, name)) {
      if (mergeCount < _kMergeCountPerCycle && queryResult.shouldMerge) {
        final bool merged = await _mergePullRequest(
          queryResult.graphQLId,
          queryResult.sha,
          log,
          client,
        );
        if (merged) {
          mergeCount++;
        }
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
    final String labelName = config.waitingForTreeToGoGreenLabelName;

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
      for (GraphQLError error in result.errors) {
        log.error(error.toString());
      }
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
      for (GraphQLError error in result.errors) {
        log.error(error.toString());
      }
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
      for (GraphQLError error in result.errors) {
        log.error(error.toString());
      }
      return false;
    }
    return true;
  }

  /// Parses a GraphQL query to a list of [_AutoMergeQueryResult]s.
  ///
  /// This method will not return null, but may return an empty list.
  Future<List<_AutoMergeQueryResult>> _parseQueryData(
      Map<String, dynamic> data, String name) async {
    final Map<String, dynamic> repository = data['repository'];
    if (repository == null || repository.isEmpty) {
      throw StateError('Query did not return a repository.');
    }

    final Map<String, dynamic> label = repository['labels']['nodes'].single;
    if (label == null || label.isEmpty) {
      throw StateError(
          'Query did not find information about the waitingForTreeToGoGreen label.');
    }
    final String labelId = label['id'];
    final List<_AutoMergeQueryResult> list = <_AutoMergeQueryResult>[];
    final Iterable<Map<String, dynamic>> pullRequests =
        label['pullRequests']['nodes'].cast<Map<String, dynamic>>();
    for (Map<String, dynamic> pullRequest in pullRequests) {
      final Map<String, dynamic> commit =
          pullRequest['commits']['nodes'].single['commit'];
      // Skip commits that are less than an hour old.
      // Use the committedDate if pushedDate is null (commitedDate cannot be null).
      final DateTime utcDate =
          DateTime.parse(commit['pushedDate'] ?? commit['committedDate'])
              .toUtc();
      if (utcDate
          .add(const Duration(hours: 1))
          .isAfter(DateTime.now().toUtc())) {
        continue;
      }
      final String author = pullRequest['author']['login'];
      final String id = pullRequest['id'];
      final int number = pullRequest['number'];

      final Set<String> changeRequestAuthors = <String>{};
      final bool hasApproval = config.rollerAccounts.contains(author) ||
          _checkApproval(
            pullRequest['reviews']['nodes'].cast<Map<String, dynamic>>(),
            changeRequestAuthors,
          );

      final String sha = commit['oid'];
      final List<Map<String, dynamic>> statuses =
          commit['status']['contexts'].cast<Map<String, dynamic>>();
      final Set<String> failingStatuses = <String>{};

      final bool ciSuccessful = await _checkStatuses(
        sha,
        failingStatuses,
        statuses,
        name,
      );

      list.add(_AutoMergeQueryResult(
        graphQLId: id,
        ciSuccessful: ciSuccessful,
        failingStatuses: failingStatuses,
        hasApprovedReview: hasApproval,
        changeRequestAuthors: changeRequestAuthors,
        number: number,
        sha: sha,
        labelId: labelId,
      ));
    }
    return list;
  }

  /// Returns whether all statuses are successful.
  ///
  /// Also fills [failures] with the names of any status/check that has failed.
  Future<bool> _checkStatuses(
    String sha,
    Set<String> failures,
    List<Map<String, dynamic>> statuses,
    String name,
  ) async {
    assert(failures != null && failures.isEmpty);
    bool allSuccess = true;

    // The status checks that are not related to changes in this PR.
    const Set<String> notInAuthorsControl = <String>{
      'flutter-build', // flutter repo
      'luci-engine', // engine repo
    };

    for (Map<String, dynamic> status in statuses) {
      final String name = status['context'];
      if (status['state'] != 'SUCCESS') {
        allSuccess = false;
        if (status['state'] == 'FAILURE' &&
            !notInAuthorsControl.contains(name)) {
          failures.add(name);
        }
      }
    }

    const List<String> _failedStates = <String>['FAILED', 'ABORTED'];
    const List<String> _succeededStates = <String>['COMPLETED', 'SKIPPED'];
    final GraphQLClient cirrusClient = await config.createCirrusGraphQLClient();
    final List<dynamic> cirrusStatuses =
        await queryCirrusGraphQL(sha, cirrusClient, log, name);
    if (cirrusStatuses == null) {
      return allSuccess;
    }
    for (dynamic runStatus in cirrusStatuses) {
      final String status = runStatus['status'];
      final String name = runStatus['name'];
      if (!_succeededStates.contains(status)) {
        allSuccess = false;
      }
      if (_failedStates.contains(status)) {
        failures.add(name);
      }
    }
    return allSuccess;
  }
}

/// Parses the graphQL response reviews.
///
/// Checks that the authorAssociation is of a MEMBER or OWNER (ignore reviews
/// from people who don't have write access to the repo).
///
/// If there are any CHANGES_REQUESTED reviews, checks if the same author has
/// subsequently APPROVED.  From testing, dismissing a review means it won't
/// show up in this list since it will have a status of DISMISSED and we only
/// ask for CHANGES_REQUESTED or APPROVED - however, adding a new review does
/// not automatically dismiss the previous one (why, GitHub? Why?).
///
/// If the author has not subsequently approved or dismissed the review, the
/// name will be added to the changeRequestAuthors set.
///
/// Returns false if no approved reviews or any oustanding change request
/// reviews.
///
/// Returns true if at least one approved review and no outstanding change
/// request reviews.
bool _checkApproval(
  List<Map<String, dynamic>> reviewNodes,
  Set<String> changeRequestAuthors,
) {
  assert(changeRequestAuthors != null && changeRequestAuthors.isEmpty);
  bool hasAtLeastOneApprove = false;
  for (Map<String, dynamic> review in reviewNodes) {
    // Ignore reviews from non-members/owners.
    if (review['authorAssociation'] != 'MEMBER' &&
        review['authorAssociation'] != 'OWNER') {
      continue;
    }

    // Reviews come back in order of creation.
    final String state = review['state'];
    final String authorLogin = review['author']['login'];
    if (state == 'APPROVED') {
      hasAtLeastOneApprove = true;
      changeRequestAuthors.remove(authorLogin);
    } else if (state == 'CHANGES_REQUESTED') {
      changeRequestAuthors.add(authorLogin);
    }
  }

  return hasAtLeastOneApprove && changeRequestAuthors.isEmpty;
}

/// A model class describing the state of a pull request that has the "waiting
/// for tree to go green" label on it.
@immutable
class _AutoMergeQueryResult {
  const _AutoMergeQueryResult({
    @required this.graphQLId,
    @required this.hasApprovedReview,
    @required this.changeRequestAuthors,
    @required this.ciSuccessful,
    @required this.failingStatuses,
    @required this.number,
    @required this.sha,
    @required this.labelId,
  })  : assert(graphQLId != null),
        assert(hasApprovedReview != null),
        assert(changeRequestAuthors != null),
        assert(ciSuccessful != null),
        assert(failingStatuses != null),
        assert(number != null),
        assert(sha != null),
        assert(labelId != null);

  /// The GitHub GraphQL ID of this pull request.
  final String graphQLId;

  /// Whether the pull request has at least one approved review.
  final bool hasApprovedReview;

  /// A set of login names that have at least one outstanding change request.
  final Set<String> changeRequestAuthors;

  /// Whether CI has run successfully on the pull request.
  final bool ciSuccessful;

  /// A set of status names that have failed.
  final Set<String> failingStatuses;

  /// The pull request number.
  final int number;

  /// The git SHA to be merged.
  final String sha;

  /// The GitHub GraphQL ID of the waiting label.
  final String labelId;

  /// Whether it is sane to automatically merge this PR.
  bool get shouldMerge =>
      ciSuccessful &&
      failingStatuses.isEmpty &&
      hasApprovedReview &&
      changeRequestAuthors.isEmpty;

  /// Whether the auto-merge label should be removed from this PR.
  bool get shouldRemoveLabel =>
      !hasApprovedReview ||
      changeRequestAuthors.isNotEmpty ||
      failingStatuses.isNotEmpty;

  /// An appropriate message to leave when removing the label.
  String get removalMessage {
    if (!shouldRemoveLabel) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        'This pull request is not suitable for automatic merging in its '
        'current state.');
    buffer.writeln();
    if (!hasApprovedReview && changeRequestAuthors.isEmpty) {
      buffer.writeln(
          '- Please get at least one approved review before re-applying this '
          'label. __Reviewers__: If you left a comment approving, please use '
          'the "approve" review action instead.');
    }
    for (String author in changeRequestAuthors) {
      buffer.writeln(
          '- This pull request has changes requested by @$author. Please '
          'resolve those before re-applying the label.');
    }
    for (String status in failingStatuses) {
      buffer.writeln(
          '- The status or check suite $status has failed. Please fix the '
          'issues identified (or deflake) before re-applying this label.');
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
        'changeRequestAuthors: $changeRequestAuthors, '
        'labelId: $labelId, '
        'shouldMerge: $shouldMerge}';
  }
}
