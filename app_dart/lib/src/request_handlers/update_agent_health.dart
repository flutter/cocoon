// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class UpdateAgentHealth extends ApiRequestHandler<UpdateAgentHealthResponse> {
  const UpdateAgentHealth(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String agentIdParam = 'AgentID';
  static const String isHealthyParam = 'IsHealthy';
  static const String healthDetailsParam = 'HealthDetails';

  @override
  Future<UpdateAgentHealthResponse> post() async {
    checkRequiredParameters(<String>[agentIdParam, isHealthyParam, healthDetailsParam]);

    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'AgentStatus';

    final String agentId = requestData[agentIdParam];
    final bool isHealthy = requestData[isHealthyParam];
    final String healthDetails = requestData[healthDetailsParam];
    final DatastoreService datastore = datastoreProvider();
    final Key key = datastore.db.emptyKey.append(Agent, id: agentId);
    final Agent agent = await datastore.db.lookupValue<Agent>(
      key,
      orElse: () {
        throw BadRequestException('Invalid agent ID: $agentId');
      },
    );
    final TabledataResourceApi tabledataResourceApi = await config.createTabledataResourceApi();
    final List<Map<String, Object>> tableDataInsertAllRequestRows = <Map<String, Object>>[];

    agent.isHealthy = isHealthy;
    agent.healthDetails = healthDetails;
    agent.healthCheckTimestamp = DateTime.now().millisecondsSinceEpoch;

    await datastore.db.commit(inserts: <Agent>[agent]);

    /// Insert data to [BigQuery] whenever updating data in [Datastore] 
    tableDataInsertAllRequestRows.add(<String, Object>{
      'json': <String, Object>{
        'Timestamp': agent.healthCheckTimestamp,
        'AgentID': agentId,
        // TODO(keyonghan): add more detailed states https://github.com/flutter/flutter/issues/44213
        'Status': isHealthy?'healthy':'unHealthy',
        'Detail': healthDetails,
      },
    });

    /// Final [rows] to be inserted to [BigQuery]
    final TableDataInsertAllRequest rows =
      TableDataInsertAllRequest.fromJson(<String, Object>{
      'rows': tableDataInsertAllRequestRows
    });

    try {
      await tabledataResourceApi.insertAll(rows, projectId, dataset, table);
    } catch(ApiRequestError){
      log.warning('Failed to add $agentId status to BigQuery: $ApiRequestError');
    }

    return UpdateAgentHealthResponse(agent);
  }
}

@immutable
class UpdateAgentHealthResponse extends JsonBody {
  const UpdateAgentHealthResponse(this.agent) : assert(agent != null);

  final Agent agent;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Agent': agent.agentId,
      'Healthy': agent.isHealthy,
      'Details': agent.healthDetails,
    };
  }
}

