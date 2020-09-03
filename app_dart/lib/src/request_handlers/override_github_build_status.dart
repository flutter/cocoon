// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/github_tree_status_override.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';

@immutable
class OverrideGitHubBuildStatus extends ApiRequestHandler<Body> {
  const OverrideGitHubBuildStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;

  static const String repositoryKeyName = 'repository';
  static const String closedKeyName = 'closed';
  static const String reasonKeyName = 'reason';
  static const String forceKeyName = 'force';

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final List<GithubTreeStatusOverride> overrides =
        await datastore.db.query<GithubTreeStatusOverride>().run().toList();

    return Body.forJson(overrides);
  }

  @override
  Future<Body> put() async {
    if (authContext.email == null) {
      throw const Forbidden();
    }

    final String repository = requestData[repositoryKeyName] as String;
    final bool closed = requestData[closedKeyName] as bool;
    final String reason = requestData[reasonKeyName] as String;
    final bool force = requestData.containsKey(forceKeyName) && requestData[forceKeyName] as bool;

    if (repository == null || closed == null || reason == null) {
      throw const BadRequestException();
    }

    final DatastoreService datastore = datastoreProvider(config.db);
    final Query<GithubTreeStatusOverride> query = datastore.db.query<GithubTreeStatusOverride>()
      ..filter('repository =', repository)
      ..limit(1);
    final GithubTreeStatusOverride currentOverride = await query.run().single;

    if (force || currentOverride.closed != closed) {
      currentOverride.closed = closed;
      currentOverride.user = authContext.email;
      currentOverride.reason = reason;
      await _updateGitHub(RepositorySlug.full(repository), closed, reason);
      await datastore.insert(<GithubTreeStatusOverride>[currentOverride]);
    }
    request.response.statusCode = HttpStatus.noContent;
    return Body.empty;
  }

  Future<void> _updateGitHub(RepositorySlug slug, bool closed, String reason) async {
    final Logging log = loggingProvider();
    final GithubService githubService = await config.createGithubService(slug.owner, slug.name);
    for (PullRequest pr in await githubService.listPullRequests(slug, 'master')) {
      log.debug('Updating tree status of ${slug.fullName}#${pr.number} (closed = $closed)');
      final CreateStatus request =
          CreateStatus(closed ? GithubBuildStatusUpdate.statusFailure : GithubBuildStatusUpdate.statusSuccess)
            ..targetUrl = 'https://flutter-dashboard.appspot.com/api/override-github-build-status'
            ..context = 'tree-status'
            ..description = reason;

      try {
        await githubService.github.repositories.createStatus(slug, pr.head.sha, request);
      } catch (error) {
        log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
      }
    }
  }
}
