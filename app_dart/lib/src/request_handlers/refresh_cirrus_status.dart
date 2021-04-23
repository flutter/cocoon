// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:graphql/client.dart';

import '../request_handling/exceptions.dart';
import 'refresh_cirrus_status_queries.dart';

/// Refer all cirrus build statuses at: https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql#L120
const List<String> kCirrusFailedStates = <String>[
  'ABORTED',
  'FAILED',
];
const List<String> kCirrusInProgressStates = <String>['CREATED', 'TRIGGERED', 'SCHEDULED', 'EXECUTING', 'PAUSED'];

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
    for (final GraphQLError error in result.errors) {
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
    for (final dynamic searchBuild in searchBuilds) {
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
