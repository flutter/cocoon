// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/devicelab/manifest.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';

/// Queries GitHub for the list of recent commits according to different branches,
/// and creates corresponding rows in the cloud datastore and the BigQuery for any commits
///  not yet there. Then creates new task rows in the datastore for any commits that
/// were added. The task rows that it creates are driven by the Flutter [Manifest].
@immutable
class RefreshGithubCommits extends ApiRequestHandler<Body> {
  const RefreshGithubCommits(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting this.httpClientProvider = Providers.freshHttpClient,
    @visibleForTesting
        this.branchHttpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : assert(datastoreProvider != null),
        assert(httpClientProvider != null),
        assert(branchHttpClientProvider != null),
        assert(gitHubBackoffCalculator != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final HttpClientProvider httpClientProvider;
  final HttpClientProvider branchHttpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  @override
  Future<Body> get() async {
    const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GithubService githubService = await config.createGithubService();
    final DatastoreService datastore = datastoreProvider(config.db);

    for (String branch in await config.flutterBranches) {
      // TODO(keyonghan): use time of latest commit for [hours] in github API query, https://github.com/flutter/flutter/issues/54284
      int hours = config.existingBranchHours;

      if (branch != 'master') {
        final Set<Commit> commits = await datastore
            .queryRecentCommits(limit: 1, branch: branch)
            .toSet();

        /// Set [hours] to be longer if a new branch is found.
        if (commits.isEmpty) {
          hours = config.newBranchHours;
        }
      }

      final List<RepositoryCommit> commits =
          await githubService.listCommits(slug, branch, hours, config);
      final List<Commit> newCommits =
          await _getNewCommits(commits, datastore, branch);

      if (newCommits.isEmpty) {
        // Nothing to do.
        continue;
      }
      log.debug(
          'Found ${newCommits.length} new commits for branch $branch on GitHub');

      //Save [Commit] to BigQuery and create [Task] in Datastore.
      await _saveData(newCommits, datastore);
    }

    return Body.empty;
  }

  Future<void> _saveData(
    List<Commit> newCommits,
    DatastoreService datastore,
  ) async {
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Checklist';

    final TabledataResourceApi tabledataResourceApi =
        await config.createTabledataResourceApi();
    final List<Map<String, Object>> tableDataInsertAllRequestRows =
        <Map<String, Object>>[];

    for (Commit commit in newCommits) {
      /// Consolidate [commits] together
      ///
      /// Prepare for bigquery [insertAll]
      tableDataInsertAllRequestRows.add(<String, Object>{
        'json': <String, Object>{
          'ID': commit.id,
          'CreateTimestamp': commit.timestamp,
          'FlutterRepositoryPath': commit.repository,
          'CommitSha': commit.sha,
          'CommitAuthorLogin': commit.author,
          'CommitAuthorAvatarURL': commit.authorAvatarUrl,
          'Branch': commit.branch,
        },
      });

      final List<Task> tasks = await _createTasks(
        commitKey: commit.key,
        sha: commit.sha,
        createTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      try {
        await datastore.withTransaction<void>((Transaction transaction) async {
          transaction.queueMutations(inserts: <Commit>[commit]);
          transaction.queueMutations(inserts: tasks);
          await transaction.commit();
          log.debug(
              'Committed ${tasks.length} new tasks for commit ${commit.sha}');
        });
      } catch (error) {
        log.warning('Failed to add commit ${commit.sha}: $error');
      }
    }

    /// Final [rows] to be inserted to [BigQuery]
    final TableDataInsertAllRequest rows = TableDataInsertAllRequest.fromJson(
        <String, Object>{'rows': tableDataInsertAllRequestRows});

    /// Insert [commits] to [BigQuery]
    try {
      await tabledataResourceApi.insertAll(rows, projectId, dataset, table);
    } catch (ApiRequestError) {
      log.warning('Failed to add commits to BigQuery: $ApiRequestError');
    }
  }

  Future<List<Commit>> _getNewCommits(List<RepositoryCommit> commits,
      DatastoreService datastore, String branch) async {
    final List<Commit> newCommits = <Commit>[];
    for (RepositoryCommit commit in commits) {
      final String id = 'flutter/flutter/$branch/${commit.sha}';
      final Key key = datastore.db.emptyKey.append(Commit, id: id);

      // TODO(keyonghan): remove old Key check, https://github.com/flutter/flutter/issues/52503
      final String oldId = 'flutter/flutter/${commit.sha}';
      final Key oldKey = datastore.db.emptyKey.append(Commit, id: oldId);

      if (await datastore.db.lookupValue<Commit>(key, orElse: () => null) ==
              null &&
          await datastore.db.lookupValue<Commit>(oldKey, orElse: () => null) ==
              null) {
        newCommits.add(Commit(
          key: key,
          timestamp: commit.commit.committer.date.millisecondsSinceEpoch,
          repository: 'flutter/flutter',
          sha: commit.sha,
          author: commit.author.login,
          authorAvatarUrl: commit.author.avatarUrl,
          branch: branch,
        ));
      } else {
        // Once we've found a commit that's already been recorded, we stop looking.
        break;
      }
    }
    return newCommits;
  }

  Future<List<Task>> _createTasks({
    @required Key commitKey,
    @required String sha,
    @required int createTimestamp,
  }) async {
    Task newTask(
      String name,
      String stageName,
      List<String> requiredCapabilities,
      bool isFlaky,
      int timeoutInMinutes,
    ) {
      return Task(
        key: commitKey.append(Task),
        commitKey: commitKey,
        createTimestamp: createTimestamp,
        startTimestamp: 0,
        endTimestamp: 0,
        name: name,
        attempts: 0,
        isFlaky: isFlaky,
        timeoutInMinutes: timeoutInMinutes,
        requiredCapabilities: requiredCapabilities,
        stageName: stageName,
        status: Task.statusNew,
      );
    }

    final List<Task> tasks = <Task>[
      // These built-in tasks are not listed in the manifest.
      newTask('cirrus', 'cirrus', <String>['can-update-github'], false, 0),
      newTask(
          'mac_bot', 'chromebot', <String>['can-update-chromebots'], false, 0),
      newTask('linux_bot', 'chromebot', <String>['can-update-chromebots'],
          false, 0),
      newTask('windows_bot', 'chromebot', <String>['can-update-chromebots'],
          false, 0),
    ];

    final YamlMap yaml = await _loadDevicelabManifest(sha);
    final Manifest manifest = Manifest.fromJson(yaml);
    manifest.tasks.forEach((String taskName, ManifestTask info) {
      tasks.add(newTask(
        taskName,
        info.stage,
        info.requiredAgentCapabilities,
        info.isFlaky,
        info.timeoutInMinutes,
      ));
    });

    return tasks;
  }

  Future<YamlMap> _loadDevicelabManifest(String sha) async {
    final String path = '/flutter/flutter/$sha/dev/devicelab/manifest.yaml';
    final Uri url = Uri.https('raw.githubusercontent.com', path);

    final HttpClient client = httpClientProvider();
    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        final HttpClientRequest clientRequest = await client.getUrl(url);

        try {
          final HttpClientResponse clientResponse = await clientRequest.close();
          final int status = clientResponse.statusCode;

          if (status == HttpStatus.ok) {
            final String content =
                await utf8.decoder.bind(clientResponse).join();
            return loadYaml(content) as YamlMap;
          } else {
            log.warning(
                'Attempt to download manifest.yaml failed (HTTP $status)');
          }
        } catch (error, stackTrace) {
          log.error(
              'Attempt to download manifest.yaml failed:\n$error\n$stackTrace');
        }

        await Future<void>.delayed(gitHubBackoffCalculator(attempt));
      }
    } finally {
      client.close(force: true);
    }

    log.error('GitHub not responding; giving up');
    response.headers.set(HttpHeaders.retryAfterHeader, '120');
    throw HttpStatusException(
        HttpStatus.serviceUnavailable, 'GitHub not responding');
  }
}
