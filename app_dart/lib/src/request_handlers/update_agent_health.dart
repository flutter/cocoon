// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:gcloud/db.dart';
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
  static const String agentIDParam = 'AgentID';
  static const String isHealthyParam = 'IsHealthy';
  static const String healthDetailsParam = 'HealthDetails';

  @override
  Future<UpdateAgentHealthResponse> post() async {
    checkRequiredParameters(<String>[isHealthyParam, healthDetailsParam]);

    final bool isHealthy = requestData[isHealthyParam];
    final String healthDetails = requestData[healthDetailsParam];

    final Query<Agent> query = config.db.query<Agent>()
      ..filter('agentID =', requestData[agentIDParam]);
    final List<Agent> agents = await query.run().toList();
    assert(agents.length <= 1);
    if (agents.isEmpty) {
      return Body.empty;
    }
    final Agent agent = agents.single;
    agent.isHealthy = isHealthy;
    agent.healthDetails = healthDetails;

    await config.db.withTransaction<void>((Transaction transaction) async {
      transaction.queueMutations(inserts: <Agent>[agent]);
      await transaction.commit();
    });

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
