// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../model/luci/buildbucket.dart';

import 'buildbucket.dart';

const int _maxResults = 40;
const Map<Status, String> _luciStatusToTaskStatus = <Status, String>{
  Status.unspecified: Task.statusInProgress,
  Status.scheduled: Task.statusInProgress,
  Status.started: Task.statusInProgress,
  Status.canceled: Task.statusSkipped,
  Status.success: Task.statusSucceeded,
  Status.failure: Task.statusFailed,
  Status.infraFailure: Task.statusFailed,
};

/// Service class for interacting with LUCI.
@immutable
class LuciService {
  /// Creates a new [LuciService].
  ///
  /// The [config] and [clientContext] arguments must not be null.
  const LuciService({
    @required this.config,
    @required this.clientContext,
  })  : assert(config != null),
        assert(clientContext != null);

  /// The Cocoon configuration. Guaranteed to bne non-null.
  final Config config;

  /// The AppEngine context to use for requests. Guaranteed to bne non-null.
  final ClientContext clientContext;

  /// Gets the list of recent LUCI tasks, broken out by the [LuciBuilder] that
  /// owns them.
  ///
  /// The list of known LUCI builders is specified in [LuciBuilder.all].
  Future<Map<LuciBuilder, List<LuciTask>>> getRecentTasks() async {
    final BuildBucketClient buildBucketClient = BuildBucketClient(clientContext);

    final List<LuciBuilder> builders = await LuciBuilder.getBuilders(config);
    final List<Request> searchRequests = builders.map<Request>((LuciBuilder builder) {
      return Request(
        searchBuilds: SearchBuildsRequest(
          pageSize: _maxResults,
          predicate: BuildPredicate(
            builderId: BuilderId(
              project: 'flutter',
              bucket: 'prod',
              builder: builder.name,
            ),
          ),
        ),
      );
    });
    final BatchRequest batchRequest = BatchRequest(requests: searchRequests);
    final BatchResponse batchResponse = await buildBucketClient.batch(batchRequest);
    final Iterable<Build> builds = batchResponse.responses
        .map<SearchBuildsResponse>((Response response) => response.searchBuilds)
        .expand<Build>((SearchBuildsResponse response) => response.builds);

    final Map<LuciBuilder, List<LuciTask>> results = <LuciBuilder, List<LuciTask>>{};
    for (Build build in builds) {
      final String commit = build.input?.gitilesCommit?.hash ?? 'unknown';
      final LuciBuilder builder = builders.singleWhere((LuciBuilder builder) {
        return builder.name == build.builderId.builder;
      });
      results[builder] ??= <LuciTask>[];
      results[builder].add(LuciTask(
        commitSha: commit,
        status: _luciStatusToTaskStatus[build.status],
      ));
    }
    return results;
  }
}

@immutable
class LuciBuilder {
  const LuciBuilder._(this.name, this.taskName);

  /// The name of this builder.
  final String name;

  /// The name of the devicelab task associated with this builder.
  final String taskName;

  /// Loads and returns the list of known builders from the Cocoon [config].
  static Future<List<LuciBuilder>> getBuilders(Config config) async {
    final Map<String, String> configValues = await config.luciBuilderTaskNames;
    final List<LuciBuilder> builders = <LuciBuilder>[];
    for (MapEntry<String, String> entry in configValues.entries) {
      builders.add(LuciBuilder._(entry.key, entry.value));
    }
    return List<LuciBuilder>.unmodifiable(builders);
  }
}

@immutable
class LuciTask {
  const LuciTask({
    @required this.commitSha,
    @required this.status,
  })  : assert(commitSha != null),
        assert(status != null);

  /// The GitHub commit at which this task is being run.
  final String commitSha;

  /// The status of this task. See the [Task] class for supported values.
  final String status;
}
