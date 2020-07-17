// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
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
const List<String> kCirrusInProgressStates = <String>['CREATED', 'TRIGGERED', 'SCHEDULED', 'EXECUTING', 'PAUSED'];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<Body> {
  const RefreshCirrusStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final GraphQLClient client = await config.createCirrusGraphQLClient();
    const int commitLimit = 15;

    for (String branch in await config.flutterBranches) {
      await for (FullTask task
          in datastore.queryRecentTasks(taskName: 'cirrus', commitLimit: commitLimit, branch: branch)) {
        final String sha = task.commit.sha;
        final String existingTaskStatus = task.task.status;

        log.debug('Found Cirrus task for branch $branch, commit $sha, with existing status $existingTaskStatus');

        const String name = 'flutter';
        final List<CirrusResult> cirrusResults = await queryCirrusGraphQL(sha, client, log, name);

        /// Get cirrus task statuses for [task.commit.branch] and [sha].
        final List<String> statuses = _getStatuses(cirrusResults, task.commit.branch, sha);

        /// Calculate overall new task status based on cirrus results.
        final String newTaskStatus = _getNewTaskStatus(statuses, task);

        if (newTaskStatus == existingTaskStatus) {
          continue;
        }
        task.task.status = newTaskStatus;
        await datastore.insert(<Task>[task.task]);
      }
    }
    return Body.empty;
  }

  String _getNewTaskStatus(List<String> statuses, FullTask task) {
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
    return newTaskStatus;
  }

  List<String> _getStatuses(List<CirrusResult> cirrusResults, String branch, String sha) {
    final List<String> statuses = <String>[];

    /// Multiple branches may exist for same commit.
    /// Update only when branches match
    if (!cirrusResults.any((CirrusResult cirrusResult) => cirrusResult.branch == branch)) {
      return statuses;
    }
    for (Map<String, dynamic> runStatus
        in cirrusResults.firstWhere((CirrusResult cirrusResult) => cirrusResult.branch == branch).tasks) {
      final String status = runStatus['status'] as String;
      final String taskName = runStatus['name'] as String;
      log.debug('Found Cirrus build status for $sha: $taskName ($status)');
      statuses.add(status);
    }
    return statuses;
  }
}

Future<List<CirrusResult>> queryCirrusGraphQL(
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

  final List<Map<String, dynamic>> tasks = <Map<String, dynamic>>[];
  final List<CirrusResult> cirrusResults = <CirrusResult>[];
  String branch;
  if (result.data == null) {
    cirrusResults.add(CirrusResult(branch, tasks));
    return cirrusResults;
  }
  try {
    final List<dynamic> searchBuilds = result.data['searchBuilds'] as List<dynamic>;
    for (dynamic searchBuild in searchBuilds) {
      tasks.clear();
      tasks.addAll((searchBuild['latestGroupTasks'] as List<dynamic>).cast<Map<String, dynamic>>());
      branch = searchBuild['branch'] as String;
      cirrusResults.add(CirrusResult(branch, tasks));
    }
  } catch (_) {
    log.debug('Did not receive expected result from Cirrus, sha $sha may not be executing Cirrus tasks.');
  }
  return cirrusResults;
}

class CirrusResult {
  const CirrusResult(this.branch, this.tasks) : assert(tasks != null);

  final String branch;
  final List<Map<String, dynamic>> tasks;
}
