// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/agent_service.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/agent_service.dart';
import '../service/datastore.dart';

@immutable
class AuthorizeAgent extends ApiRequestHandler<AuthorizeAgentResponse> {
  const AuthorizeAgent(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String agentIdParam = 'AgentID';

  @override
  Future<AuthorizeAgentResponse> post() async {
    checkRequiredParameters(<String>[agentIdParam]);

    final String agentId = requestData[agentIdParam];
    final DatastoreService datastore = datastoreProvider();
    final AgentService agentService = AgentService();
    final Key key = datastore.db.emptyKey.append(Agent, id: agentId);
    final Agent agent = await datastore.db.lookupValue<Agent>(
      key,
      orElse: () {
        throw BadRequestException('Invalid agent ID: $agentId');
      },
    );

    agent.authToken = agentService.refreshAgentAuthToken();
    
    await datastore.db.commit(inserts: <Agent>[agent]);

    return AuthorizeAgentResponse(agent);
  }
}

@immutable
class AuthorizeAgentResponse extends JsonBody {
  const AuthorizeAgentResponse(this.agent) : assert(agent != null);

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
