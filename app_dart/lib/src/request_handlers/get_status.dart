// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/firestore/commit.dart';
import '../model/firestore/commit_tasks_status.dart';
import '../model/firestore/task.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';

@immutable
final class GetStatus extends RequestHandler<Body> {
  const GetStatus({
    required super.config,
    required BuildStatusService buildStatusService,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _now = now,
       _buildStatusService = buildStatusService;

  final BuildStatusService _buildStatusService;
  final DateTime Function() _now;

  static const String kLastCommitShaParam = 'lastCommitSha';
  static const String kBranchParam = 'branch';
  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final lastCommitSha = request!.uri.queryParameters[kLastCommitShaParam];

    final repoName =
        request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final slug = RepositorySlug('flutter', repoName);
    final branch =
        request!.uri.queryParameters[kBranchParam] ??
        Config.defaultBranch(slug);
    final firestoreService = await config.createFirestoreService();
    final commitNumber = config.commitNumber;
    final lastCommitTimestamp =
        lastCommitSha != null
            ? (await Commit.fromFirestoreBySha(
              firestoreService,
              sha: lastCommitSha,
            )).createTimestamp
            : _now().millisecondsSinceEpoch;

    final commits =
        await _buildStatusService
            .retrieveCommitStatusFirestore(
              limit: commitNumber,
              timestamp: lastCommitTimestamp,
              branch: branch,
              slug: slug,
            )
            .map(_SerializableCommitStatus.new)
            .toList();

    return Body.forJson({'Commits': commits.map((e) => e.toJson()).toList()});
  }
}

// TODO(matanlurey): These are all temporary (private) classes that marshal
// these objects into the JSON format expected by the frontend, which we control
// e2e so they can evolve.
//
// It would be better to move the dashboard/lib/src/rpc_model into the
// packages/cocoon_common package, and then use that representation for both
// the frontend and backend (we're never going to deploy them independently).

final class _SerializableCommitStatus {
  const _SerializableCommitStatus(this.status);

  final CommitTasksStatus status;

  Map<String, Object?> toJson() {
    return {
      'Commit': _SerializableCommit(status.commit).toJson(),
      'Tasks': [...status.collateTasksByTaskName().map(_SerializableTask.new)],
      'Status': _determineCommitStatus(),
    };
  }

  // Partial copy from https://github.com/flutter/cocoon/blob/f220a6d764715499867ae7883aa24c040307e5f8/app_dart/lib/src/model/appengine/stage.dart#L143-L160.
  String _determineCommitStatus() {
    final fullTasks = status.collateTasksByTaskName();
    if (fullTasks.isEmpty) {
      return Task.statusInProgress;
    }
    if (fullTasks.every((t) => t.task.status == Task.statusSucceeded)) {
      return Task.statusSucceeded;
    }
    if (fullTasks.any((t) => Task.taskFailStatusSet.contains(t.task.status))) {
      return Task.statusFailed;
    }
    return Task.statusInProgress;
  }
}

final class _SerializableCommit {
  const _SerializableCommit(this.commit);

  final Commit commit;

  Map<String, Object?> toJson() {
    return {
      'FlutterRepositoryPath': commit.repositoryPath,
      'CreateTimestamp': commit.createTimestamp,
      'Sha': commit.sha,
      'Message': commit.message,
      'Author': {'Login': commit.author, 'avatar_url': commit.avatar},
      'Branch': commit.branch,
    };
  }
}

final class _SerializableTask {
  const _SerializableTask(this.task);

  final FullTask task;

  Map<String, Object?> toJson() {
    return {
      'CreateTimestamp': task.task.createTimestamp,
      'StartTimestamp': task.task.startTimestamp,
      'EndTimestamp': task.task.endTimestamp,
      'Attempts': task.task.attempts,
      'Flaky': task.task.testFlaky,
      'Status': task.task.status,
      'BuildNumberList': task.buildList.join(','),
      'BuilderName': task.task.taskName,
    };
  }
}
