// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/devicelab/manifest.dart';
import '../request_handling/exceptions.dart';
import '../service/luci.dart';
import 'datastore.dart';

/// Scheduler service to validate all commits to supported Flutter repositories.
///
/// Scheduler responsibilties include:
///   1. Tracking commits in Cocoon
///   2. Ensuring commits are validated (via scheduling tasks against commits)
///   3. Retry mechanisms for taskss
class Scheduler {
  Scheduler({
    @required this.config,
    @required this.datastore,
    this.gitHubBackoffCalculator = twoSecondLinearBackoff,
    this.httpClient,
    this.log,
  })  : assert(datastore != null),
        assert(gitHubBackoffCalculator != null);

  final Config config;
  final DatastoreService datastore;
  final HttpClient httpClient;
  final GitHubBackoffCalculator gitHubBackoffCalculator;
  final Logging log;

  /// Ensure [commits] exist in Cocoon.
  ///
  /// If [Commit] does not exist in Datastore:
  ///   * Write it to datastore
  ///   * Schedule tasks listed in its scheduler config
  /// Otherwise, ignore it.
  ///
  /// [commits] is assumed to be sorted in descending order by merged timestamp.
  Future<void> addCommits(List<Commit> commits) async {
    final List<Commit> newCommits = await _getNewCommits(commits);
    log.debug('Found ${newCommits.length} new commits on GitHub');
    for (Commit commit in newCommits) {
      await _addCommit(commit);
    }
  }

  Future<void> _addCommit(Commit commit) async {
    try {
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        await transaction.commit();
        log.debug('Committed commit ${commit.sha}');
      });
      await _scheduleTasks(commit);
    } catch (error) {
      log.error('Failed to add commit ${commit.sha}: $error');
    }

    await _uploadToBigQuery(commit);
  }

  /// Return subset of [commits] not stored in Datastore.
  Future<List<Commit>> _getNewCommits(List<Commit> commits) async {
    final List<Commit> newCommits = <Commit>[];
    // Ensure commits are sorted from newest to oldest
    commits.sort((Commit a, Commit b) => a.timestamp.compareTo(b.timestamp));
    print(commits);
    for (Commit commit in commits) {
      if (await datastore.db.lookupValue<Commit>(commit.key, orElse: () => null) == null) {
        newCommits.add(commit);
      } else {
        // Once we've found a commit that's already been recorded, we stop looking.
        break;
      }
    }

    // Reverses commits to be in order of oldest to newest.
    return newCommits;
  }

  /// Create [Tasks] specified in [commit] scheduler config.
  Future<List<Task>> _scheduleTasks(Commit commit) async {
    Task newTask(
      String name,
      String stageName,
      List<String> requiredCapabilities,
      bool isFlaky,
      int timeoutInMinutes,
    ) {
      return Task(
        key: commit.key.append(Task),
        commitKey: commit.key,
        createTimestamp: commit.timestamp,
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

    final List<Task> tasks = <Task>[];
    final List<LuciBuilder> prodBuilders = await LuciBuilder.getProdBuilders('flutter', config);
    for (LuciBuilder builder in prodBuilders) {
      // These built-in tasks are not listed in the manifest.
      tasks.add(Task.chromebot(commitKey: commit.key, createTimestamp: commit.timestamp, builder: builder));
    }

    final YamlMap yaml = await loadDevicelabManifest(commit);
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

    try {
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
        log.debug('Committed ${tasks.length} new tasks for commit ${commit.sha}');
      });
    } catch (error) {
      log.error('Failed to add commit ${commit.sha}: $error');
    }

    return tasks;
  }

  /// Load in memory the Cocoon Agent DeviceLab scheduler config.
  ///
  // TODO(chillers): Remove when DeviceLab has migrated to LUCI. https://github.com/flutter/flutter/projects/151
  @visibleForTesting
  Future<YamlMap> loadDevicelabManifest(Commit commit) async {
    final String path = '/flutter/flutter/${commit.sha}/dev/devicelab/manifest.yaml';
    final Uri url = Uri.https('raw.githubusercontent.com', path);

    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        final HttpClientRequest clientRequest = await httpClient.getUrl(url);

        try {
          final HttpClientResponse clientResponse = await clientRequest.close();
          final int status = clientResponse.statusCode;

          if (status == HttpStatus.ok) {
            final String content = await utf8.decoder.bind(clientResponse).join();
            return loadYaml(content) as YamlMap;
          } else {
            log.warning('Attempt to download manifest.yaml failed (HTTP $status)');
          }
        } catch (error, stackTrace) {
          log.error('Attempt to download manifest.yaml failed:\n$error\n$stackTrace');
        }

        await Future<void>.delayed(gitHubBackoffCalculator(attempt));
      }
    } finally {
      httpClient.close(force: true);
    }

    log.error('GitHub not responding; giving up');
    throw HttpStatusException(HttpStatus.serviceUnavailable, 'Failed to load $path from GitHub');
  }

  /// Push [Commit] to BigQuery as part of the infra metrics dashboards.
  Future<void> _uploadToBigQuery(Commit commit) async {
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Checklist';

    final TabledataResourceApi tabledataResourceApi = await config.createTabledataResourceApi();
    final List<Map<String, Object>> tableDataInsertAllRequestRows = <Map<String, Object>>[];

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
        'CommitMessage': commit.message,
        'Branch': commit.branch,
      },
    });

    /// Final [rows] to be inserted to [BigQuery]
    final TableDataInsertAllRequest rows =
        TableDataInsertAllRequest.fromJson(<String, Object>{'rows': tableDataInsertAllRequestRows});

    /// Insert [commits] to [BigQuery]
    try {
      await tabledataResourceApi.insertAll(rows, projectId, dataset, table);
    } on ApiRequestError {
      log.warning('Failed to add commits to BigQuery: $ApiRequestError');
    }
  }
}
