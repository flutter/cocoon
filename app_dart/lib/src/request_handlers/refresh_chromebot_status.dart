// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/luci.dart';

@immutable
class RefreshChromebotStatus extends ApiRequestHandler<Body> {
  const RefreshChromebotStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LuciServiceProvider luciServiceProvider,
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting
        this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : luciServiceProvider = luciServiceProvider ?? _createLuciService,
        datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final LuciServiceProvider luciServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  static LuciService _createLuciService(ApiRequestHandler<dynamic> handler) {
    return LuciService(
      config: handler.config,
      clientContext: handler.authContext.clientContext,
    );
  }

  @override
  Future<Body> get() async {
    final LuciService luciService = luciServiceProvider(this);
    final DatastoreService datastore = datastoreProvider(config.db);
    final Map<LuciBuilder, List<LuciTask>> luciTasks =
        await luciService.getRecentTasks(
      repo: 'flutter',
      requireTaskName: true,
    );

    final List<String> branches = await config.flutterBranches;

    for (LuciBuilder builder in luciTasks.keys) {
      await runTransactionWithRetries(() async {
        await _updateStatus(
          builder,
          branches,
          datastore,
          luciTasks,
        );
      });
    }
    return Body.empty;
  }

  /// Update chromebot tasks statuses in datastore for [builder],
  /// based on latest [luciTasks] statuses.
  Future<void> _updateStatus(
      LuciBuilder builder,
      List<String> branches,
      DatastoreService datastore,
      Map<LuciBuilder, List<LuciTask>> luciTasks) async {
    for (String branch in branches) {
      await for (FullTask task in datastore.queryRecentTasks(
          taskName: builder.taskName, branch: branch)) {
        for (LuciTask luciTask in luciTasks[builder]) {
          if (luciTask.commitSha == task.commit.sha &&
              luciTask.ref == 'refs/heads/$branch') {
            final Task update = task.task;
            update.status = luciTask.status;
            await datastore.insert(<Task>[update]);
            // Stop updating task whenever we find the latest status of the same commit.
            break;
          }
        }
      }
    }
  }
}
