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
class AuthorizeAgent extends ApiRequestHandler<AuthorizeAgentResponse> {
  const AuthorizeAgent(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    this.agentServiceProvider = AgentService.defaultProvider,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final AgentServiceProvider agentServiceProvider;

  static const String agentIdParam = 'AgentID';

  @override
  Future<AuthorizeAgentResponse> post() async {
    checkRequiredParameters(<String>[agentIdParam]);

    final String agentId = requestData[agentIdParam] as String;
    final DatastoreService datastore = datastoreProvider();
    final AgentService agentService = agentServiceProvider();
    final Key key = datastore.db.emptyKey.append(Agent, id: agentId);
    final Agent agent = await datastore.db.lookupValue<Agent>(
      key,
      orElse: () {
        throw BadRequestException('Invalid agent ID: $agentId');
      },
    );

    final AgentAuthToken agentAuthToken = agentService.refreshAgentAuthToken();
    agent.authToken = agentAuthToken.hash;

    await datastore.db.commit(inserts: <Agent>[agent]);

    return AuthorizeAgentResponse(agentAuthToken.value);
  }
}

@immutable
class AuthorizeAgentResponse extends JsonBody {
  const AuthorizeAgentResponse(this.token) : assert(token != null);

  final String token;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Token': token,
    };
  }
}
