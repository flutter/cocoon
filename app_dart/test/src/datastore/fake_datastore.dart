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
typedef QueryCallback<T extends Model<dynamic>> = Iterable<T> Function(Iterable<T> results);

/// Signature for a callback function that will be notified whenever `commit()`
/// is called, either via [FakeDatastoreDB.commit] or [FakeTransaction.commit].
///
/// The `inserts` and `deletes` arguments represent the prospective mutations.
/// Both arguments are immutable.
///
/// This callback will be invoked before any mutations are applied, so by
/// throwing an exception, callbacks can simulate a failed commit.
typedef CommitCallback = void Function(List<Model<dynamic>> inserts, List<Key<dynamic>> deletes);

/// A fake datastore database implementation.
///
/// This datastore's contents are stored in a single [values] map. Callers can
/// set up the map to populate the datastore in a way that works for their
/// test.
class FakeDatastoreDB implements DatastoreDB {
  FakeDatastoreDB({
    Map<Key<dynamic>, Model<dynamic>> values,
    Map<Type, QueryCallback<Model<dynamic>>> onQuery,
    this.onCommit,
  })  : values = values ?? <Key<dynamic>, Model<dynamic>>{},
        onQuery = onQuery ?? <Type, QueryCallback<Model<dynamic>>>{};

  final Map<Key<dynamic>, Model<dynamic>> values;
  final Map<Type, QueryCallback<Model<dynamic>>> onQuery;
  CommitCallback onCommit;

  /// Adds a [QueryCallback] to the set of callbacks that will be notified when
  /// queries are run.
  ///
  /// The [callback] argument will replace any existing callback that has been
  /// specified for type `T`, as only one callback may exist per type.
  void addOnQuery<T extends Model<dynamic>>(QueryCallback<T> callback) {
    final QueryCallback<Model<dynamic>> untypedCallback = (Iterable<Model<dynamic>> results) {
      return callback(results.cast<T>()).cast<Model<dynamic>>();
    };
    onQuery[T] = untypedCallback;
  }

  @override
  Future<dynamic> commit({List<Model<dynamic>> inserts, List<Key<dynamic>> deletes}) async {
    inserts ??= <Model<dynamic>>[];
    deletes ??= <Key<dynamic>>[];
    if (onCommit != null) {
      onCommit(List<Model<dynamic>>.unmodifiable(inserts), List<Key<dynamic>>.unmodifiable(deletes));
    }
    deletes.forEach(values.remove);
    for (Model<dynamic> model in inserts) {
      values[model.key] = model;
    }
  }

  @override
  Datastore get datastore => throw UnimplementedError();

  @override
  Partition get defaultPartition => Partition(null);

  @override
  Key<dynamic> get emptyKey => defaultPartition.emptyKey;

  @override
  Future<List<T>> lookup<T extends Model<dynamic>>(List<Key<dynamic>> keys) async {
    return keys.map<T>((Key<dynamic> key) => values[key] as T).toList();
  }

  @override
  Future<T> lookupValue<T extends Model<dynamic>>(Key<dynamic> key, {T orElse()}) async {
    final List<T> values = await lookup(<Key<dynamic>>[key]);
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
  FakeQuery<T> query<T extends Model<dynamic>>({Partition partition, Key<dynamic> ancestorKey}) {
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
class FakeQuery<T extends Model<dynamic>> implements Query<T> {
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
      if (filterString.contains('branch =') ||
          filterString.contains('head =') ||
          filterString.contains('repository =')) {
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

  final Map<Key<dynamic>, Model<dynamic>> inserts = <Key<dynamic>, Model<dynamic>>{};
  final Set<Key<dynamic>> deletes = <Key<dynamic>>{};
  bool sealed = false;

  @override
  final FakeDatastoreDB db;

  @override
  Future<dynamic> commit() async {
    if (sealed) {
      throw StateError('Transaction sealed');
    }
    if (db.onCommit != null) {
      db.onCommit(List<Model<dynamic>>.unmodifiable(inserts.values), List<Key<dynamic>>.unmodifiable(deletes));
    }
    for (MapEntry<Key<dynamic>, Model<dynamic>> entry in inserts.entries) {
      db.values[entry.key] = entry.value;
    }
    deletes.forEach(db.values.remove);
    sealed = true;
  }

  @override
  Future<List<T>> lookup<T extends Model<dynamic>>(List<Key<dynamic>> keys) async {
    final List<T> results = <T>[];
    for (Key<dynamic> key in keys) {
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
  Future<T> lookupValue<T extends Model<dynamic>>(Key<dynamic> key, {T orElse()}) async {
    final List<T> values = await lookup(<Key<dynamic>>[key]);
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
  Query<T> query<T extends Model<dynamic>>(Key<dynamic> ancestorKey, {Partition partition}) {
    final List<T> queryResults = <T>[
      ...inserts.values.whereType<T>(),
      ...db.values.values.whereType<T>(),
    ];
    deletes.whereType<T>().forEach(queryResults.remove);
    return FakeQuery<T>._(db, queryResults);
  }

  @override
  void queueMutations({List<Model<dynamic>> inserts, List<Key<dynamic>> deletes}) {
    if (sealed) {
      throw StateError('Transaction sealed');
    }
    if (inserts != null) {
      final math.Random random = math.Random();
      for (Model<dynamic> insert in inserts) {
        Key<dynamic> key = insert.key;
        if (key.id == null) {
          key = Key<dynamic>(key.parent, key.type, random.nextInt(math.pow(2, 20).toInt()));
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
