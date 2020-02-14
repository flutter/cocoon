// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/github_gold_status_update.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_value.dart';

typedef DatastoreServiceProvider = DatastoreService Function();

/// Service class for interacting with App Engine cloud datastore.
///
/// This service exists to provide an API for common datastore queries made by
/// the Cocoon backend.
@immutable
class DatastoreService {
  /// Creates a new [DatastoreService].
  ///
  /// The [db] argument must not be null.
  const DatastoreService({
    @required this.db,
  }) : assert(db != null);

  /// The backing [DatastoreDB] object. Guaranteed to be non-null.
  final DatastoreDB db;

  static DatastoreService defaultProvider() {
    return DatastoreService(db: dbService);
  }

  /// Queries for recent commits.
  ///
  /// The [limit] argument specifies the maximum number of commits to retrieve.
  ///
  /// The returned commits will be ordered by most recent [Commit.timestamp].
  Stream<Commit> queryRecentCommits({int limit = 100, int timestamp}) {
    timestamp ??= DateTime.now().millisecondsSinceEpoch;
    final Query<Commit> query = db.query<Commit>()
      ..limit(limit)
      ..order('-timestamp')
      ..filter('timestamp <', timestamp);
    return query.run();
  }

  /// queryRecentTimeSerialsValues fetches the latest benchmark results starting from
  /// [startFrom] and up to a given [limit].
  ///
  /// If startFrom is nil, starts from the latest available record.
  /// [startFrom] to be implemented...
  Stream<TimeSeriesValue> queryRecentTimeSeriesValues(TimeSeries timeSeries,
      {int limit = 1500, String startFrom}) {
    final Query<TimeSeriesValue> query =
        db.query<TimeSeriesValue>(ancestorKey: timeSeries.key)
          ..limit(limit)
          ..order('-createTimestamp');
    return query.run();
  }

  /// Queries for recent tasks that meet the specified criteria.
  ///
  /// Since each task belongs to a commit, this query implicitly includes a
  /// query of the most recent N commits (see [queryRecentCommits]). The
  /// [commitLimit] argument specifies how many commits to consider when
  /// retrieving the list of recent tasks.
  ///
  /// The [taskLimit] argument specifies how many tasks to retrieve for each
  /// commit that is considered.
  ///
  /// If [taskName] is specified, only tasks whose [Task.name] matches the
  /// specified value will be returned. By default, tasks will be returned
  /// regardless of their name.
  ///
  /// The returned tasks will be ordered by most recent [Commit.timestamp]
  /// first, then by most recent [Task.createTimestamp].
  Stream<FullTask> queryRecentTasks({
    String taskName,
    int commitLimit = 20,
    int taskLimit = 20,
  }) async* {
    assert(commitLimit != null);
    assert(taskLimit != null);
    await for (Commit commit in queryRecentCommits(limit: commitLimit)) {
      final Query<Task> query = db.query<Task>(ancestorKey: commit.key)
        ..limit(taskLimit)
        ..order('-createTimestamp');
      if (taskName != null) {
        query.filter('name =', taskName);
      }
      yield* query.run().map<FullTask>((Task task) => FullTask(task, commit));
    }
  }

  /// Finds all tasks owned by the specified [commit] and partitions them into
  /// stages.
  ///
  /// The returned list of stages will be ordered by the natural ordering of
  /// [Stage].
  Future<List<Stage>> queryTasksGroupedByStage(Commit commit) async {
    final Query<Task> query = db.query<Task>(ancestorKey: commit.key)
      ..order('-stageName');
    final Map<String, StageBuilder> stages = <String, StageBuilder>{};
    await for (Task task in query.run()) {
      if (!stages.containsKey(task.stageName)) {
        stages[task.stageName] = StageBuilder()
          ..commit = commit
          ..name = task.stageName;
      }
      stages[task.stageName].tasks.add(task);
    }
    final List<Stage> result = stages.values
        .map<Stage>((StageBuilder stage) => stage.build())
        .toList();
    return result..sort();
  }

  Future<GithubBuildStatusUpdate> queryLastStatusUpdate(
    RepositorySlug slug,
    PullRequest pr,
  ) async {
    final Query<GithubBuildStatusUpdate> query = db
        .query<GithubBuildStatusUpdate>()
          ..filter('repository =', slug.fullName)
          ..filter('pr =', pr.number)
          ..filter('head =', pr.head.sha);
    final List<GithubBuildStatusUpdate> previousStatusUpdates =
        await query.run().toList();

    if (previousStatusUpdates.isEmpty) {
      return GithubBuildStatusUpdate(
        repository: slug.fullName,
        pr: pr.number,
        head: pr.head.sha,
        status: null,
        updates: 0,
      );
    } else {
      if (previousStatusUpdates.length > 1) {
        throw StateError(
            'GithubBuildStatusUpdate should have no more than one entries on '
            'repository ${slug.fullName}, pr ${pr.number}, head ${pr.head.sha}');
      }
      return previousStatusUpdates.single;
    }
  }

  Future<GithubGoldStatusUpdate> queryLastGoldUpdate(
    RepositorySlug slug,
    PullRequest pr,
  ) async {
    final Query<GithubGoldStatusUpdate> query = db
        .query<GithubGoldStatusUpdate>()
          ..filter('repository =', slug.fullName)
          ..filter('pr =', pr.number);
    final List<GithubGoldStatusUpdate> previousStatusUpdates =
        await query.run().toList();

    if (previousStatusUpdates.isEmpty) {
      return GithubGoldStatusUpdate(
        pr: pr.number,
        head: null,
        status: null,
        updates: 0,
      );
    } else {
      if (previousStatusUpdates.length > 1) {
        throw StateError(
            'GithubGoldStatusUpdate should have no more than one entry on '
            'repository ${slug.fullName}, pr ${pr.number}.');
      }
      return previousStatusUpdates.single;
    }
  }
}
