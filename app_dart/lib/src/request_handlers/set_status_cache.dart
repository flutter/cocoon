// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonEncode, utf8;

import 'package:collection/collection.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/agent.dart';
import '../model/appengine/commit.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';

@immutable
class SetStatusCache extends RequestHandler<Body> {
  const SetStatusCache(
    Config config, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting BuildStatusProvider buildStatusProvider,
  })  : buildStatusProvider =
            buildStatusProvider ?? const BuildStatusProvider(),
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusProvider buildStatusProvider;

  @override
  Future<Body> get() async {
    final List<SerializableCommitStatus> statuses = await buildStatusProvider
        .retrieveCommitStatus()
        .map<SerializableCommitStatus>(
            (CommitStatus status) => SerializableCommitStatus(status))
        .toList();

    final DatastoreService datastore = datastoreProvider();
    final Query<Agent> agentQuery = datastore.db.query<Agent>()
      ..order('agentId');
    final List<Agent> agents =
        await agentQuery.run().where(_isVisible).toList();
    agents.sort((Agent a, Agent b) =>
        compareAsciiLowerCaseNatural(a.agentId, b.agentId));

    // TODO(chillers): Split these into separate endpoints when Flutter app is used for production. https://github.com/flutter/cocoon/issues/472
    final Map<String, dynamic> jsonResponse = <String, dynamic>{
      'Statuses': statuses,
      'AgentStatuses': agents,
    };

    final Body response = Body.forJson(jsonResponse);

    final CacheProvider<List<int>> cacheProvider =
        Cache.redisCacheProvider('redis://10.0.0.4:6379');
    final Cache<List<int>> cache = Cache<List<int>>(cacheProvider);

    final Cache<String> statusCache = cache.withPrefix('responses').withCodec(utf8);

    await statusCache['get-status']
        .set(jsonEncode(jsonResponse), const Duration(minutes: 5));

    await cacheProvider.close();

    return response;
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
