// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class UpdateAgentHealth extends ApiRequestHandler<Body> {
  const UpdateAgentHealth(
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String agentIdParam = 'AgentID';
  static const String isHealthyParam = 'IsHealthy';
  static const String healthDetailsParam = 'HealthDetails';

  @override
  Future<Body> post() async {
    checkRequiredParameters(<String>[isHealthyParam, healthDetailsParam]);

    final bool isHealthy = requestData[isHealthyParam];
    final String healthDetails = requestData[healthDetailsParam];
    final DatastoreService datastore = datastoreProvider();

    final Query<Agent> query = datastore.db.query<Agent>()
      ..filter('agentid =', requestData[agentIdParam]);
    final List<Agent> agents = await query.run().toList();
    assert(agents.length <= 1);
    if (agents.isEmpty) {
      return Body.empty;
    }
    final Agent agent = agents.single;
    agent.isHealthy = isHealthy;
    agent.healthDetails = healthDetails;
    agent.healthCheckTimestamp = DateTime.now().millisecondsSinceEpoch;

    await datastore.db.commit(inserts: <Agent>[agent]);

    return Body.forJson(<String, dynamic>{
      'Agent': agent.agentId,
      'Healthy': agent.isHealthy,
      'Details': agent.healthDetails,
    });
  }
}