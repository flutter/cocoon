// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/github_build_status_update.dart';
import '../request_handling/api_request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

@immutable
class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub({
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
    @visibleForTesting BuildStatusServiceProvider? buildStatusServiceProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusServiceProvider = buildStatusServiceProvider ?? BuildStatusService.defaultProvider;

  final BuildStatusServiceProvider buildStatusServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  static const String fullNameRepoParam = 'repo';

  @override
  Future<Body> get() async {
    if (authContext!.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      log.fine('GitHub statuses are not pushed from local dev environments');
      return Body.empty;
    }

    final String repository = request!.uri.queryParameters[fullNameRepoParam] ?? 'flutter/flutter';
    final RepositorySlug slug = RepositorySlug.full(repository);
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusServiceProvider(datastore);

    final BuildStatus status = (await buildStatusService.calculateCumulativeStatus(slug))!;
    await _insertBigquery(slug, status.githubStatus, Config.defaultBranch(slug), config);
    await _updatePRs(slug, status.githubStatus, datastore);
    log.fine('All the PRs for $repository have been updated with $status');

    return Body.empty;
  }

  Future<void> _updatePRs(RepositorySlug slug, String status, DatastoreService datastore) async {
    final GitHub github = await config.createGitHubClient(slug: slug);
    final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];
    await for (PullRequest pr in github.pullRequests.list(slug)) {
      // Tree status is only put on PRs merging into ToT.
      if (pr.base!.ref != Config.defaultBranch(slug)) {
        log.fine('This PR is not staged to land on ${Config.defaultBranch(slug)}, skipping.');
        continue;
      }
      final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);
      if (update.status != status) {
        log.fine('Updating status of ${slug.fullName}#${pr.number} from ${update.status} to $status');
        final CreateStatus request = CreateStatus(status);
        request.targetUrl = 'https://flutter-dashboard.appspot.com/#/build?repo=${slug.name}';
        request.context = 'tree-status';
        if (status != GithubBuildStatusUpdate.statusSuccess) {
          request.description = config.flutterBuildDescription;
        }
        try {
          await github.repositories.createStatus(slug, pr.head!.sha!, request);
          update.status = status;
          update.updates = (update.updates ?? 0) + 1;
          update.updateTimeMillis = DateTime.now().millisecondsSinceEpoch;
          updates.add(update);
        } catch (error) {
          log.severe('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
        }
      }
    }
    await datastore.insert(updates);
  }

  Future<void> _insertBigquery(RepositorySlug slug, String status, String branch, Config config) async {
    const String bigqueryTableName = 'BuildStatus';
    final Map<String, dynamic> bigqueryData = <String, dynamic>{
      'Timestamp': DateTime.now().millisecondsSinceEpoch,
      'Status': status,
      'Branch': branch,
      'Repo': slug.name,
    };
    await insertBigquery(bigqueryTableName, bigqueryData, await config.createTabledataResourceApi());
  }
}
