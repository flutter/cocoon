// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math';
import 'package:gcloud/db.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import '../datastore/cocoon_config.dart';

/// Wrapper class for datastore operations.
///
/// Datastore operations generate high rates of errors related to
/// Transaction and/or GRPC problems. Fixing this required to add retries
/// to all the database operations causing 4 or 5 levels of nesting. This
/// class was created to simplify all the database related operations to a
/// single nesting level in most cases or two at most while still providing
/// retry logic.
class DatastoreWrapper {
  DatastoreWrapper(this._db, this._config);

  final DatastoreDB _db;
  final Config _config;

  /// Shards [rows] into several sublists of size [Config.maxEntityGroups].
  Future<List<List<Model>>> shard(List<Model> rows) async {
    final List<List<Model>> shards = <List<Model>>[];
    for (int i = 0; i < rows.length; i += _config.maxEntityGroups) {
      shards.add(rows.sublist(i, min(rows.length, _config.maxEntityGroups)));
    }
    return shards;
  }

  /// Inserts [rows] into datastore sharding the inserts if needed.
  Future<void> insert(List<Model> rows) async {
    final List<List<Model>> shards = await shard(rows);
    for (List<Model> shard in shards) {
      await runTransactionWithRetries(() async {
        await _db.withTransaction<void>((Transaction transaction) async {
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
      await _db.withTransaction<void>((Transaction transaction) async {
        results = await transaction.lookup<T>(keys);
      });
    });
    return results;
  }

  /// Looks up registers by value using a single [key].
  Future<T> lookupByValue<T extends Model>(Key key) async {
    T result;
    await runTransactionWithRetries(() async {
      await _db.withTransaction<void>((Transaction transaction) async {
        result = await _db.lookupValue<T>(key, orElse: () => null);
      });
    });
    return result;
  }

  /// Runs a function inside a transaction providing a [Transaction] parameter.
  Future<T> withTransaction<T>(Future<T> Function(Transaction) handler) async {
    T result;
    await runTransactionWithRetries(() async {
      await _db.withTransaction<void>((Transaction transaction) async {
        result = await handler(transaction);
      });
    });
    return result;
  }
}
