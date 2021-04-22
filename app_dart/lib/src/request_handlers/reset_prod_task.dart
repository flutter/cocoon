// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../model/appengine/key_helper.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

/// Triggers prod builds based on a task key. This handler is used to trigger
/// LUCI builds that didn't run or failed.
@immutable
class ResetProdTask extends ApiRequestHandler<Body> {
  const ResetProdTask(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.luciBuildService, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LuciBuildService luciBuildService;

  static const String taskKeyParam = 'Key';
  static const String ownerParam = 'Owner';
  static const String repoParam = 'Repo';

  @override
  Future<Body> post() async {
    checkRequiredParameters(<String>[taskKeyParam]);
    final DatastoreService datastore = datastoreProvider(config.db);
    final String encodedKey = requestData[taskKeyParam] as String;
    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper = KeyHelper(applicationContext: clientContext.applicationContext);
    final String owner = requestData[ownerParam] as String ?? 'flutter';
    final String repo = requestData[repoParam] as String ?? '';
    final Key<int> key = keyHelper.decode(encodedKey) as Key<int>;
    log.info('Rescheduling task with Key: ${key.id}');
    final Task task = (await datastore.lookupByKey<Task>(<Key<int>>[key])).single;
    if (task == null) {
      throw BadRequestException('No such task: $key');
    }
    // Task is complete and it succeeded, nothing to do here.
    if (task.status == 'Succeeded') {
      return Body.empty;
    }
    final Commit commit = await datastore.db.lookupValue<Commit>(task.commitKey, orElse: () {
      throw BadRequestException('No such commit: ${task.commitKey}');
    });
    String builder = task.builderName;
    if (builder == null) {
      final List<LuciBuilder> builders = await config.luciBuilders('prod', 'flutter');
      builder = builders
          .where((LuciBuilder builder) => builder.taskName == task.name)
          .map((LuciBuilder builder) => builder.name)
          .single;
    }
    final RepositorySlug slug = RepositorySlug(owner, repo);
    final Build currentBuild = await luciBuildService.getBuild(slug, commit.sha, builder, 'prod');
    log.info('Owner: $owner, Repo: $repo, Builder: $builder');
    final List<Status> noReschedule = <Status>[Status.started, Status.scheduled, Status.success];
    if (currentBuild != null && noReschedule.contains(currentBuild.status)) {
      throw const ConflictException();
    }
    await luciBuildService.rescheduleProdBuild(
      commitSha: commit.sha,
      builderName: builder,
    );
    task
      ..status = Task.statusNew
      ..startTimestamp = 0
      ..attempts += 1;
    await datastore.insert(<Task>[task]);
    return Body.empty;
  }
}
