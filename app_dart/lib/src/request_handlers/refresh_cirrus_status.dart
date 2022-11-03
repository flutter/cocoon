// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:graphql/client.dart';

import '../request_handling/exceptions.dart';
import '../service/logging.dart';
import 'refresh_cirrus_status_queries.dart';

/// Refer all cirrus build statuses at: https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql#L120
const List<String> kCirrusFailedStates = <String>[
  'ABORTED',
  'FAILED',
];
const List<String> kCirrusInProgressStates = <String>['CREATED', 'TRIGGERED', 'SCHEDULED', 'EXECUTING', 'PAUSED'];

/// Return the latest Cirrus build for a given [sha] by querying the cirrus graphQL.
///
/// API explorer: https://cirrus-ci.com/explorer
Future<CirrusResult> queryCirrusGraphQL(
  String sha,
  GraphQLClient client,
  String name,
) async {
  const String owner = 'flutter';
  log.info('Cirrus query owner:$owner, name:$name, sha:$sha ');
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
  if (result.hasException) {
    log.severe(result.exception.toString());
    throw const BadRequestException('GraphQL query failed');
  }

  final List<Map<String, dynamic>> tasks = <Map<String, dynamic>>[];
  late CirrusResult cirrusResult;

  if (result.data == null) {
    cirrusResult = CirrusResult(null, null, tasks);
    return cirrusResult;
  }
  try {
    cirrusResult = getFirstBuildResult(result.data, tasks, name: name, sha: sha);
  } catch (_) {
    log.fine('Did not receive expected result from Cirrus, sha $sha may not be executing Cirrus tasks.');
  }
  return cirrusResult;
}

/// There may be multiple build results for a single commit.
///
/// This returns the first build which represents the latest test statuses.
CirrusResult getFirstBuildResult(
  Map<String, dynamic>? data,
  List<Map<String, dynamic>> tasks, {
  String? name,
  String? sha,
}) {
  log.info('Cirrus data: $data');
  final List<dynamic> searchBuilds = data!['searchBuilds'] as List<dynamic>;
  if (searchBuilds.isEmpty) {
    return const CirrusResult(null, null, <Map<String, dynamic>>[]);
  }
  final Map<String, dynamic> searchBuild = searchBuilds.first as Map<String, dynamic>;
  tasks.addAll((searchBuild['latestGroupTasks'] as List<dynamic>).cast<Map<String, dynamic>>());
  final String? id = searchBuild['id'] as String?;
  log.info('Cirrus searchBuild id for flutter/$name, commit: $sha: $id');
  final String? branch = searchBuild['branch'] as String?;
  return CirrusResult(id, branch, tasks);
}

class CirrusResult {
  const CirrusResult(this.id, this.branch, this.tasks);

  final String? id;
  final String? branch;
  final List<Map<String, dynamic>> tasks;
}
