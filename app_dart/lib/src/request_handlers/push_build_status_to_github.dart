// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class PushBuildStatusToGithub extends ApiRequestHandler<Body> {
  const PushBuildStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      return Body.empty;
    }

    final DatastoreService datastore = datastoreProvider();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final Result trend = await _computeTrend(datastore);
    log.debug('Computed build result of ${trend.githubStatus}');
    if (trend == Result.buildWillFail || trend == Result.succeeded || trend == Result.failed) {
      final GitHub github = await config.createGitHubClient();
      final List<GithubBuildStatusUpdate> updates = <GithubBuildStatusUpdate>[];

      await for (PullRequest pr in github.pullRequests.list(slug)) {
        final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);

        if (update.status != trend.githubStatus) {
          log.debug('Updating status of ${slug.fullName}#${pr.number} from ${update.status}');
          final CreateStatus request = CreateStatus(trend.githubStatus);
          request.targetUrl = 'https://flutter-dashboard.appspot.com/build.html';
          request.context = 'flutter-build';
          if (trend != Result.succeeded) {
            request.description = 'Flutter build is currently broken. Please do not merge this '
                'PR unless it contains a fix to the broken build.';
          }

          try {
            await github.repositories.createStatus(slug, pr.head.sha, request);
            update.status = trend.githubStatus;
            update.updates += 1;
            updates.add(update);
          } catch (error) {
            log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
          }
        }
      }

      final int maxEntityGroups = config.maxEntityGroups;
      for (int i = 0; i < updates.length; i += maxEntityGroups) {
        await datastore.db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: updates.skip(i).take(maxEntityGroups).toList());
          await transaction.commit();
        });
      }
      log.debug('Committed all updates');
    }

    return Body.empty;
  }

  bool _isFinal(String status) {
    return status == Task.statusSucceeded ||
        status == Task.statusFailed ||
        status == Task.statusSkipped;
  }

  bool _isFailedOrSkipped(String status) {
    return status == Task.statusFailed || status == Task.statusSkipped;
  }

  Future<Result> _computeTrend(DatastoreService datastore) async {
    final Map<String, bool> checkedTasks = <String, bool>{};
    bool isLatestBuild = true;

    await for (BuildStatus status in _getBuildStatuses(datastore)) {
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          if (isLatestBuild) {
            // We only care about tasks defined in the latest build. If a task
            // is removed from CI, we no longer care about its status.
            checkedTasks[task.name] = false;
          }

          final bool isInLatestBuild = checkedTasks.containsKey(task.name);
          final bool checked = checkedTasks[task.name] ?? false;
          if (isInLatestBuild && !checked && (task.isFlaky || _isFinal(task.status))) {
            checkedTasks[task.name] = true;
            if (!task.isFlaky && _isFailedOrSkipped(task.status)) {
              return Result.buildWillFail;
            }
          }
        }
      }
      isLatestBuild = false;
    }

    if (checkedTasks.isEmpty) {
      return Result.buildWillFail;
    }

    return Result.succeeded;
  }

  Stream<BuildStatus> _getBuildStatuses(DatastoreService datastore) async* {
    await for (Commit commit in datastore.queryRecentCommits()) {
      final List<Stage> stages = await datastore.queryTasksGroupedByStage(commit);
      final Result result = _computeBuildResult(commit, stages);
      log.debug('For commit ${commit.sha}, yielding result of $result');
      yield BuildStatus(commit, stages, result);
    }
  }

  Result _computeBuildResult(Commit commit, List<Stage> stages) {
    int taskCount = 0;
    int pendingCount = 0;
    int inProgressCount = 0;
    int failedCount = 0;

    for (Stage stage in stages) {
      for (Task task in stage.tasks) {
        taskCount++;

        if (!task.isFlaky) {
          // Do not count flakes towards failures.
          continue;
        }

        switch (task.status) {
          case Task.statusFailed:
          case Task.statusSkipped:
            failedCount++;
            break;
          case Task.statusSucceeded:
            // Nothing to count. It's a success if there are zero failures.
            break;
          case Task.statusInProgress:
            inProgressCount++;
            pendingCount++;
            break;
          default:
            // Includes TaskNew and TaskNoStatus
            pendingCount++;
        }
      }
    }

    if (taskCount == 0) {
      // No tasks found at all. Something's wrong.
      return Result.failed;
    }

    if (pendingCount == 0) {
      // Build finished.
      if (failedCount > 0) {
        return Result.failed;
      }
      return Result.succeeded;
    } else if (inProgressCount == 0) {
      return Result.notStarted;
    }

    final int fourHours = const Duration(hours: 4).inMilliseconds;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - commit.timestamp > fourHours) {
      return Result.stuck;
    }

    if (failedCount > 0) {
      return Result.buildWillFail;
    }

    return Result.inProgress;
  }
}

@immutable
class BuildStatus {
  const BuildStatus(this.commit, this.stages, this.result);

  final Commit commit;
  final List<Stage> stages;
  final Result result;
}

class Result {
  const Result._(this.value);

  final String value;

  static const Result notStarted = Result._('notStarted');
  static const Result inProgress = Result._('inProgress');
  static const Result buildWillFail = Result._('buildWillFail');
  static const Result succeeded = Result._('succeeded');
  static const Result failed = Result._('failed');
  static const Result stuck = Result._('stuck');

  String get githubStatus => this == succeeded
      ? GithubBuildStatusUpdate.statusSuccess
      : GithubBuildStatusUpdate.statusFailure;

  @override
  String toString() => value;
}
