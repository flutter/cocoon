// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/agent.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

const Duration maxHealthCheckAge = Duration(minutes: 10);

@immutable
class UpdateAgentHealthHistory extends ApiRequestHandler<Body> {
  const UpdateAgentHealthHistory(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Agent';

    final TabledataResourceApi tabledataResourceApi =
        await config.createTabledataResourceApi();
    final DatastoreService datastore = datastoreProvider();
    final Query<Agent> agentQuery = datastore.db.query<Agent>()
      ..order('agentId');
    final List<Agent> agents =
        await agentQuery.run().where(_isVisible).toList();
    agents.sort((Agent a, Agent b) =>
        compareAsciiLowerCaseNatural(a.agentId, b.agentId));

    final List<Map<String, Object>> tableDataInsertAllRequestRows =
        <Map<String, Object>>[];

    for (Agent agent in agents) {
      final bool isHealthy = _isAgentHealthy(agent);

      /// Consolidate [agents] together.
      ///
      /// Prepare for bigquery [insertAll].
      tableDataInsertAllRequestRows.add(<String, Object>{
        'json': <String, Object>{
          'Timestamp': agent.healthCheckTimestamp,
          'AgentID': agent.agentId,
          'Status': isHealthy ? 'healthy' : 'unhealthy',
          'Detail': isHealthy ? agent.healthDetails : 'out of date',
        },
      });
    }

    /// Prepare final [rows] to be inserted to `BigQuery`.
    final TableDataInsertAllRequest rows = TableDataInsertAllRequest.fromJson(
        <String, Object>{'rows': tableDataInsertAllRequestRows});

    /// Insert [agents] to `BigQuery`.
    try {
      await tabledataResourceApi.insertAll(rows, projectId, dataset, table);
    } catch (ApiRequestError) {
      log.error('Failed to add commits to BigQuery: $ApiRequestError');
    }

    return Body.forJson(<String, dynamic>{
      'AgentStatuses': agents,
    });
  }

  bool _isVisible(Agent agent) => !agent.isHidden;

  bool _isAgentHealthy(Agent agent) {
    return agent.isHealthy &&
        agent.healthCheckTimestamp != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
                agent.healthCheckTimestamp)) <
            maxHealthCheckAge;
  }
}
