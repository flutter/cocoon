// Copyright 2019 The Chromium Authors. All rights reserved.
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
import '../service/agent_service.dart';
import '../service/datastore.dart';

@immutable
class CreateAgent extends ApiRequestHandler<CreateAgentResponse> {
  const CreateAgent(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    this.agentServiceProvider = AgentService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final AgentServiceProvider agentServiceProvider;

  static const String agentIdParam = 'AgentID';
  static const String capabilitiesParam = 'Capabilities';

  @override
  Future<CreateAgentResponse> post() async {
    checkRequiredParameters(<String>[agentIdParam, capabilitiesParam]);

    final String agentId = requestData[agentIdParam] as String;
    final List<String> capabilities =
        (requestData[capabilitiesParam] as List<dynamic>)
            .cast<String>()
            .toList();
    final DatastoreService datastore = datastoreProvider();
    final AgentService agentService = agentServiceProvider();
    final Key key = datastore.db.emptyKey.append(Agent, id: agentId);

    if (await datastore.db.lookupValue<Agent>(key, orElse: () => null) !=
        null) {
      throw BadRequestException('Agent ID: $agentId already exists');
    }

    final AgentAuthToken agentAuthToken = agentService.refreshAgentAuthToken();
    final Agent agent = Agent(
      agentId: agentId,
      capabilities: capabilities,
      healthCheckTimestamp: DateTime.now().millisecondsSinceEpoch,
      authToken: agentAuthToken.hash,
      isHealthy: false,
      key: key,
    );

    await datastore.db.commit(inserts: <Agent>[agent]);

    return CreateAgentResponse(agentAuthToken.value);
  }
}

@immutable
class CreateAgentResponse extends JsonBody {
  const CreateAgentResponse(this.token) : assert(token != null);

  final String token;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Token': token,
    };
  }
}
