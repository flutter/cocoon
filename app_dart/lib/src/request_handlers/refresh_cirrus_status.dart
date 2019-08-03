// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

const List<String> _failedStates = <String>['error', 'failure'];
const List<String> _inProgressStates = <String>['pending'];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<Body> {
  const RefreshCirrusStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider();
    final GitHub github = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

    await for (FullTask task in datastore.queryRecentTasks(taskName: 'cirrus')) {
      final String sha = task.commit.sha;
      final Map<String, RepositoryStatus> mostRecentStatuses = <String, RepositoryStatus>{};
      await for (RepositoryStatus status in github.repositories.listStatuses(slug, sha)) {
        final bool isCirrusStatus = status.targetUrl.contains('cirrus-ci.com');
        if (isCirrusStatus) {
          final String taskName = status.context;
          final RepositoryStatus existingStatus = mostRecentStatuses[taskName];
          if (existingStatus == null || existingStatus.updatedAt.isBefore(status.updatedAt)) {
            mostRecentStatuses[taskName] = status;
          }
        }
      }

      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          if (mostRecentStatuses.isEmpty) {
            task.task.status = Task.statusNew;
          } else if (mostRecentStatuses.values.any(_failedStates.contains)) {
            task.task.status = Task.statusFailed;
          } else if (mostRecentStatuses.values.any(_inProgressStates.contains)) {
            task.task.status = Task.statusInProgress;
          } else {
            task.task.status = Task.statusSucceeded;
          }
          transaction.queueMutations(inserts: <Task>[task.task]);
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
