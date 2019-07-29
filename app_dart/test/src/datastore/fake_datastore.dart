// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/datastore.dart' show Datastore;
import 'package:gcloud/db.dart';

class FakeDatastoreDB implements DatastoreDB {
  FakeDatastoreDB({
    Map<Key, Model> values,
  }) : values = values ?? <Key, Model>{};

  Map<Key, Model> values;

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
  Future<T> lookupValue<T extends Model>(Key key, {T Function() orElse}) async {
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
    throw UnimplementedError();
  }
}

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
