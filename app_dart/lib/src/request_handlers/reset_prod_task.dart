// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/google/token_info.dart';
import '../model/luci/buildbucket.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import '../service/logging.dart';
import '../service/luci.dart';

/// Triggers prod builds based on a task key. This handler is used to trigger
/// LUCI builds that didn't run or failed.
@immutable
class ResetProdTask extends ApiRequestHandler<Body> {
  const ResetProdTask(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.luciBuildService,
    this.scheduler, {
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LuciBuildService luciBuildService;
  final Scheduler scheduler;

  static const String taskKeyParam = 'Key';
  static const String ownerParam = 'Owner';
  static const String repoParam = 'Repo';
  static const String commitShaParam = 'Commit';
  static const String builderParam = 'Builder';
  static const String propertiesParam = 'Properties';

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final String encodedKey = requestData![taskKeyParam] as String? ?? '';
    final KeyHelper keyHelper = config.keyHelper;
    final String owner = requestData![ownerParam] as String? ?? 'flutter';
    final String repo = requestData![repoParam] as String? ?? 'flutter';
    String commitSha = requestData![commitShaParam] as String? ?? '';
    final Map<String, dynamic> defaultProperties =
        repo == 'engine' ? Config.engineDefaultProperties : const <String, dynamic>{};
    final Map<String, dynamic> properties =
        (requestData![propertiesParam] as Map<String, dynamic>?) ?? defaultProperties;
    final TokenInfo token = await tokenInfo(request!);

    RepositorySlug slug;
    String? builder = requestData![builderParam] as String? ?? '';
    Task? task;
    Commit commit;

    if (encodedKey.isNotEmpty) {
      // Check params required for dashboard.
      checkRequiredParameters(<String>[taskKeyParam]);
    } else {
      // Checks params required when this API is called with curl.
      checkRequiredParameters(<String>[commitShaParam, builderParam, repoParam]);
    }

    if (encodedKey.isNotEmpty) {
      // Request coming from the dashboard.
      final Key<int> key = keyHelper.decode(encodedKey) as Key<int>;
      log.info('Rescheduling task with Key: ${key.id}');
      task = (await datastore.lookupByKey<Task>(<Key<int>>[key])).single;
      if (task!.status == 'Succeeded') {
        return Body.empty;
      }
      commit = await datastore.db.lookupValue<Commit>(task.commitKey!);
      slug = commit.slug;
      commitSha = commit.sha!;
      builder = task.builderName;
      if (builder == null) {
        final CiYaml ciYaml = await scheduler.getCiYaml(commit);
        final List<LuciBuilder> builders = await scheduler.getPostSubmitBuilders(ciYaml);
        builder = builders
            .where((LuciBuilder builder) => builder.taskName == task!.name)
            .map((LuciBuilder builder) => builder.name)
            .single;
      }
    } else {
      if (repo == 'flutter') {
        throw const BadRequestException(
            'Flutter repo does not support retries with curl, please use flutter-dashboard instead');
      }
      // Request not coming from dashboard means we need to create slug from parameters.
      slug = RepositorySlug(owner, repo);
      commit = Commit(repository: slug.fullName, sha: commitSha);
    }

    final Iterable<Build> currentBuilds = await luciBuildService.getProdBuilds(slug, commit.sha!, builder, repo);
    final List<Status> noReschedule = <Status>[Status.started, Status.scheduled, Status.success];
    final Build? build = currentBuilds.firstWhereOrNull(
      (Build element) {
        log.info('Found build status: ${element.status} inNoReschedule ${noReschedule.contains(element.status)}');
        return noReschedule.contains(element.status);
      },
    );
    log.info('Owner: $owner, Repo: $repo, Builder: $builder, CommitSha: ${commit.sha}, Build: $build');

    if (build != null) {
      throw const ConflictException();
    }
    final Map<String, List<String?>> tags = <String, List<String?>>{
      'triggered_by': <String?>[token.email],
      'trigger_type': <String>['manual'],
    };
    final Build buildResult = await luciBuildService.reschedulePostsubmitBuild(
      commitSha: commit.sha!,
      builderName: builder,
      repo: repo,
      properties: properties,
      tags: tags,
      bucket: task?.isFlaky ?? false ? 'staging' : 'prod',
    );
    if (task != null) {
      // Only try to update task when it really exists.
      task
        ..status = Task.statusNew
        ..startTimestamp = 0
        ..attempts = (task.attempts ?? 0) + 1;
      await datastore.insert(<Task>[task]);
    }
    final String buildUrl = 'https://ci.chromium.org/ui/b/${buildResult.id}';
    return Body.forString('Build url: $buildUrl');
  }
}
