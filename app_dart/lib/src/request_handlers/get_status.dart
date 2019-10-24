// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/agent.dart';
import '../model/appengine/commit.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';

@immutable
class GetStatus extends RequestHandler<Body> {
  const GetStatus(
    Config config, {
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting BuildStatusProvider buildStatusProvider,
  })  : buildStatusProvider = buildStatusProvider ?? const BuildStatusProvider(),
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusProvider buildStatusProvider;

  @override
  Future<Body> get() async {
    final List<SerializableCommitStatus> statuses = await buildStatusProvider
        .retrieveCommitStatus()
        .map<SerializableCommitStatus>((CommitStatus status) => SerializableCommitStatus(status))
        .toList();

    final DatastoreService datastore = datastoreProvider();
    final Query<Agent> agentQuery = datastore.db.query<Agent>()..order('agentId');
    final List<Agent> agents = await agentQuery.run().where(_isVisible).toList();
    agents.sort((Agent a, Agent b) => compareAsciiLowerCaseNatural(a.agentId, b.agentId));

    return Body.forJson(<String, dynamic>{
      'Statuses': statuses,
      'AgentStatuses': agents,
    });
  }

  static bool _isVisible(Agent agent) => !agent.isHidden;
}

/// The serialized representation of a [CommitStatus].
// TODO(tvolkert): Directly serialize [CommitStatus] once frontends migrate to new format.
class SerializableCommitStatus {
  const SerializableCommitStatus(this.status);

  final CommitStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Checklist': SerializableCommit(status.commit),
      'Stages': status.stages,
    };
  }
}
