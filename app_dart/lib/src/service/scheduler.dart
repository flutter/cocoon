// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';
import 'package:truncate/truncate.dart';
import 'package:yaml/yaml.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/typedefs.dart';
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
///   3. Retry mechanisms for tasks
class Scheduler {
  Scheduler({
    @required this.config,
    @required this.datastore,
    this.gitHubBackoffCalculator = twoSecondLinearBackoff,
    this.httpClientProvider,
    this.log,
  })  : assert(datastore != null),
        assert(gitHubBackoffCalculator != null);

  final Config config;
  final DatastoreService datastore;
  final HttpClientProvider httpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;
  Logging log;

  /// Sets the appengine [log] used by this class to log debug and error
  /// messages. This method has to be called before any other method in this
  /// class.
  void setLogger(Logging log) {
    this.log = log;
  }

  /// Ensure [commits] exist in Cocoon.
  ///
  /// If [Commit] does not exist in Datastore:
  ///   * Write it to datastore
  ///   * Schedule tasks listed in its scheduler config
  /// Otherwise, ignore it.
  Future<void> addCommits(List<Commit> commits) async {
    final List<Commit> newCommits = await _getNewCommits(commits);
    log.debug('Found ${newCommits.length} new commits on GitHub');
    for (Commit commit in newCommits) {
      await _addCommit(commit);
    }
  }

  /// Schedule tasks against [PullRequest].
  ///
  /// If [PullRequest] was merged, schedule prod tasks against it.
  /// Otherwise if it is presubmit, schedule try tasks against it.
  Future<void> addPullRequest(PullRequest pr) async {
    // TODO(chillers): Support triggering on presubmit. https://github.com/flutter/flutter/issues/77858
    if (!pr.merged) {
      log.warning('Only pull requests that were closed and merged should have tasks scheduled');
      return;
    }

    final String fullRepo = pr.base.repo.fullName;
    final String branch = pr.base.ref;
    final String sha = pr.mergeCommitSha;

    final String id = '$fullRepo/$branch/$sha';
    final Key<String> key = datastore.db.emptyKey.append<String>(Commit, id: id);
    final Commit mergedCommit = Commit(
      author: pr.user.login,
      authorAvatarUrl: pr.user.avatarUrl,
      branch: branch,
      key: key,
      // The field has a max length of 1500 so ensure the commit message is not longer.
      message: truncate(pr.title, 1490, omission: '...'),
      repository: fullRepo,
      sha: sha,
      timestamp: pr.mergedAt.millisecondsSinceEpoch,
    );

    if (await _commitExistsInDatastore(mergedCommit)) {
      log.debug('$sha already exists in datastore. Scheduling skipped.');
      return;
    }

    log.debug('Scheduling $sha via GitHub webhook');
    await _addCommit(mergedCommit);
  }

  Future<void> _addCommit(Commit commit) async {
    final List<Task> tasks = await _getTasks(commit);
    try {
      await datastore.withTransaction<void>((Transaction transaction) async {
        transaction.queueMutations(inserts: <Commit>[commit]);
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
        log.debug('Committed ${tasks.length} new tasks for commit ${commit.sha}');
      });
    } catch (error) {
      log.error('Failed to add commit ${commit.sha}: $error');
    }

    await _uploadToBigQuery(commit);
  }

  /// Return subset of [commits] not stored in Datastore.
  Future<List<Commit>> _getNewCommits(List<Commit> commits) async {
    final List<Commit> newCommits = <Commit>[];
    // Ensure commits are sorted from newest to oldest (descending order)
    commits.sort((Commit a, Commit b) => b.timestamp.compareTo(a.timestamp));
    for (Commit commit in commits) {
      if (!await _commitExistsInDatastore(commit)) {
        newCommits.add(commit);
      } else {
        // Once we've found a commit that's already been recorded, we stop looking.
        break;
      }
    }

    // Reverses commits to be in order of oldest to newest.
    return newCommits;
  }

  /// Whether [Commit] already exists in [datastore].
  ///
  /// Datastore is Cocoon's source of truth for what commits have been scheduled.
  /// Since webhooks or cron jobs can schedule commits, we must verify a commit
  /// has not already been scheduled.
  Future<bool> _commitExistsInDatastore(Commit commit) async {
    return await datastore.db.lookupValue<Commit>(commit.key, orElse: () => null) != null;
  }

  /// Create [Tasks] specified in [commit] scheduler config.
  Future<List<Task>> _getTasks(Commit commit) async {
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

    return tasks;
  }

  /// Load in memory the Cocoon Agent DeviceLab scheduler config.
  ///
  // TODO(chillers): Remove when DeviceLab has migrated to LUCI. https://github.com/flutter/flutter/projects/151
  @visibleForTesting
  Future<YamlMap> loadDevicelabManifest(Commit commit) async {
    final String path = '/flutter/flutter/${commit.sha}/dev/devicelab/manifest.yaml';
    log.debug('Getting devicelab manifest content');
    final String content = await remoteFileContent(httpClientProvider, log, gitHubBackoffCalculator, path);
    if (content == null) {
      throw HttpStatusException(HttpStatus.serviceUnavailable, 'Failed to load $path from GitHub');
    }
    return loadYaml(content) as YamlMap;
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
