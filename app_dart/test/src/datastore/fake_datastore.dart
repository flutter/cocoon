// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/datastore.dart' show Datastore;
import 'package:gcloud/db.dart';

/// A fake datastore database implementation.
///
/// This datastore's contents are stored in a single [values] map. Callers can
/// set up the map to populate the datastore in a way that works for their
/// test.
class FakeDatastoreDB implements DatastoreDB {
  FakeDatastoreDB({
    Map<Key, Model> values,
  }) : values = values ?? <Key, Model>{};

  final Map<Key, Model> values;

  @override
  Future<dynamic> commit({List<Model> inserts, List<Key> deletes}) async {
    inserts ??= <Model>[];
    deletes ??= <Key>[];
    deletes.forEach(values.remove);
    for (Model model in inserts) {
      values[model.key] = model;
    }
  }

  @override
  Datastore get datastore => throw UnimplementedError();

  @override
  Partition get defaultPartition => Partition(null);

  @override
  Key get emptyKey => defaultPartition.emptyKey;

  @override
  Future<List<T>> lookup<T extends Model>(List<Key> keys) async {
    return keys.map<T>((Key key) => values[key]).toList();
  }

  @override
  Future<T> lookupValue<T extends Model>(Key key, {T orElse()}) async {
    final List<T> values = await lookup(<Key>[key]);
    T value = values.single;
    if (value == null) {
      if (orElse != null) {
        value = orElse();
      } else {
        throw KeyNotFoundException(key);
      }
    }
    return value;
  }

  @override
  ModelDB get modelDB => throw UnimplementedError();

  @override
  Partition newPartition(String namespace) => Partition(namespace);

  @override
  FakeQuery<T> query<T extends Model>({Partition partition, Key ancestorKey}) {
    final List<T> results = values.values.whereType<T>().toList();
    return FakeQuery<T>(results: results);
  }

  @override
  Future<T> withTransaction<T>(TransactionHandler<T> transactionHandler) {
    final FakeTransaction transaction = FakeTransaction._(this);
    return transactionHandler(transaction);
  }
}

/// A query that will return all values of type `T` that exist in the
/// [FakeDatastoreDB.values] map.
///
/// This fake query ignores any [filter] or [order] directives, though it does
/// respect [limit] and [offset] directives.
class FakeQuery<T extends Model> implements Query<T> {
  FakeQuery({this.results});

  List<T> results;
  int start = 0;
  int count = 100;

  @override
  void filter(String filterString, Object comparisonObject) {}

  @override
  void limit(int limit) {
    assert(limit != null);
    assert(limit >= 1);
    count = limit;
  }

  @override
  void offset(int offset) {
    assert(offset != null);
    assert(offset >= 0);
    start = offset;
  }

  @override
  void order(String orderString) {}

  @override
  Stream<T> run() => Stream<T>.fromIterable(results.skip(start).take(count));
}

/// A fake datastore transaction.
///
/// This class keeps track of [inserts] and [deletes] and updates the parent
/// [FakeDatastoreDB] when the transaction is committed.
class FakeTransaction implements Transaction {
  FakeTransaction._(this.db);

  final Map<Key, Model> inserts = <Key, Model>{};
  final Set<Key> deletes = <Key>{};
  bool sealed = false;

  @override
  final FakeDatastoreDB db;

  @override
  Future<dynamic> commit() async {
    if (sealed) {
      throw StateError('Transaction sealed');
    }
    for (MapEntry<Key, Model> entry in inserts.entries) {
      db.values[entry.key] = entry.value;
    }
    deletes.forEach(db.values.remove);
    sealed = true;
  }

  @override
  Future<List<T>> lookup<T extends Model>(List<Key> keys) async {
    final List<T> results = List<T>(keys.length);
    for (Key key in keys) {
      if (deletes.contains(key)) {
        results.add(null);
      } else if (inserts.containsKey(key)) {
        results.add(inserts[key]);
      } else if (db.values.containsKey(key)) {
        results.add(db.values[key]);
      } else {
        results.add(null);
      }
    }
    return results;
  }

  @override
  Future<T> lookupValue<T extends Model>(Key key, {T orElse()}) async {
    final List<T> values = await lookup(<Key>[key]);
    T value = values.single;
    if (value == null) {
      if (orElse != null) {
        value = orElse();
      } else {
        throw KeyNotFoundException(key);
      }
    }
    return value;
  }

  @override
  Query<T> query<T extends Model>(Key ancestorKey, {Partition partition}) {
    final List<T> queryResults = <T>[
      ...inserts.values.whereType<T>(),
      ...db.values.values.whereType<T>(),
    ];
    deletes.whereType<T>().forEach(queryResults.remove);
    return FakeQuery<T>(results: queryResults);
  }

  @override
  void queueMutations({List<Model> inserts, List<Key> deletes}) {
    if (sealed) {
      throw StateError('Transaction sealed');
    }
    if (inserts != null) {
      for (Model insert in inserts) {
        this.inserts[insert.key] = insert;
      }
    }
    if (deletes != null) {
      this.deletes.addAll(deletes);
    }
  }

  @override
  Future<dynamic> rollback() async {
    if (sealed) {
      throw StateError('Transaction sealed');
    }
    inserts.clear();
    deletes.clear();
    sealed = true;
  }
}
