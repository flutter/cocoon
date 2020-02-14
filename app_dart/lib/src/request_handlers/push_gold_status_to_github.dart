// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/github_gold_status_update.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class PushGoldStatusToGithub extends ApiRequestHandler<Body> {
  PushGoldStatusToGithub(Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
    HttpClient goldClient,
  }) : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
       loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
       goldClient = goldClient ?? HttpClient(),
       super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;
  final HttpClient goldClient;

  static const String kTargetUrl = 'https://flutter-gold.skia.org/changelists';
  static const String kContext = 'flutter-gold';

  @override
  Future<Body> get() async {
    final Logging log = loggingProvider();
    final DatastoreService datastore = datastoreProvider();

    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push gold status from the local dev server.
      return Body.empty;
    }

    const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GitHub gitHubClient = await config.createGitHubClient();
    final GraphQLClient cirrusClient = await config.createCirrusGraphQLClient();
    final List<GithubGoldStatusUpdate> statusUpdates = <GithubGoldStatusUpdate>[];
    final List<String> cirrusCheckStatuses = <String>[];
    const List<String> cirrusInProgressStates = <String>[
      'EXECUTING',
      'CREATED',
      'TRIGGERED',
      'NEEDS_APPROVAL'
    ];


    await for (PullRequest pr in gitHubClient.pullRequests.list(slug)) {
      // Check run statuses for this pr
      for (dynamic runStatus in await _queryGraphQL(
        pr.number.toString(),
        pr.head.sha,
        cirrusClient,
      )) {
        final String status = runStatus['status'];
        final String taskName = runStatus['name'];

        log.debug('Found Cirrus build status for pull request ${pr.number}, commit '
          '${pr.head.sha}: $taskName ($status)');

        if (taskName.contains('framework'))
          cirrusCheckStatuses.add(status);
      }

      // Is there a framework test? (Generates gold tryjobs)
      if (cirrusCheckStatuses.isEmpty)
        return Body.empty;

      // This PR needs a Gold Status
      // Get last known Gold status from datastore
      final GithubGoldStatusUpdate lastUpdate =
        await datastore.queryLastGoldUpdate(slug, pr);
      CreateStatus statusRequest;

      log.debug('Last known Gold status for ${pr.number} was with sha '
        '${lastUpdate?.head ?? 'initial'}, status: ${lastUpdate?.status ?? 'initial'}');

      if (lastUpdate.head == null || lastUpdate.head != pr.head.sha){
        // This is a new commit.
        log.debug('Creating Gold status for new commit ${pr.head.sha} for pull '
          'request #${pr.number}.');

        if (cirrusCheckStatuses.any(cirrusInProgressStates.contains)) {
          // Checks are still running
          log.debug('Status: running, checks are not completed.');
          statusRequest = CreateStatus(GithubGoldStatusUpdate.statusRunning);
          statusRequest.targetUrl = kTargetUrl;
          statusRequest.context = kContext;
          statusRequest.description = 'This check is waiting for framework '
            'checks to be completed.';
        } else {
          // Checks are completed.
          // Get gold status.
          final String status = await _getGoldStatus(pr, log);
          log.debug('Checks are completed, Gold reports $status status for '
            '${pr.number} sha ${pr.head.sha}.');
          statusRequest = CreateStatus(status);
          statusRequest.targetUrl = kTargetUrl;
          statusRequest.context = kContext;
          statusRequest.description = _getStatusDescription(status);
          if (status == GithubGoldStatusUpdate.statusRunning) {
            log.debug('Notifying for triage.');
            await _commentAndApplyGoldLabel(gitHubClient, pr, slug);
          }
        }
      } else {
        // We have seen this commit before.
        // If checks are still running, or last update was green, do nothing.
        if (cirrusCheckStatuses.any(cirrusInProgressStates.contains)
          || lastUpdate.status == GithubGoldStatusUpdate.statusCompleted)
          return Body.empty;

        // Check Gold for new status and update.
        final String status = await _getGoldStatus(pr, log);
        log.debug('Checks are completed, Gold reports $status status for '
          '${pr.number} sha ${pr.head.sha}.');
        if (lastUpdate.status != status) {
          // The 'running' state is used when the check is waiting and when
          // triage is needed, so if it is already 'running' we don't need to
          // update it. The comment feature below alerts the author that the
          // result needs to be addressed.
          statusRequest = CreateStatus(status);
          statusRequest.targetUrl = kTargetUrl;
          statusRequest.context = kContext;
          statusRequest.description = _getStatusDescription(status);
        }
        if (status == GithubGoldStatusUpdate.statusRunning
          && !await _alreadyCommented(gitHubClient, pr, slug)) {
          log.debug('Notifying for triage.');
          await _commentAndApplyGoldLabel(gitHubClient, pr, slug);
        }
      }

      if (statusRequest != null) {
        try {
          await gitHubClient.repositories.createStatus(slug, pr.head.sha, statusRequest);
          lastUpdate.status = statusRequest.state;
          lastUpdate.head = pr.head.sha;
          lastUpdate.updates += 1;
          statusUpdates.add(lastUpdate);
        } catch (error) {
          log.error(
            'Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }

    final int maxEntityGroups = config.maxEntityGroups;
    for (int i = 0; i < statusUpdates.length; i += maxEntityGroups) {
      await datastore.db.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(
          inserts: statusUpdates.skip(i).take(maxEntityGroups).toList());
        await transaction.commit();
      });
    }
    log.debug('Committed all updates');
    return Body.empty;
  }

  /// Queries the Cirrus GraphQL for build information for the given pr and sha.
  Future<List<dynamic>> _queryGraphQL(
    String pr,
    String sha,
    GraphQLClient client,
  ) async {
    const String owner = 'flutter';
    const String name = 'flutter';
    const String cirrusStatusQuery = r'''
    query BuildBySHAQuery($owner: String!, $name: String!, $SHA: String) { 
      searchBuilds(repositoryOwner: $owner, repositoryName: $name, SHA: $SHA) {
        pullRequest(first: 1, query: $PR) { 
          id latestGroupTasks { 
            id name status 
          }
        } 
      } 
    }''';
    final QueryResult result = await client.query(
      QueryOptions(
        document: cirrusStatusQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'owner': owner,
          'name': name,
          'SHA': sha,
          'PR': pr,
        },
      ),
    );

    if (result.hasErrors) {
      for (GraphQLError error in result.errors) {
        log.error(error.toString());
      }
      throw const BadRequestException('GraphQL query failed');
    }

    final List<dynamic> tasks = <dynamic>[];
    final Map<String, dynamic> searchBuilds = result.data['searchBuilds'].first;
    tasks.addAll(searchBuilds['latestGroupTasks']);
    return tasks;
  }

  /// Used to check for any tryjob results from Flutter Gold associated with a
  /// pull request.
  Future<String> _getGoldStatus(PullRequest pr, Logging log) async {
    // We wait for a few seconds in case tests _just_ finished and the tryjob
    // has not finished ingesting the results.
    await Future<void>.delayed(const Duration(seconds: 10));
      final Uri requestForTryjobStatus = Uri.parse(
        'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged'
    );
    String rawResponse;
    try {
      final HttpClientRequest request = await goldClient.getUrl(requestForTryjobStatus);
      final HttpClientResponse response = await request.close();

      rawResponse = await utf8.decodeStream(response);
      final Map<String, dynamic> decodedResponse = json.decode(rawResponse);

      if (decodedResponse['digests'] == null) {

        log.debug('There are no unexpected image results for ${pr.number} at sha '
          '${pr.head.sha}, returning status ${GithubGoldStatusUpdate.statusCompleted}');

        return GithubGoldStatusUpdate.statusCompleted;
      } else {

        log.debug('Tryjob for ${pr.number} at sha ${pr.head.sha} generated new '
          'images, returning status ${GithubGoldStatusUpdate.statusRunning}');

        return GithubGoldStatusUpdate.statusRunning;
      }
    } on FormatException catch (_) {
      throw BadRequestException('Formatting error detected requesting '
        'tryjob status for pr ${pr.number} from Flutter Gold.\n'
        'rawResponse: $rawResponse');
    } catch (e) {
      throw BadRequestException('Error detected requesting tryjob status for pr '
        '${pr.number} from Flutter Gold.\n'
        'error: $e');
    }
  }

  String _getStatusDescription(String status) {
    if (status == GithubGoldStatusUpdate.statusRunning)
        return 'Image changes have been found for '
          'this pr. Visit https://flutter-gold.skia.org/changelists to '
          'view and triage (e.g. because this is an intentional change).';
    return 'All golden file tests have passed.';
  }

  /// Creates a comment on a given pull request identified to have golden file
  /// changes and applies the `will affect goldens` label.
  Future<void> _commentAndApplyGoldLabel(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
  ) async {
    final String body = 'Golden image changes have been found for this pull '
      'request. Click [here](https://flutter-gold.skia.org/search?issue=${pr.number}&new_clstore=true) '
      'to view and triage (e.g. because this is an intentional change).\n\n'
      + config.goldenBreakingChangeMessage + '\n\n'
      + '_Changes reported for pull request ${pr.number} at sha ${pr.head.sha}_\n\n';
    await gitHubClient.issues.createComment(slug, pr.number, body);
    await gitHubClient.issues
      .addLabelsToIssue(slug, pr.number, <String>[
        'will affect goldens',
        'severe: API break',
      ]);
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
  ) async {
    final Stream<IssueComment> comments =
      gitHubClient.issues.listCommentsByIssue(slug, pr.number);
    await for (IssueComment comment in comments) {
      if (comment.body.contains(
        'Changes reported for pull request ${pr.number} at sha ${pr.head.sha}'
      )) {
        return true;
      }
    }
    return false;
  }
}
