// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/github_build_status_update.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';

@immutable
class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
    @visibleForTesting BuildStatusProvider buildStatusProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        buildStatusProvider =
            buildStatusProvider ?? const BuildStatusProvider(),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;
  final BuildStatusProvider buildStatusProvider;

  @override
  Future<Body> get() async {
    final Logging log = loggingProvider();
    final DatastoreService datastore = datastoreProvider();

    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      return Body.empty;
    }

    const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final BuildStatus buildStatus =
        await buildStatusProvider.calculateCumulativeStatus();
    final GitHub github = await config.createGitHubClient();
    final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
    log.debug('Computed build result of $buildStatus');

    // Insert build status to bigquery.
    await _insertBigquery(buildStatus);

    await for (PullRequest pr in github.pullRequests.list(slug)) {
      final GithubBuildStatusUpdate update =
          await datastore.queryLastStatusUpdate(slug, pr);

      if (update.status != buildStatus.githubStatus) {
        log.debug(
            'Updating status of ${slug.fullName}#${pr.number} from ${update.status}');
        final CreateStatus request = CreateStatus(buildStatus.githubStatus);
        request.targetUrl = 'https://flutter-dashboard.appspot.com/build.html';
        request.context = 'flutter-build';
        if (buildStatus != BuildStatus.succeeded) {
          request.description =
              'Flutter build is currently broken. Please do not merge this '
              'PR unless it contains a fix to the broken build.';
        }

        try {
          await github.repositories.createStatus(slug, pr.head.sha, request);
          update.status = buildStatus.githubStatus;
          update.updates += 1;
          updates.add(update);
        } catch (error) {
          log.error(
              'Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }

    final int maxEntityGroups = config.maxEntityGroups;
    for (int i = 0; i < updates.length; i += maxEntityGroups) {
      await datastore.db.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(
            inserts: updates.skip(i).take(maxEntityGroups).toList());
        await transaction.commit();
      });
    }
    log.debug('Committed all updates');

    return Body.empty;
  }

  Future<void> _insertBigquery(BuildStatus buildStatus) async {
    // Define const variables for [BigQuery] operations.
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'BuildStatus';

    final TabledataResourceApi tabledataResourceApi = await config.createTabledataResourceApi();
    final List<Map<String, Object>> requestRows = <Map<String, Object>>[];
    
    requestRows.add(<String, Object>{
      'json': <String, Object>{
        'Timestamp': DateTime.now().millisecondsSinceEpoch,
        'Status': buildStatus.value,
      },
    });

    // Obtain [rows] to be inserted to [BigQuery].
    final TableDataInsertAllRequest request =
      TableDataInsertAllRequest.fromJson(<String, Object>{
      'rows': requestRows
    });

    try {
      await tabledataResourceApi.insertAll(request, projectId, dataset, table);
    } catch(ApiRequestError){
      log.warning('Failed to add build status to BigQuery: $ApiRequestError');
    }
  }
}
