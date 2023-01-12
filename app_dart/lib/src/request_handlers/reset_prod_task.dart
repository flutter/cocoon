// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/google/token_info.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/luci_build_service.dart';
import '../service/scheduler.dart';

/// Reruns a postsubmit LUCI build.
///
/// Expects either [taskKeyParam] or a set of params that give enough detail to lookup a task in datastore.
@immutable
class ResetProdTask extends ApiRequestHandler<Body> {
  const ResetProdTask({
    required super.config,
    required super.authenticationProvider,
    required this.luciBuildService,
    required this.scheduler,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
  }) : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider;

  final DatastoreServiceProvider datastoreProvider;
  final LuciBuildService luciBuildService;
  final Scheduler scheduler;

  static const String branchParam = 'Branch';
  static const String taskKeyParam = 'Key';
  static const String ownerParam = 'Owner';
  static const String repoParam = 'Repo';
  static const String commitShaParam = 'Commit';
  static const String builderParam = 'Builder';

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final String? encodedKey = requestData![taskKeyParam] as String?;
    String? gitBranch = requestData![branchParam] as String?;
    final String owner = requestData![ownerParam] as String? ?? 'flutter';
    final String? repo = requestData![repoParam] as String?;
    final String? sha = requestData![commitShaParam] as String?;
    final TokenInfo token = await tokenInfo(request!);
    final String? taskName = requestData![builderParam] as String?;

    RepositorySlug? slug;

    if (encodedKey != null && encodedKey.isNotEmpty) {
      // Check params required for dashboard.
      checkRequiredParameters(<String>[taskKeyParam]);
    } else {
      // Checks params required when this API is called with curl.
      checkRequiredParameters(<String>[commitShaParam, builderParam, repoParam]);
      slug = RepositorySlug(owner, repo!);
      gitBranch ??= Config.defaultBranch(slug);
    }

    final Task task = await _getTaskFromNamedParams(
      datastore: datastore,
      encodedKey: encodedKey,
      gitBranch: gitBranch,
      name: taskName,
      sha: sha,
      slug: slug,
    );
    final Commit commit = await _getCommitFromTask(datastore, task);

    final CiYaml ciYaml = await scheduler.getCiYaml(commit);
    final Target target = ciYaml.postsubmitTargets.singleWhere((Target target) => target.value.name == task.name);

    final Map<String, List<String>> tags = <String, List<String>>{
      'triggered_by': <String>[token.email!],
      'trigger_type': <String>['manual'],
    };
    final bool isRerunning = await luciBuildService.checkRerunBuilder(
      commit: commit,
      task: task,
      target: target,
      datastore: datastore,
      tags: tags,
      ignoreChecks: true,
    );
    if (isRerunning == false) {
      throw InternalServerError('Failed to rerun ${task.name}');
    }

    return Body.empty;
  }

  /// Retrieve [Task] from [DatastoreService] from either an encoded key or commit + task name info.
  ///
  /// If [encodedKey] is passed, [KeyHelper] will decode it directly and return the associated entity.
  ///
  /// Otherwise, [name], [gitBranch], [sha], and [slug] must be passed to find the [Task].
  Future<Task> _getTaskFromNamedParams({
    required DatastoreService datastore,
    String? encodedKey,
    String? gitBranch,
    String? name,
    String? sha,
    RepositorySlug? slug,
  }) async {
    if (encodedKey != null && encodedKey.isNotEmpty) {
      final Key<int> key = config.keyHelper.decode(encodedKey) as Key<int>;
      return datastore.lookupByValue<Task>(key);
    }

    final Commit commit = await datastore.findCommit(gitBranch: gitBranch!, sha: sha!, slug: slug!);
    return await datastore.findTask(commitKey: commit.key, name: name!);
  }

  /// Returns the [Commit] associated with [Task].
  Future<Commit> _getCommitFromTask(DatastoreService datastore, Task task) async {
    return (await datastore.lookupByKey<Commit>(<Key<dynamic>>[task.parentKey!])).single!;
  }
}
