// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';

const List<String> _failedStates = <String>['error', 'failure'];
const List<String> _inProgressStates = <String>['pending'];

@immutable
class RefreshCirrusStatus extends ApiRequestHandler<RefreshCirrusStatusResponse> {
  const RefreshCirrusStatus(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<RefreshCirrusStatusResponse> get() async {
    final DatastoreService datastore = datastoreProvider();
    final GitHub github = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GithubService githubService = GithubService(github, slug);

    int number = 0;
    int iter = 0;
    //Map<String, dynamic> statusJson;

    await for (FullTask task in datastore.queryRecentTasks(taskName: 'cirrus', commitLimit: 15)) {
      final String sha = task.commit.sha;
      final String existingTaskStatus = task.task.status;
      log.debug('Found Cirrus task for commit $sha with existing status $existingTaskStatus');
      final Map<String, RepositoryStatus> mostRecentStatuses = <String, RepositoryStatus>{};

      //String test = githubService.helper(sha);
      //statusJson = json.decode(await githubService.checkRuns(slug, sha));
      number = (await githubService.checkRuns(slug, sha)).length;
      return RefreshCirrusStatusResponse(number);
      
      await for (RepositoryStatus status in github.repositories.listStatuses(slug, sha)) {
        iter += 1;
        final bool isCirrusStatus = status.targetUrl.contains('cirrus-ci.com');
        if (isCirrusStatus) {
          final String taskName = status.context;
          log.debug('Found Cirrus build status for $sha: $taskName (${status.state})');
          final RepositoryStatus existingStatus = mostRecentStatuses[taskName];
          if (existingStatus == null || existingStatus.updatedAt.isBefore(status.updatedAt)) {
            mostRecentStatuses[taskName] = status;
          }
        }
      }

      if (number == 0) {
        number = iter;
        return RefreshCirrusStatusResponse(number);
      }

      final Iterable<String> states =
          mostRecentStatuses.values.map<String>((RepositoryStatus status) => status.state);
      String newTaskStatus;
      if (states.isEmpty) {
        newTaskStatus = Task.statusNew;
      } else if (states.any(_failedStates.contains)) {
        newTaskStatus = Task.statusFailed;
      } else if (states.any(_inProgressStates.contains)) {
        newTaskStatus = Task.statusInProgress;
      } else {
        newTaskStatus = Task.statusSucceeded;
      }

      if (newTaskStatus != existingTaskStatus) {
        task.task.status = newTaskStatus;
        await config.db.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: <Task>[task.task]);
          await transaction.commit();
        });
      }
    }

    //return Body.empty;
    return RefreshCirrusStatusResponse(number);
  }
}


@immutable
class RefreshCirrusStatusResponse extends JsonBody {
  const RefreshCirrusStatusResponse(this.number) : assert(number != null);

  final int number;
  //final Map<String, dynamic> statusJson;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Number': number,
      //'total_count': statusJson['total_count'],
      //'check_runs': statusJson['check_runs']
    };
  }
}