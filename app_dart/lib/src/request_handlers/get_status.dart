// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/commit.dart';
import '../service/build_status_service.dart';

final class GetStatus extends RequestHandler {
  const GetStatus({
    required super.config,
    required BuildStatusService buildStatusService,
    required FirestoreService firestore,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _now = now,
       _buildStatusService = buildStatusService,
       _firestore = firestore;

  final FirestoreService _firestore;
  final BuildStatusService _buildStatusService;
  final DateTime Function() _now;

  static const String kLastCommitShaParam = 'lastCommitSha';
  static const String kBranchParam = 'branch';
  static const String kRepoParam = 'repo';

  @override
  Future<Response> get(Request request) async {
    final lastCommitSha = request.uri.queryParameters[kLastCommitShaParam];

    final repoName =
        request.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final slug = RepositorySlug('flutter', repoName);
    final branch =
        request.uri.queryParameters[kBranchParam] ?? Config.defaultBranch(slug);
    final commitNumber = config.commitNumber;

    final DateTime lastCommitCreated;
    if (lastCommitSha != null) {
      final commit = await Commit.fromFirestoreBySha(
        _firestore,
        sha: lastCommitSha,
      );
      lastCommitCreated = DateTime.fromMillisecondsSinceEpoch(
        commit.createTimestamp,
      );
    } else {
      lastCommitCreated = _now();
    }

    final commits = await _buildStatusService.retrieveCommitStatusFirestore(
      limit: commitNumber,
      created: TimeRange.before(lastCommitCreated, exclusive: true),
      branch: branch,
      slug: slug,
    );

    return Response.json({
      'Commits': [
        ...commits.map((status) {
          return rpc_model.CommitStatus(
            commit: rpc_model.Commit(
              author: rpc_model.CommitAuthor(
                login: status.commit.author,
                avatarUrl: status.commit.avatar,
              ),
              branch: status.commit.branch,
              timestamp: status.commit.createTimestamp,
              sha: status.commit.sha,
              message: status.commit.message,
              repository: status.commit.repositoryPath,
            ),
            tasks: [
              ...status.collateTasksByTaskName().map((fullTask) {
                return rpc_model.Task(
                  attempts: fullTask.task.currentAttempt,
                  buildNumberList: fullTask.buildList,
                  builderName: fullTask.task.taskName,
                  createTimestamp: fullTask.task.createTimestamp,
                  startTimestamp: fullTask.task.startTimestamp,
                  endTimestamp: fullTask.task.endTimestamp,
                  isBringup: fullTask.task.bringup,
                  isFlaky:
                      fullTask.didAtLeastOneFailureOccur &&
                      fullTask.totalSubTasks > 1,
                  status: fullTask.task.status,
                  lastAttemptFailed: fullTask.lastCompletedAttemptWasFailure,
                  currentBuildNumber: fullTask.task.buildNumber,
                );
              }),
            ],
          );
        }),
      ],
    });
  }
}
