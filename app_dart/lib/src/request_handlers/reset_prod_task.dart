// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/ci_yaml/target.dart';
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

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final String encodedKey = requestData![taskKeyParam] as String? ?? '';
    final KeyHelper keyHelper = config.keyHelper;
    final TokenInfo token = await tokenInfo(request!);

    Task? task;
    Commit commit;

    checkRequiredParameters(<String>[taskKeyParam]);

    if (encodedKey.isNotEmpty) {
      // Request coming from the dashboard.
      final Key<int> key = keyHelper.decode(encodedKey) as Key<int>;
      log.info('Rescheduling task with Key: ${key.id}');
      task = (await datastore.lookupByKey<Task>(<Key<int>>[key])).single;
      if (task!.status == 'Succeeded') {
        return Body.empty;
      }
      commit = await datastore.db.lookupValue<Commit>(task.commitKey!);
    } else {
      throw const BadRequestException('Please use https://flutter-dashboard.appspot.com directly for retries');
    }

    final Iterable<Build> currentBuilds = await luciBuildService.getProdBuilds(commit.slug, commit.sha!, task.name);
    final List<Status> noReschedule = <Status>[Status.started, Status.scheduled, Status.success];
    final Build? build = currentBuilds.firstWhereOrNull(
      (Build element) {
        log.info('Found build status: ${element.status} inNoReschedule ${noReschedule.contains(element.status)}');
        return noReschedule.contains(element.status);
      },
    );
    log.info('commit=$commit, task=$task');

    if (build != null) {
      throw const ConflictException();
    }
    final Map<String, List<String>> tags = <String, List<String>>{
      'triggered_by': <String>[token.email!],
      'trigger_type': <String>['manual'],
    };

    final CiYaml ciYaml = await scheduler.getCiYaml(commit);
    final Target target = ciYaml.postsubmitTargets.singleWhere((Target target) => target.value.name == task!.name);

    if (await luciBuildService.checkRerunBuilder(
          commit: commit,
          target: target,
          task: task,
          datastore: datastore,
          tags: tags,
        ) ==
        false) {
      throw InternalServerError('Failed to rerun ${task.name}');
    }
    // Update task to indicate it has been reset.
    task
      ..status = Task.statusNew
      ..startTimestamp = 0
      ..attempts = (task.attempts ?? 0) + 1;
    await datastore.insert(<Task>[task]);
    return Body.empty;
  }
}
