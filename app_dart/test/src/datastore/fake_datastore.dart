// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:gcloud/datastore.dart' show Datastore, OrderDirection;
import 'package:gcloud/db.dart';

/// Signature for a callback function that will be notified whenever a
/// [FakeQuery] is run.
///
/// The `results` argument contains the provisional results of the query (after
/// [FakeQuery.limit] and [FakeQuery.offset] have been applied). Callers can
/// affect the results of the query by returning a different set of results
/// from the callback.
///
/// The callback must not return null.
typedef QueryCallback<T extends Model> = Iterable<T> Function(Iterable<T> results);

/// Signature for a callback function that will be notified whenever `commit()`
/// is called, either via [FakeDatastoreDB.commit] or [FakeTransaction.commit].
///
/// The `inserts` and `deletes` arguments represent the prospective mutations.
/// Both arguments are immutable.
///
/// This callback will be invoked before any mutations are applied, so by
/// throwing an exception, callbacks can simulate a failed commit.
typedef CommitCallback = void Function(List<Model> inserts, List<Key> deletes);

/// A fake datastore database implementation.
///
/// This datastore's contents are stored in a single [values] map. Callers can
/// set up the map to populate the datastore in a way that works for their
/// test.
class FakeDatastoreDB implements DatastoreDB {
  FakeDatastoreDB({
    Map<Key, Model> values,
    Map<Type, QueryCallback<dynamic>> onQuery,
    this.onCommit,
  })  : values = values ?? <Key, Model>{},
        onQuery = onQuery ?? <Type, QueryCallback<dynamic>>{};

  final Map<Key, Model> values;
  final Map<Type, QueryCallback<dynamic>> onQuery;
  CommitCallback onCommit;

  /// Adds a [QueryCallback] to the set of callbacks that will be notified when
  /// queries are run.
  ///
  /// The [callback] argument will replace any existing callback that has been
  /// specified for type `T`, as only one callback may exist per type.
  void addOnQuery<T extends Model>(QueryCallback<T> callback) {
    final QueryCallback<dynamic> untypedCallback = (Iterable<dynamic> results) {
      return callback(results.cast<T>()).cast<dynamic>();
    };
    onQuery[T] = untypedCallback;
  }

  @override
  Future<dynamic> commit({List<Model> inserts, List<Key> deletes}) async {
    inserts ??= <Model>[];
    deletes ??= <Key>[];
    if (onCommit != null) {
      onCommit(List<Model>.unmodifiable(inserts), List<Key>.unmodifiable(deletes));
    }
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
    return keys.map<T>((Key key) => values[key] as T).toList();
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
    return FakeQuery<T>._(this, results);
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
  FakeQuery._(this.db, this.results);

  final FakeDatastoreDB db;
  final List<FakeFilterSpec> filters = <FakeFilterSpec>[];
  final List<FakeOrderSpec> orders = <FakeOrderSpec>[];

  List<T> results;
  int start = 0;
  int count = 100;

  @override
  void filter(String filterString, Object comparisonObject) {
    // In production, Datastore filters cannot have a space at the end.
    assert(filterString.trim() == filterString);
    filters.add(FakeFilterSpec._(filterString, comparisonObject));
  }

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
  void order(String orderString) {
    if (orderString.startsWith('-')) {
      orders.add(FakeOrderSpec._(orderString.substring(1), OrderDirection.Decending));
    } else {
      orders.add(FakeOrderSpec._(orderString, OrderDirection.Ascending));
    }
  }

  @override
  Stream<T> run() {
    Iterable<T> resultsView = results;

    // This considers only the special case when there exists [branch] or [pr] filter.
    for (FakeFilterSpec filter in filters) {
      final String filterString = filter.filterString;
      final Object value = filter.comparisonObject;
      if (filterString.contains('branch =') || filterString.contains('head =')) {
        resultsView = resultsView.where((T result) => result.toString().contains(value.toString()));
      }
    }
    resultsView = resultsView.skip(start).take(count);

    if (db.onQuery.containsKey(T)) {
      resultsView = db.onQuery[T](resultsView).cast<T>();
    }
    return Stream<T>.fromIterable(resultsView);
  }
}

class FakeFilterSpec {
  const FakeFilterSpec._(this.filterString, this.comparisonObject);

  final String filterString;
  final Object comparisonObject;
}

class FakeOrderSpec {
  const FakeOrderSpec._(this.fieldName, this.direction);

  final String fieldName;
  final OrderDirection direction;
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
    if (db.onCommit != null) {
      db.onCommit(List<Model>.unmodifiable(inserts.values), List<Key>.unmodifiable(deletes));
    }
    for (MapEntry<Key, Model> entry in inserts.entries) {
      db.values[entry.key] = entry.value;
    }
    deletes.forEach(db.values.remove);
    sealed = true;
  }

  @override
  Future<List<T>> lookup<T extends Model>(List<Key> keys) async {
    final List<T> results = <T>[];
    for (Key key in keys) {
      if (deletes.contains(key)) {
        results.add(null);
      } else if (inserts.containsKey(key)) {
        results.add(inserts[key] as T);
      } else if (db.values.containsKey(key)) {
        results.add(db.values[key] as T);
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
    return FakeQuery<T>._(db, queryResults);
  }

  @override
  void queueMutations({List<Model> inserts, List<Key> deletes}) {
    if (sealed) {
      throw StateError('Transaction sealed');
    }
    if (inserts != null) {
      final math.Random random = math.Random();
      for (Model insert in inserts) {
        Key key = insert.key;
        if (key.id == null) {
          key = Key(key.parent, key.type, random.nextInt(math.pow(2, 20).toInt()));
        }
        this.inserts[key] = insert;
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
