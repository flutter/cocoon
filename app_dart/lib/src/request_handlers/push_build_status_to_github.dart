// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/github_build_status.dart';
import '../request_handling/api_request_handler.dart';
import '../service/big_query.dart';
import '../service/build_status_service.dart';

@immutable
final class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub({
    required super.config,
    required super.authenticationProvider,
    required BuildStatusService buildStatusService,
    required FirestoreService firestore,
    required BigQueryService bigQuery,
  }) : _buildStatusService = buildStatusService,
       _firestore = firestore,
       _bigQuery = bigQuery;

  final BuildStatusService _buildStatusService;
  final FirestoreService _firestore;
  final BigQueryService _bigQuery;

  static const _fullNameRepoParam = 'repo';

  @override
  Future<Body> get() async {
    if (authContext!.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      log.debug('GitHub statuses are not pushed from local dev environments');
      return Body.empty;
    }

    final repository =
        request!.uri.queryParameters[_fullNameRepoParam] ?? 'flutter/flutter';
    final slug = RepositorySlug.full(repository);
    final status = await _buildStatusService.calculateCumulativeStatus(slug);
    await _insertBigQuery(
      slug,
      status.githubStatus,
      Config.defaultBranch(slug),
      config,
    );
    await _updatePRs(slug, status.githubStatus, _firestore);
    log.debug('All the PRs for $repository have been updated with $status');

    return Body.empty;
  }

  Future<void> _updatePRs(
    RepositorySlug slug,
    String realStatus,
    FirestoreService firestoreService,
  ) async {
    final github = await config.createGitHubClient(slug: slug);
    final githubBuildStatuses = <GithubBuildStatus>[];
    await for (PullRequest pr in github.pullRequests.list(
      slug,
      base: Config.defaultBranch(slug),
    )) {
      // Tree status only affects the default branch - which github should filter for.. but check for a whoopsie.
      if (pr.base!.ref != Config.defaultBranch(slug)) {
        log.warn(
          'when asked for PRs for ${Config.defaultBranch(slug)} - github '
          'returns something else: $pr',
        );
        continue;
      }
      final githubBuildStatus = await firestoreService.queryLastBuildStatus(
        slug,
        pr.number!,
        pr.head!.sha!,
      );

      // Look at the labels on the PR to figure out if we need to turn a failing status into a neutral one.
      // This will have the side effect of flipping a neutral to (success|failure) if the emergency label is removed.
      final hasEmergencyLabel =
          pr.labels?.any((label) => label.name == Config.kEmergencyLabel) ??
          false;
      final status =
          (realStatus != GithubBuildStatus.statusSuccess && hasEmergencyLabel)
              ? GithubBuildStatus.statusNeutral
              : realStatus;
      if (githubBuildStatus.status != status) {
        log.log(
          severity: hasEmergencyLabel ? Severity.warning : Severity.debug,
          'Updating status of ${slug.fullName}#${pr.number} from '
          '${githubBuildStatus.status} to $status',
        );
        final request = CreateStatus(status);
        request.targetUrl =
            'https://flutter-dashboard.appspot.com/#/build?repo=${slug.name}';
        request.context = 'tree-status';
        if (status == GithubBuildStatus.statusNeutral) {
          request.description = config.flutterTreeStatusEmergency;
        } else if (status != GithubBuildStatus.statusSuccess) {
          request.description = config.flutterTreeStatusRed;
        }
        try {
          await github.repositories.createStatus(slug, pr.head!.sha!, request);
          final currentTimeMillisecondsSinceEpoch =
              DateTime.now().millisecondsSinceEpoch;

          githubBuildStatus.setStatus(status);
          githubBuildStatus.setUpdates(githubBuildStatus.updates + 1);
          githubBuildStatus.setUpdateTimeMillis(
            currentTimeMillisecondsSinceEpoch,
          );
          githubBuildStatuses.add(githubBuildStatus);
        } catch (e) {
          log.error(
            'Failed to post status update to ${slug.fullName}#${pr.number}',
            e,
          );
        }
      }
    }
    await updateGithubBuildStatusDocuments(githubBuildStatuses);
  }

  Future<void> updateGithubBuildStatusDocuments(
    List<GithubBuildStatus> githubBuildStatuses,
  ) async {
    if (githubBuildStatuses.isEmpty) {
      return;
    }
    final writes = documentsToWrites(githubBuildStatuses);
    await _firestore.batchWriteDocuments(
      BatchWriteRequest(writes: writes),
      kDatabase,
    );
  }

  Future<void> _insertBigQuery(
    RepositorySlug slug,
    String status,
    String branch,
    Config config,
  ) async {
    const bigqueryTableName = 'BuildStatus';
    final bigqueryData = <String, dynamic>{
      'Timestamp': DateTime.now().millisecondsSinceEpoch,
      'Status': status,
      'Branch': branch,
      'Repo': slug.name,
    };

    await insertBigQuery(bigqueryTableName, bigqueryData, _bigQuery.tabledata);
  }
}
