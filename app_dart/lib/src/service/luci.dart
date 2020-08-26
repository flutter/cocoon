// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../model/luci/buildbucket.dart';
import '../request_handling/api_request_handler.dart';

import 'buildbucket.dart';

part 'luci.g.dart';

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

typedef LuciServiceProvider = LuciService Function(ApiRequestHandler<dynamic> handler);

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

  /// The Cocoon configuration. Guaranteed to be non-null.
  final Config config;

  /// The AppEngine context to use for requests. Guaranteed to be non-null.
  final ClientContext clientContext;

  /// Gets the list of recent LUCI tasks, broken out by the [BranchLuciBuilder]
  ///  that owns them.
  ///
  /// The list of known LUCI builders is specified in [LuciBuilder.all].
  Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>> getBranchRecentTasks({
    String repo,
    bool requireTaskName = false,
  }) async {
    assert(requireTaskName != null);
    final List<LuciBuilder> builders = await LuciBuilder.getProdBuilders(repo, config);
    final Iterable<Build> builds = await getBuilds(repo, requireTaskName, builders);

    final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> results =
        <BranchLuciBuilder, Map<String, List<LuciTask>>>{};
    for (Build build in builds) {
      final String commit = build.input?.gitilesCommit?.hash ?? 'unknown';
      final String ref = build.input?.gitilesCommit?.ref ?? 'unknown';
      final LuciBuilder builder = builders.singleWhere((LuciBuilder builder) {
        return builder.name == build.builderId.builder;
      });
      final String branch = ref == 'unknown' ? 'unknown' : ref.split('/')[2];
      final BranchLuciBuilder branchLuciBuilder = BranchLuciBuilder(
        luciBuilder: builder,
        branch: branch,
      );
      results[branchLuciBuilder] ??= <String, List<LuciTask>>{};
      results[branchLuciBuilder][commit] ??= <LuciTask>[];
      results[branchLuciBuilder][commit].add(LuciTask(
          commitSha: commit,
          ref: ref,
          status: _luciStatusToTaskStatus[build.status],
          buildNumber: build.number,
          builderName: build.builderId.builder));
    }
    return results;
  }

  /// Gets the list of recent LUCI tasks, broken out by the [LuciBuilder] that
  /// owns them.
  ///
  /// The list of known LUCI builders is specified in [LuciBuilder.all].
  Future<Map<LuciBuilder, List<LuciTask>>> getRecentTasks({
    String repo,
    bool requireTaskName = false,
  }) async {
    assert(requireTaskName != null);
    final List<LuciBuilder> builders = await LuciBuilder.getProdBuilders(repo, config);
    final Iterable<Build> builds = await getBuilds(repo, requireTaskName, builders);

    final Map<LuciBuilder, List<LuciTask>> results = <LuciBuilder, List<LuciTask>>{};
    for (Build build in builds) {
      final String commit = build.input?.gitilesCommit?.hash ?? 'unknown';
      final String ref = build.input?.gitilesCommit?.ref ?? 'unknown';
      final LuciBuilder builder = builders.singleWhere((LuciBuilder builder) {
        return builder.name == build.builderId.builder;
      });
      results[builder] ??= <LuciTask>[];
      results[builder].add(LuciTask(
        commitSha: commit,
        ref: ref,
        status: _luciStatusToTaskStatus[build.status],
        buildNumber: build.number,
        builderName: build.builderId.builder,
      ));
    }
    return results;
  }

  /// Gets list of [build] for [repo] and available Luci [builders]
  /// predefined in cocoon config.
  ///
  /// Latest builds of each builder will be returned from new to old.
  Future<Iterable<Build>> getBuilds(String repo, bool requireTaskName, List<LuciBuilder> builders) async {
    final BuildBucketClient buildBucketClient = BuildBucketClient();

    bool includeBuilder(LuciBuilder builder) {
      if (repo != null && builder.repo != repo) {
        return false;
      }
      if (requireTaskName && builder.taskName == null) {
        return false;
      }
      return true;
    }

    final List<Request> searchRequests = builders.where(includeBuilder).map<Request>((LuciBuilder builder) {
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
    }).toList();
    final BatchRequest batchRequest = BatchRequest(requests: searchRequests);
    final BatchResponse batchResponse = await buildBucketClient.batch(batchRequest);
    final Iterable<Build> builds = batchResponse.responses
        .map<SearchBuildsResponse>((Response response) => response.searchBuilds)
        .expand<Build>((SearchBuildsResponse response) => response.builds);
    return builds;
  }
}

@immutable
class BranchLuciBuilder {
  const BranchLuciBuilder({
    this.luciBuilder,
    this.branch,
  });

  final String branch;
  final LuciBuilder luciBuilder;

  @override
  int get hashCode => '${luciBuilder.toString()},$branch'.hashCode;

  @override
  bool operator ==(Object other) =>
      other is BranchLuciBuilder &&
      other.luciBuilder.name == luciBuilder.name &&
      other.luciBuilder.taskName == luciBuilder.taskName &&
      other.luciBuilder.repo == luciBuilder.repo &&
      other.luciBuilder.flaky == luciBuilder.flaky;
}

@immutable
@JsonSerializable()
class LuciBuilder {
  const LuciBuilder({
    @required this.name,
    @required this.repo,
    @required this.flaky,
    this.enabled,
    this.runIf,
    this.taskName,
  }) : assert(name != null);

  /// Create a new [LuciBuilder] object from its JSON representation.
  factory LuciBuilder.fromJson(Map<String, dynamic> json) => _$LuciBuilderFromJson(json);

  /// The name of this builder.
  @JsonKey(required: true, disallowNullValue: true)
  final String name;

  /// The name of the repository for which this builder runs.
  @JsonKey(required: true, disallowNullValue: true)
  final String repo;

  /// Flag the result of this builder as blocker or not.
  @JsonKey()
  final bool flaky;

  /// Flag if this builder is enabled or not.
  @JsonKey(name: 'enabled')
  final bool enabled;

  /// Globs to filter changed files to trigger builders.
  @JsonKey(name: 'run_if')
  final List<String> runIf;

  /// The name of the devicelab task associated with this builder.
  @JsonKey(name: 'task_name')
  final String taskName;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$LuciBuilderToJson(this);

  /// Loads and returns the list of known builders from the Cocoon [config].
  static Future<List<LuciBuilder>> getProdBuilders(String repo, Config config) async {
    return await config.luciBuilders('prod', repo);
  }
}

@immutable
class LuciTask {
  const LuciTask(
      {@required this.commitSha,
      @required this.ref,
      @required this.status,
      @required this.buildNumber,
      @required this.builderName})
      : assert(commitSha != null),
        assert(ref != null),
        assert(status != null),
        assert(buildNumber != null),
        assert(builderName != null);

  /// The GitHub commit at which this task is being run.
  final String commitSha;

  // The GitHub ref at which this task is being run.
  final String ref;

  /// The status of this task. See the [Task] class for supported values.
  final String status;

  /// The build number of this task.
  final int buildNumber;

  /// The builder name of this task.
  final String builderName;
}
