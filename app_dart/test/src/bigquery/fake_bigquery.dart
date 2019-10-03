// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:googleapis/bigquery/v2.dart';
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
class FakeTabledataResourceApi implements TabledataResourceApi {
  FakeTabledataResourceApi({
    Map<Key, Model> values,
    Map<Type, QueryCallback<dynamic>> onQuery,
    this.onCommit,
  })  : values = values ?? <Key, Model>{},
        onQuery = onQuery ?? <Type, QueryCallback<dynamic>>{};

  //to-do Keyong
}
