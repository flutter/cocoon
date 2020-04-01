// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:gcloud/datastore.dart' as gcloud_datastore;
import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';
import 'package:grpc/grpc.dart';
import 'package:retry/retry.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/github_gold_status_update.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';
import '../model/appengine/time_series.dart';
import '../model/appengine/time_series_value.dart';

/// Function signature for a [DatastoreService] provider.
typedef DatastoreServiceProvider = DatastoreService Function(
    {DatastoreDB db, int maxEntityGroups});

/// Function signature that will be executed with retries.
typedef RetryHandler = Function();

/// Runs a db transaction with retries.
///
/// It uses quadratic backoff starting with 50ms and 3 max attempts.
Future<void> runTransactionWithRetries(RetryHandler retryHandler,
    {int delayMilliseconds = 50, int maxAttempts = 3}) {
  final RetryOptions r = RetryOptions(
      delayFactor: Duration(milliseconds: delayMilliseconds),
      maxAttempts: maxAttempts);
  return r.retry(
    retryHandler,
    retryIf: (Exception e) =>
        e is gcloud_datastore.TransactionAbortedError || e is GrpcError,
  );
}

/// Service class for interacting with App Engine cloud datastore.
///
/// This service exists to provide an API for common datastore queries made by
/// the Cocoon backend.
@immutable
class DatastoreService {
  /// Creates a new [DatastoreService].
  ///
  /// The [db] argument must not be null.
  const DatastoreService(
    this.db,
    this.maxEntityGroups,
  ) : assert(db != null, maxEntityGroups != null);

  /// Maximum number of entity groups to process at once.
  final int maxEntityGroups;

  /// The backing [DatastoreDB] object. Guaranteed to be non-null.
  final DatastoreDB db;

  /// Creates and returns a [DatastoreService] using [db] and [maxEntityGroups].
  static DatastoreService defaultProvider(
      {DatastoreDB db, int maxEntityGroups}) {
    return DatastoreService(db ?? dbService, maxEntityGroups ?? 5);
  }

  /// Queries for recent commits.
  ///
  /// The [limit] argument specifies the maximum number of commits to retrieve.
  ///
  /// The returned commits will be ordered by most recent [Commit.timestamp].
  Stream<Commit> queryRecentCommits(
      {int limit = 100, int timestamp, String branch}) {
    timestamp ??= DateTime.now().millisecondsSinceEpoch;
    branch ??= 'master';
    final Query<Commit> query = db.query<Commit>()
      ..limit(limit)
      ..filter('branch =', branch)
      ..order('-timestamp')
      ..filter('timestamp <', timestamp);
    return query.run();
  }

  // Queries for recent commits without considering branches.
  // TODO(keyonghan): combine this function with the above `queryRecentCommits`,
  // this needs to fix https://github.com/flutter/flutter/issues/52694.
  Stream<Commit> queryRecentCommitsNoBranch({int limit = 100, int timestamp}) {
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
  Stream<FullTask> queryRecentTasks(
      {String taskName,
      int commitLimit = 20,
      int taskLimit = 20,
      String branch = 'master'}) async* {
    assert(commitLimit != null);
    assert(taskLimit != null);
    await for (Commit commit
        in queryRecentCommits(limit: commitLimit, branch: branch)) {
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
        head: '',
        status: '',
        updates: 0,
        description: '',
        repository: slug.fullName,
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

  /// Shards [rows] into several sublists of size [maxEntityGroups].
  Future<List<List<Model>>> shard(List<Model> rows) async {
    final List<List<Model>> shards = <List<Model>>[];
    for (int i = 0; i < rows.length; i += maxEntityGroups) {
      shards.add(rows.sublist(i, i + min<int>(rows.length, maxEntityGroups)));
    }
    return shards;
  }

  /// Inserts [rows] into datastore sharding the inserts if needed.
  Future<void> insert(List<Model> rows) async {
    final List<List<Model>> shards = await shard(rows);
    for (List<Model> shard in shards) {
      await runTransactionWithRetries(() async {
        await db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: shard);
          await transaction.commit();
        });
      });
    }
  }

  /// Looks up registers by [keys].
  Future<List<T>> lookupByKey<T extends Model>(List<Key> keys) async {
    List<T> results = <T>[];
    await runTransactionWithRetries(() async {
      await db.withTransaction<void>((Transaction transaction) async {
        results = await transaction.lookup<T>(keys);
      });
    });
    return results;
  }

  /// Looks up registers by value using a single [key].
  Future<T> lookupByValue<T extends Model>(Key key,
      {T Function() orElse}) async {
    T result;
    await runTransactionWithRetries(() async {
      await db.withTransaction<void>((Transaction transaction) async {
        result = await db.lookupValue<T>(key, orElse: orElse);
      });
    });
    return result;
  }

  /// Runs a function inside a transaction providing a [Transaction] parameter.
  Future<T> withTransaction<T>(Future<T> Function(Transaction) handler) async {
    T result;
    await runTransactionWithRetries(() async {
      await db.withTransaction<void>((Transaction transaction) async {
        result = await handler(transaction);
      });
    });
    return result;
  }
}
