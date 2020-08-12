// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
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
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String agentIdParam = 'AgentID';
  static const String isHealthyParam = 'IsHealthy';
  static const String healthDetailsParam = 'HealthDetails';

  @override
  Future<UpdateAgentHealthResponse> post() async {
    checkRequiredParameters(<String>[agentIdParam, isHealthyParam, healthDetailsParam]);

    final String agentId = requestData[agentIdParam] as String;
    final bool isHealthy = requestData[isHealthyParam] as bool;
    final String healthDetails = requestData[healthDetailsParam] as String;
    final DatastoreService datastore = datastoreProvider(config.db);
    final Key key = datastore.db.emptyKey.append(Agent, id: agentId);
    final Agent agent = await datastore.db.lookupValue<Agent>(
      key,
      orElse: () {
        throw BadRequestException('Invalid agent ID: $agentId');
      },
    );

    agent.isHealthy = isHealthy;
    agent.healthDetails = healthDetails;
    agent.healthCheckTimestamp = DateTime.now().millisecondsSinceEpoch;

    await datastore.db.commit(inserts: <Agent>[agent]);

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
