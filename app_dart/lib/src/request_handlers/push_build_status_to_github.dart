// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/github_build_status_update.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';

@immutable
class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
    @visibleForTesting BuildStatusServiceProvider buildStatusServiceProvider,
    @visibleForTesting this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        buildStatusServiceProvider = buildStatusServiceProvider ?? BuildStatusService.defaultProvider,
        assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;
  final BuildStatusServiceProvider buildStatusServiceProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  @override
  Future<Body> get() async {
    final Logging log = loggingProvider();
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusServiceProvider(datastore);
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GithubService githubService = await config.createGithubService(slug.owner, slug.name);

    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      return Body.empty;
    }

    // TODO(keyonghan): improve branch fetching logic, like using cache, https://github.com/flutter/flutter/issues/53108
    for (String branch in await config.flutterBranches) {
      final BuildStatus buildStatus = await buildStatusService.calculateCumulativeStatus(branch: branch);
      final GitHub github = githubService.github;
      final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
      log.debug('Computed build result of $buildStatus');
      // Insert build status to bigquery.
      await _insertBigquery(buildStatus, branch);
      final List<PullRequest> pullRequests = await githubService.listPullRequests(slug, branch);
      for (PullRequest pr in pullRequests) {
        final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);
        if (update.status != buildStatus.githubStatus) {
          log.debug('Updating status of ${slug.fullName}#${pr.number} from ${update.status}');
          final CreateStatus request = CreateStatus(buildStatus.githubStatus);
          request.targetUrl = 'https://flutter-dashboard.appspot.com/#/build';
          request.context = config.flutterBuild;
          if (buildStatus != BuildStatus.succeeded) {
            request.description = config.flutterBuildDescription;
          }

          try {
            await github.repositories.createStatus(slug, pr.head.sha, request);
            update.status = buildStatus.githubStatus;
            update.updates += 1;
            update.updateTimeMillis = DateTime.now().millisecondsSinceEpoch;
            updates.add(update);
          } catch (error) {
            log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
          }
        }
      }

      /// Whenever github status is updated, [update.updates] will be synchronized in
      /// datastore [GithubBuildStatusUpdate].
      await datastore.insert(updates);
      log.debug('Committed all updates');
    }

    return Body.empty;
  }

  Future<void> _insertBigquery(BuildStatus buildStatus, String branch) async {
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
        'Branch': branch,
      },
    });

    // Obtain [rows] to be inserted to [BigQuery].
    final TableDataInsertAllRequest request = TableDataInsertAllRequest.fromJson(<String, Object>{'rows': requestRows});

    try {
      await tabledataResourceApi.insertAll(request, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add build status to BigQuery: $ApiRequestError');
    }
  }
}
