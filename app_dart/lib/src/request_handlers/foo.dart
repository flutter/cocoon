// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/datastore.dart';

@immutable
class Foo extends RequestHandler<Body> {
  const Foo(
    Config config, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    final String maxParam = request.uri.queryParameters['max'];
    final int max =  int.tryParse(maxParam) ?? 5;
    final DatastoreService datastore = datastoreProvider();
    await for (Commit commit in datastore.db.query<Commit>().run().take(max)) {
      final List<Task> tasks = <Task>[];
      await for (Task task in datastore.db.query<Task>(ancestorKey: commit.key).run()) {
        task.attempts++;
        tasks.add(task);
        log.debug('Task ${task.id} attempts==${task.attempts}');
      }
      await datastore.db.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
      });
    }

    return Body.empty;
  }
}
