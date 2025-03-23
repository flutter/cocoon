// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:gcloud/datastore.dart' as gcloud_datastore;
import 'package:gcloud/db.dart';
import 'package:github/github.dart' show RepositorySlug;
import 'package:grpc/grpc.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../model/appengine/branch.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../request_handling/exceptions.dart';
import 'config.dart';

/// Per the docs in [DatastoreDB.withTransaction], only 5 entity groups can
/// be touched in any given transaction, or the backing datastore will throw
/// an error.
const int defaultMaxEntityGroups = 5;

/// This number inherits from old GO backend, and is upto change if necessary.
const int defaultTimeSeriesValuesNumber = 1500;

/// Function signature for a [DatastoreService] provider.
typedef DatastoreServiceProvider = DatastoreService Function(DatastoreDB db);

/// Function signature that will be executed with retries.
typedef RetryHandler = void Function();

/// Runs a db transaction with retries.
///
/// It uses quadratic backoff starting with 200ms and 3 max attempts.
/// for context please read https://github.com/flutter/flutter/issues/54615.
Future<void> runTransactionWithRetries(
  RetryHandler retryHandler, {
  RetryOptions? retryOptions,
}) {
  final r =
      retryOptions ??
      const RetryOptions(maxDelay: Duration(seconds: 10), maxAttempts: 3);
  return r.retry(
    retryHandler,
    retryIf:
        (Exception e) =>
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
    this.maxEntityGroups, {
    RetryOptions? retryOptions,
  }) : retryOptions =
           retryOptions ??
           const RetryOptions(maxDelay: Duration(seconds: 10), maxAttempts: 3);

  /// Maximum number of entity groups to process at once.
  final int maxEntityGroups;

  /// The backing [DatastoreDB] object.
  final DatastoreDB db;

  /// Transaction retry configurations.
  final RetryOptions retryOptions;

  /// Creates and returns a [DatastoreService] using [db] and [maxEntityGroups].
  static DatastoreService defaultProvider(DatastoreDB db) {
    return DatastoreService(db, defaultMaxEntityGroups);
  }

  /// Queries for recent commits.
  ///
  /// The [limit] argument specifies the maximum number of commits to retrieve.
  ///
  /// The returned commits will be ordered by most recent [Commit.timestamp].
  Stream<Commit> queryRecentCommits({
    int limit = 100,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) {
    timestamp ??= DateTime.now().millisecondsSinceEpoch;
    branch ??= Config.defaultBranch(slug);
    final query =
        db.query<Commit>()
          ..limit(limit)
          ..filter('repository =', slug.fullName)
          ..filter('branch =', branch)
          ..order('-timestamp')
          ..filter('timestamp <', timestamp);
    return query.run();
  }

  Stream<Branch> queryBranches() {
    final query = db.query<Branch>();
    return query.run();
  }

  /// Queries for recent [Task] by name.
  ///
  /// The [limit] argument specifies the maximum number of tasks to retrieve.
  ///
  /// The returned tasks will be ordered by most recent to oldest.
  Stream<Task> queryRecentTasksByName({int limit = 100, required String name}) {
    final query =
        db.query<Task>()
          ..limit(limit)
          ..filter('name =', name)
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
  /// If [taskName] is specified, only tasks whose [Task.name] matches the
  /// specified value will be returned. By default, tasks will be returned
  /// regardless of their name.
  ///
  /// The returned tasks will be ordered by most recent [Commit.timestamp]
  /// first, then by most recent [Task.createTimestamp].
  Stream<FullTask> queryRecentTasks({
    String? taskName,
    int commitLimit = 20,
    String? branch,
    required RepositorySlug slug,
  }) async* {
    await for (Commit commit in queryRecentCommits(
      limit: commitLimit,
      branch: branch,
      slug: slug,
    )) {
      final query = db.query<Task>(ancestorKey: commit.key)
        ..order('-createTimestamp');
      if (taskName != null) {
        query.filter('name =', taskName);
      }
      yield* query.run().map<FullTask>((Task task) => FullTask(task, commit));
    }
  }

  /// Shards [rows] into several sublists of size [maxEntityGroups].
  Future<List<List<Model<dynamic>>>> shard(List<Model<dynamic>> rows) async {
    final shards = <List<Model<dynamic>>>[];
    for (var i = 0; i < rows.length; i += maxEntityGroups) {
      shards.add(
        rows.sublist(i, i + min<int>(rows.length - i, maxEntityGroups)),
      );
    }
    return shards;
  }

  /// Inserts [rows] into datastore sharding the inserts if needed.
  Future<void> insert(List<Model<dynamic>> rows) async {
    final shards = await shard(rows);
    for (var shard in shards) {
      await runTransactionWithRetries(() async {
        await db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: shard);
          await transaction.commit();
        });
      }, retryOptions: retryOptions);
    }
  }

  /// Looks up registers by [keys].
  Future<List<T?>> lookupByKey<T extends Model<dynamic>>(
    List<Key<dynamic>> keys,
  ) async {
    List<T?> results = <T>[];
    await runTransactionWithRetries(() async {
      await db.withTransaction<void>((Transaction transaction) async {
        results = await transaction.lookup<T>(keys);
        await transaction.commit();
      });
    }, retryOptions: retryOptions);
    return results;
  }

  /// Looks up registers by value using a single [key].
  Future<T> lookupByValue<T extends Model<dynamic>>(
    Key<dynamic> key, {
    T Function()? orElse,
  }) async {
    late T result;
    await runTransactionWithRetries(() async {
      await db.withTransaction<void>((Transaction transaction) async {
        result = await db.lookupValue<T>(key, orElse: orElse);
        await transaction.commit();
      });
    }, retryOptions: retryOptions);
    return result;
  }

  /// Runs a function inside a transaction providing a [Transaction] parameter.
  Future<T?> withTransaction<T>(Future<T> Function(Transaction) handler) async {
    T? result;
    await runTransactionWithRetries(() async {
      await db.withTransaction<void>((Transaction transaction) async {
        result = await handler(transaction);
      });
    }, retryOptions: retryOptions);
    return result;
  }

  Future<Task?> getTaskFromBuildbucketBuild(
    bbv2.Build build, {
    String? customName,
  }) async {
    log.debug(
      'Generating commit key from buildbucket build: ${build.toString()}',
    );

    final repository = build.input.gitilesCommit.project.split('/')[1];
    log.debug('Repository: $repository');

    final branch = build.input.gitilesCommit.ref.split('/')[2];
    log.debug('Branch: $branch');

    final hash = build.input.gitilesCommit.id;
    log.debug('Hash: $hash');

    final slug = RepositorySlug('flutter', repository);
    log.debug('Slug: ${slug.toString()}');

    final id = '${slug.fullName}/$branch/$hash';
    final commitKey = db.emptyKey.append<String>(Commit, id: id);

    try {
      return await Task.fromDatastore(
        datastore: this,
        commitKey: commitKey,
        name: customName ?? build.builder.builder,
      );
    } on InternalServerError catch (e) {
      log.warn('Failed to find an existing task for the buildbucket build', e);
      return null;
    }
  }
}
