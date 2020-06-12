// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/luci/buildbucket.dart' as bb;
import '../model/luci/push_message.dart';
import 'luci_build_service.dart';

class GithubStatusService {
  const GithubStatusService(this.config, this.luciBuildService);

  /// The global configuration of this AppEngine server.
  final Config config;
  final LuciBuildService luciBuildService;

  Future<void> setBuildsPendingStatus(
      String repositoryName, int prNumber, String commitSha) async {
    final RepositorySlug slug = RepositorySlug('flutter', repositoryName);
    final GitHub gitHubClient = await config.createGitHubClient();
    final Map<String, bb.Build> builds = await luciBuildService
        .buildsForRepositoryAndPr(repositoryName, prNumber, commitSha);
    for (bb.Build build in builds.values) {
      final CreateStatus status = CreateStatus('pending')
        ..context = build.builderId.builder
        ..description = 'Flutter LUCI Build: ${build.builderId.builder}'
        ..targetUrl = '';
      await gitHubClient.repositories.createStatus(slug, commitSha, status);
    }
  }

  Future<void> setPendingStatus({
    @required String ref,
    @required String builderName,
    @required String buildUrl,
  }) async {
    final RepositorySlug slug = await config.repoNameForBuilder(builderName);
    // No builderName configuration, nothing to do here.
    if (slug == null) {
      return;
    }
    final GitHub gitHubClient = await config.createGitHubClient();
    // GitHub "only" allows setting a status for a context/ref pair 1000 times.
    // We should avoid unnecessarily setting a pending status, e.g. if we get
    // started and pending messages close together.
    // We have to check for both because sometimes one or the other might come
    // in.
    // However, we should keep going if the _most recent_ status is not pending.
    await for (RepositoryStatus status
        in gitHubClient.repositories.listStatuses(slug, ref)) {
      if (status.context == builderName) {
        if (status.state == 'pending' &&
            status.targetUrl.startsWith(buildUrl)) {
          return;
        }
        break;
      }
    }

    String updatedBuildUrl = '';
    if (buildUrl.isNotEmpty) {
      // If buildUrl is not empty then append a query parameter to refresh the page
      // content every 30 seconds. A resulting updatedBuild url will look like:
      // https://ci.chromium.org/p/flutter/builders/try/Linux%20Web%20Engine/5275?reload=30
      updatedBuildUrl =
          '$buildUrl${buildUrl.contains('?') ? '&' : '?'}reload=30';
    }
    final CreateStatus status = CreateStatus('pending')
      ..context = builderName
      ..description = 'Flutter LUCI Build: $builderName'
      ..targetUrl = updatedBuildUrl;
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }

  Future<void> setCompletedStatus({
    @required String ref,
    @required String builderName,
    @required String buildUrl,
    @required Result result,
  }) async {
    final RepositorySlug slug = await config.repoNameForBuilder(builderName);
    // No builderName configuration, nothing to do here.
    if (slug == null) {
      return;
    }
    final GitHub gitHubClient = await config.createGitHubClient();
    final CreateStatus status = statusForResult(result)
      ..context = builderName
      ..description = 'Flutter LUCI Build: $builderName'
      ..targetUrl = buildUrl;
    await gitHubClient.repositories.createStatus(slug, ref, status);
  }

  CreateStatus statusForResult(Result result) {
    switch (result) {
      case Result.canceled:
      case Result.failure:
        return CreateStatus('failure');
        break;
      case Result.success:
        return CreateStatus('success');
        break;
    }
    throw StateError('unreachable');
  }
}
