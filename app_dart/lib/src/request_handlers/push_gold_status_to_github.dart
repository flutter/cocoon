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
import 'refresh_cirrus_status.dart';

@immutable
class PushGoldStatusToGithub extends ApiRequestHandler<Body> {
  PushGoldStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
    HttpClient goldClient,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        goldClient = goldClient ?? HttpClient(),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;
  final HttpClient goldClient;

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
    final List<GithubGoldStatusUpdate> statusUpdates =
        <GithubGoldStatusUpdate>[];
    final List<String> cirrusCheckStatuses = <String>[];

    await for (PullRequest pr in gitHubClient.pullRequests.list(slug)) {
      log.debug('Querying pull request ${pr.number}...');
      cirrusCheckStatuses.clear();
      // Query current checks for this pr.
      final List<dynamic> cirrusChecks =
          await queryCirrusGraphQL(pr.head.sha, cirrusClient, log, 'flutter');
      for (dynamic check in cirrusChecks) {
        final String status = check['status'];
        final String taskName = check['name'];

        log.debug(
            'Found Cirrus build status for pull request ${pr.number}, commit '
            '${pr.head.sha}: $taskName ($status)');

        cirrusCheckStatuses.add(status);
      }

      // Get last known Gold status from datastore.
      final GithubGoldStatusUpdate lastUpdate =
          await datastore.queryLastGoldUpdate(slug, pr);
      CreateStatus statusRequest;

      log.debug('Last known Gold status for ${pr.number} was with sha: '
          '${lastUpdate.head}, status: ${lastUpdate.status}');

      if (lastUpdate.status == GithubGoldStatusUpdate.statusCompleted &&
          lastUpdate.head == pr.head.sha) {
        log.debug('Completed status already reported for this commit.');
        // We have already seen this commit and it is completed.
        continue;
      }

      if (cirrusCheckStatuses.any(kCirrusInProgressStates.contains)) {
        // Checks are still running, we have to wait.
        log.debug('Waiting for checks to be completed.');
        statusRequest = _createStatus(GithubGoldStatusUpdate.statusRunning,
            'This check is waiting for all other checks to be completed.');
      } else {
        // Get Gold status.
        final String goldStatus = await _getGoldStatus(pr, log);
        statusRequest =
            _createStatus(goldStatus, _getStatusDescription(goldStatus));
        if (goldStatus == GithubGoldStatusUpdate.statusRunning &&
            !await _alreadyCommented(gitHubClient, pr, slug)) {
          log.debug('Notifying for triage.');
          await _commentAndApplyGoldLabel(gitHubClient, pr, slug);
        }
      }

      // Push updates if there is a status change (detected by unique description)
      // or this is a new commit.
      if (lastUpdate.description != statusRequest.description ||
          lastUpdate.head != pr.head.sha) {
        try {
          log.debug(
              'Pushing status to GitHub: ${statusRequest.state}, ${statusRequest.description}');
          await gitHubClient.repositories
              .createStatus(slug, pr.head.sha, statusRequest);
          lastUpdate.status = statusRequest.state;
          lastUpdate.head = pr.head.sha;
          lastUpdate.updates += 1;
          lastUpdate.description = statusRequest.description;
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

  /// Returns a GitHub Status for the given state and description.
  CreateStatus _createStatus(String state, String description) {
    final CreateStatus statusUpdate = CreateStatus(state)
      ..targetUrl = 'https://flutter-gold.skia.org/changelists'
      ..context = 'flutter-gold'
      ..description = description;
    return statusUpdate;
  }

  /// Used to check for any tryjob results from Flutter Gold associated with a
  /// pull request.
  Future<String> _getGoldStatus(PullRequest pr, Logging log) async {
    // We wait for a few seconds in case tests _just_ finished and the tryjob
    // has not finished ingesting the results.
    await Future<void>.delayed(const Duration(seconds: 10));
    final Uri requestForTryjobStatus = Uri.parse(
        'http://flutter-gold.skia.org/json/changelist/github/${pr.number}/${pr.head.sha}/untriaged');
    String rawResponse;
    try {
      final HttpClientRequest request =
          await goldClient.getUrl(requestForTryjobStatus);
      final HttpClientResponse response = await request.close();

      rawResponse = await utf8.decodeStream(response);
      final Map<String, dynamic> decodedResponse = json.decode(rawResponse);

      if (decodedResponse['digests'] == null) {
        log.debug(
            'There are no unexpected image results for ${pr.number} at sha '
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
      throw BadRequestException(
          'Error detected requesting tryjob status for pr '
          '${pr.number} from Flutter Gold.\n'
          'error: $e');
    }
  }

  String _getStatusDescription(String status) {
    if (status == GithubGoldStatusUpdate.statusRunning) {
      return 'Image changes have been found for '
          'this pull request. Visit https://flutter-gold.skia.org/changelists '
          'to view and triage (e.g. because this is an intentional change).';
    }
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
            'to view and triage (e.g. because this is an intentional change).\n\n' +
        config.goldenBreakingChangeMessage +
        '\n\n' +
        '_Changes reported for pull request ${pr.number} at sha ${pr.head.sha}_\n\n';
    await gitHubClient.issues.createComment(slug, pr.number, body);
    await gitHubClient.issues.addLabelsToIssue(slug, pr.number, <String>[
      'will affect goldens',
      'severe: API break',
      // TODO(Piinks): Add CQ+1 label when https://github.com/flutter/flutter/pull/49815
      // lands to keep everything in sync across both CIs. The comment feedback
      // will need to reflect that the Luci checks will need to run and be
      // triaged as well.
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
          'Changes reported for pull request ${pr.number} at sha ${pr.head.sha}')) {
        return true;
      }
    }
    return false;
  }
}
