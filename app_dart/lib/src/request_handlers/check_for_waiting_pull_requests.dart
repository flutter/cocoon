// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonEncode;

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:github/server.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

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

    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      return Body.empty;
    }

    await _checkPRs(log, RepositorySlug('flutter', 'flutter'));
    await _checkPRs(log, RepositorySlug('flutter', 'engine'));

    return Body.empty;
  }

  Future<void> _checkPRs(Logging log, RepositorySlug slug) async {
    final Map<String, dynamic> data = await _queryGraphQL(slug, log);
    for (_AutoMergeQueryResult queryResult in _parseQueryData(data)) {
      if (queryResult.shouldMerge) {
        await _mergePullRequest(
          log,
          RepositorySlug('flutter', 'flutter'),
          queryResult.number,
          queryResult.sha,
        );
      } else if (queryResult.shouldRemoveLabel) {
        await _removeLabel(
          slug,
          queryResult.number,
          queryResult.removalMessage,
        );
      } else {
        log.debug('Pull Request could be merged but tree is red: $queryResult');
      }
    }
  }

  Future<Map<String, dynamic>> _queryGraphQL(RepositorySlug slug, Logging log) async {
    final HttpLink _httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final String token = await config.githubOAuthToken;
    final AuthLink _authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final Link _link = _authLink.concat(_httpLink);

    final GraphQLClient _client = GraphQLClient(
      cache: InMemoryCache(),
      link: _link,
    );

    final String graphQLDocument = await _graphQLDocumentForSlug(slug);

    final QueryResult result = await _client.query(
      QueryOptions(
        document: graphQLDocument,
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasErrors) {
      log.error(jsonEncode(result.errors));
      throw const InternalServerError();
    }

    return result.data;
  }

  Future<String> _graphQLDocumentForSlug(RepositorySlug slug) async {
    final String labelName = await config.waitingForTreeToGoGreenLabelName;
    return '''query {
repository(owner: "${slug.owner}", name: "${slug.name}") {
  pullRequests(labels: "$labelName", first: 100, states: OPEN) {
    nodes {
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
}}''';
  }

  Future<void> _removeLabel(
    RepositorySlug slug,
    int number,
    String message,
  ) async {
    final GitHub client = await config.createGitHubClient();
    await client.issues.createComment(slug, number, message);
    await client.issues.removeLabelForIssue(
      slug,
      number,
      await config.waitingForTreeToGoGreenLabelName,
    );
  }

  Future<void> _mergePullRequest(
    Logging log,
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
        log.error('Failed to merge PR $number due to merge conflict.');
        throw const BadRequestException();
        break;
      case 405:
      default:
        log.error(
            'Failed to with merge with status code ${response.statusCode}: ${response.body}.');
        throw const BadRequestException();
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
    return repository['pullRequests']['nodes']
        .cast<Map<String, dynamic>>()
        .map<_AutoMergeQueryResult>((Map<String, dynamic> pullRequest) {
      final int number = pullRequest['number'];
      final bool mergeable = pullRequest['mergeable'] != 'MERGEABLE';
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
      final Map<String, dynamic> commit =
          pullRequest['commits']['nodes'].single['commit'];
      final String sha = commit['oid'];
      final bool ciSuccessful = commit['status']['state'] == 'SUCCESS';

      return _AutoMergeQueryResult(
        ciSuccessful: ciSuccessful,
        hasApprovedReview: hasApproval,
        hasChangesRequested: hasChangesRequested,
        mergeable: mergeable,
        number: number,
        sha: sha,
      );
    }).toList();
  }
}

/// A model class describing the state of a pull request that has the "waiting
/// for tree to go green" label on it.
@immutable
class _AutoMergeQueryResult {
  const _AutoMergeQueryResult({
    @required this.hasApprovedReview,
    @required this.hasChangesRequested,
    @required this.mergeable,
    @required this.ciSuccessful,
    @required this.number,
    @required this.sha,
  })  : assert(hasApprovedReview != null),
        assert(hasChangesRequested != null),
        assert(mergeable != null),
        assert(ciSuccessful != null),
        assert(number != null),
        assert(sha != null);

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

  /// Whether it is sane to automatically merge this PR.
  bool get shouldMerge =>
      ciSuccessful && mergeable && hasApprovedReview && !hasChangesRequested;

  /// Whether the auto-merge label should be removed from this PR.
  bool get shouldRemoveLabel =>
      !mergeable || !hasApprovedReview || hasChangesRequested;

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
    if (!mergeable) {
      buffer.writeln(
          '- Please resolve merge conflicts before re-applying this label.');
    }
    if (!hasApprovedReview) {
      buffer.writeln(
          '- Please get at least one approved review before re-applying this '
          'label. __Reviewers__: If you left a comment approving, please use '
          'the "approve" review action instead.');
    }
    if (hasChangesRequested) {
      buffer.writeln(
          '- This pull request has changes requested. Please resolve those '
          'before re-applying the label.');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return '$runtimeType{PR#$number, '
        'sha: $sha, '
        'ciSuccessful: $ciSuccessful, '
        'hasApprovedReview: $hasApprovedReview, '
        'hasChangesRequested: $hasChangesRequested, '
        'mergeable: $mergeable, '
        'shouldMerge: $shouldMerge}';
  }
}
