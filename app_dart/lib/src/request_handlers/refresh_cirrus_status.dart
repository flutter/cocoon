// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import 'refresh_cirrus_status_queries.dart';

/// Refer all cirrus build statuses at: https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql#L120
const List<String> kCirrusFailedStates = <String>[
  'ABORTED',
  'FAILED',
];
const List<String> kCirrusInProgressStates = <String>[
  'CREATED',
  'TRIGGERED',
  'SCHEDULED',
  'EXECUTING',
  'PAUSED'
];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<Body> {
  const RefreshCirrusStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider();
    final GraphQLClient client = await config.createCirrusGraphQLClient();

    await for (FullTask task
        in datastore.queryRecentTasks(taskName: 'cirrus', commitLimit: 15)) {
      final String sha = task.commit.sha;
      final String existingTaskStatus = task.task.status;
      log.debug(
          'Found Cirrus task for commit $sha with existing status $existingTaskStatus');
      final List<String> statuses = <String>[];
      const String name = 'flutter';

      for (dynamic runStatus
          in await queryCirrusGraphQL(sha, client, log, name)) {
        final String status = runStatus['status'];
        final String taskName = runStatus['name'];
        log.debug('Found Cirrus build status for $sha: $taskName ($status)');
        statuses.add(status);
      }

      String newTaskStatus;
      if (statuses.isEmpty) {
        newTaskStatus = Task.statusNew;
      } else if (statuses.any(kCirrusFailedStates.contains)) {
        newTaskStatus = Task.statusFailed;
        task.task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
      } else if (statuses.any(kCirrusInProgressStates.contains)) {
        newTaskStatus = Task.statusInProgress;
      } else {
        newTaskStatus = Task.statusSucceeded;
        task.task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
      }

      if (newTaskStatus != existingTaskStatus) {
        task.task.status = newTaskStatus;
        await config.db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: <Task>[task.task]);
          await transaction.commit();
        });
      }
    }
    return Body.empty;
  }
}

Future<List<dynamic>> queryCirrusGraphQL(
  String sha,
  GraphQLClient client,
  Logging log,
  String name,
) async {
  assert(client != null);
  const String owner = 'flutter';
  final QueryResult result = await client.query(
    QueryOptions(
      document: cirusStatusQuery,
      fetchPolicy: FetchPolicy.noCache,
      variables: <String, dynamic>{
        'owner': owner,
        'name': name,
        'SHA': sha,
      },
    ),
  );

  if (result.hasErrors) {
    for (GraphQLError error in result.errors) {
      log.error(error.toString());
    }
    throw const BadRequestException('GraphQL query failed');
  }

  final List<dynamic> tasks = <dynamic>[];
  if (result.data == null) {
    return tasks;
  }
  try {
    final Map<String, dynamic> searchBuilds = result.data['searchBuilds'].first;
    tasks.addAll(searchBuilds['latestGroupTasks']);
  } catch(_) {
    log.debug('Did not receive expected result from Cirrus:');
    log.debug(result.data);
  }
  return tasks;
}
