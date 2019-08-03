// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

import '../service/luci.dart';

@visibleForTesting
typedef LuciServiceProvider = LuciService Function(RefreshChromebotStatus handler);

@immutable
class RefreshChromebotStatus extends ApiRequestHandler<Body> {
  const RefreshChromebotStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LuciServiceProvider luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider = datastoreProvider ?? _createDatastoreService,
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciServiceProvider luciServiceProvider;
  final DatastoreServiceProvider datastoreProvider;

  static LuciService _createLuciService(RefreshChromebotStatus handler) {
    return LuciService(
      config: handler.config,
      clientContext: handler.authContext.clientContext,
    );
  }

  static DatastoreService _createDatastoreService() {
    return DatastoreService(db: dbService);
  }

  @override
  Future<Body> get() async {
    final LuciService luciService = luciServiceProvider(this);
    final DatastoreService datastore = datastoreProvider();
    final Map<LuciBuilder, List<LuciTask>> luciTasks = await luciService.getRecentTasks();

    for (LuciBuilder builder in luciTasks.keys) {
      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          await for (FullTask task in datastore.queryRecentTasks(taskName: builder.taskName)) {
            for (LuciTask luciTask in luciTasks[builder]) {
              if (luciTask.commitSha == task.commit.sha) {
                final Task update = task.task;
                update.status = luciTask.status;
                transaction.queueMutations(inserts: <Task>[update]);
              }
            }
          }
          await transaction.commit();
        } catch (error) {
          await transaction.rollback();
          rethrow;
        }
      });
    }

    return Body.empty;
  }
}
