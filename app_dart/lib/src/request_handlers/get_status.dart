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
import '../model/appengine/key_helper.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';

@immutable
class GetStatus extends RequestHandler<Body> {
  const GetStatus(
    Config config, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting BuildStatusProvider buildStatusProvider,
  })  : buildStatusProvider =
            buildStatusProvider ?? const BuildStatusProvider(),
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusProvider buildStatusProvider;

  static const String lastCommitKeyParam = 'lastCommitKey';

  @override
  Future<Body> get() async {
    final String encodedLastCommitKey =
        request.uri.queryParameters[lastCommitKeyParam];
    final DatastoreService datastore = datastoreProvider();
    final KeyHelper keyHelper = config.keyHelper;
    final int commitNumber = config.commitNumber;

    /// [timestamp] is initially set as the current time, which allows query return
    /// latest commit list. If [owerKeyParam] is not empty, [timestamp] will be set
    /// as the timestamp of that [commit], and the query will return lastest commit
    /// list whose timestamp is smaller than [timestamp].
    final int timestamp =
        await _obtainTimestamp(encodedLastCommitKey, keyHelper, datastore);

    final List<SerializableCommitStatus> statuses = await buildStatusProvider
        .retrieveCommitStatus(limit: commitNumber, timestamp: timestamp)
        .map<SerializableCommitStatus>((CommitStatus status) =>
            SerializableCommitStatus(
                status, keyHelper.encode(status.commit.key)))
        .toList();

    final Query<Agent> agentQuery = datastore.db.query<Agent>()
      ..order('agentId');
    final List<Agent> agents =
        await agentQuery.run().where(_isVisible).toList();
    agents.sort((Agent a, Agent b) =>
        compareAsciiLowerCaseNatural(a.agentId, b.agentId));

    return Body.forJson(<String, dynamic>{
      'Statuses': statuses,
      'AgentStatuses': agents,
    });
  }

  Future<int> _obtainTimestamp(String encodedLastCommitKey, KeyHelper keyHelper,
      DatastoreService datastore) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    if (encodedLastCommitKey != null) {
      final Key ownerKey = keyHelper.decode(encodedLastCommitKey);
      final Commit commit =
          await datastore.db.lookupValue<Commit>(ownerKey, orElse: () => null);

      timestamp = commit?.timestamp;
    }
    return timestamp;
  }

  static bool _isVisible(Agent agent) => !agent.isHidden;
}

/// The serialized representation of a [CommitStatus].
// TODO(tvolkert): Directly serialize [CommitStatus] once frontends migrate to new format.
class SerializableCommitStatus {
  const SerializableCommitStatus(this.status, this.key);

  final CommitStatus status;
  final String key;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Checklist': <String, dynamic>{
        'Key': key,
        'Checklist': SerializableCommit(status.commit).facade,
      },
      'Stages': status.stages,
    };
  }
}
