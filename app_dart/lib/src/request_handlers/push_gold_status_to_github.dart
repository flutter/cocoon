// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

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
  const PushGoldStatusToGithub(Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
  }) : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
       loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
       super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;

  @override
  Future<Body> get() async {
    final Logging log = loggingProvider();
    final DatastoreService datastore = datastoreProvider();

    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push gold status from the local dev server.
      return Body.empty;
    }

    const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GitHub githubClient = await config.createGitHubClient();
    final GraphQLClient cirrusClient = await config.createCirrusGraphQLClient();
    final List<GithubGoldStatusUpdate> statusUpdates = <GithubGoldStatusUpdate>[];
    final List<String> cirrusCheckStatuses = <String>[];
    const List<String> cirrusInProgressStates = <String>[
      'EXECUTING',
      'CREATED',
      'TRIGGERED',
      'NEEDS_APPROVAL'
    ];


    await for (PullRequest pr in githubClient.pullRequests.list(slug)) {
      // Check run statuses for this pr
      for (dynamic runStatus in await _queryGraphQL(
        pr.id.toString(),
        pr.head.sha,
        cirrusClient,
      )) {
        final String status = runStatus['status'];
        final String taskName = runStatus['name'];

        log.debug('Found Cirrus build status for pull request ${pr.id}, commit '
          '${pr.head.sha}: $taskName ($status)');

        if (taskName.contains('framework'))
          cirrusCheckStatuses.add(status);
      }

      if (cirrusCheckStatuses.isEmpty)
        return Body.empty;

      // This PR needs a Gold Status
      // Get last known Gold status from datastore
      final GithubGoldStatusUpdate lastUpdate =
        await datastore.queryLastGoldUpdate(slug, pr);
      CreateStatus statusRequest;

      log.debug('Last known Gold status for ${pr.id} was with sha '
        '${lastUpdate.head}, status: ${lastUpdate.status ?? 'initial'}');

      if (cirrusCheckStatuses.any(cirrusInProgressStates.contains)) {
        // Checks have not completed uploading to Gold
        log.debug('Checks for ${pr.id} at ${pr.head.sha} are still running.');

        if (lastUpdate.status == GithubGoldStatusUpdate.statusRunning)
          return Body.empty;
        
        else {
          // Set up running status for github.
          statusRequest = CreateStatus(GithubGoldStatusUpdate.statusRunning);
          statusRequest.targetUrl = 'https://flutter-gold.skia.org/changelists';
          statusRequest.context = 'flutter-gold';
          statusRequest.description = 'This check is waiting for framework '
            'checks to be completed';
        }
      } else {
        // Checks have completed
        final String status = await _getGoldStatus(pr, log);
        if (lastUpdate.head != pr.head.sha || lastUpdate.status != status) {
          // Set up status for github.
          statusRequest = CreateStatus(status);
          statusRequest.targetUrl = 'https://flutter-gold.skia.org/changelists';
          statusRequest.context = 'flutter-gold';

          switch (status) {
            case GithubGoldStatusUpdate.statusRunning:
              statusRequest.description = 'Image changes have been found for '
                'this pr. Visit https://flutter-gold.skia.org/changelists to '
                'view and triage (e.g. because this is an intentional change).';
              // TODO(Piinks): Comment on pr that golden file changes have been detected
              break;
            case GithubGoldStatusUpdate.statusCompleted:
              statusRequest.description = 'All golden file tests have passed.';
              break;
          }
        }
      }

      if (statusRequest != null) {
        try {
          await githubClient.repositories.createStatus(slug, pr.head.sha, statusRequest);
          lastUpdate.status = statusRequest.state;
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

  /// Used to check for any tryjob results from Flutter Gold associated with a PR.
  Future<String> _getGoldStatus(PullRequest pr, Logging log) async {
      final Uri requestForTryjobStatus = Uri.parse(
        'http://flutter-gold.skia.org/json/changelist/github/${pr.id}/${pr.head.sha}/untriaged'
    );
    String rawResponse;
    try {
      final io.HttpClient httpClient = io.HttpClient();
      final io.HttpClientRequest request = await httpClient.getUrl(requestForTryjobStatus);
      final io.HttpClientResponse response = await request.close();

      rawResponse = await utf8.decodeStream(response);
      final Map<String, dynamic> decodedResponse = json.decode(rawResponse);

      if (decodedResponse['digests'] == null) {

        log.debug('There are no unexpected image results for ${pr.id} at sha '
          '${pr.head.sha}, returning status ${GithubGoldStatusUpdate.statusCompleted}');

        return GithubGoldStatusUpdate.statusCompleted;
      } else {

        log.debug('Tryjob for ${pr.id} at sha ${pr.head.sha} generated new '
          'images, returning status ${GithubGoldStatusUpdate.statusRunning}');

        return GithubGoldStatusUpdate.statusRunning;
      }
    } on FormatException catch (_) {
      throw BadRequestException('Formatting error detected requesting '
        'tryjob status for pr ${pr.id} from Flutter Gold.\n'
        'rawResponse: $rawResponse');
    } catch (e) {
      throw BadRequestException('Error detected requesting tryjob status for pr '
        '${pr.id} from Flutter Gold.\n'
        'error: $e');
    }
  }
}

