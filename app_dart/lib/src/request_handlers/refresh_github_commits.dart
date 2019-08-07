// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/devicelab/manifest.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';

/// Queries GitHub for the list of recent commits, and creates corresponding
/// rows in the cloud datastore for any commits not yet in the datastore. Then
/// creates new task rows in the datastore for any commits that were added.
/// The task rows that it creates are driven by the Flutter [Manifest].
@immutable
class RefreshGithubCommits extends ApiRequestHandler<Body> {
  const RefreshGithubCommits(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  @override
  Future<Body> get() async {
    final GitHub github = await config.createGitHubClient();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final List<RepositoryCommit> commits =
        await github.repositories.listCommits(slug).take(50).toList();
    log.debug('Downloaded ${commits.length} commits from GitHub');

    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<Commit> newCommits = <Commit>[];
    for (int i = 0; i < commits.length; i += config.maxEntityGroups) {
      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          for (RepositoryCommit commit in commits.skip(i).take(config.maxEntityGroups)) {
            final String id = 'flutter/flutter/${commit.sha}';
            final Key key = transaction.db.emptyKey.append(Commit, id: id);
            if (await transaction.lookupValue<Commit>(key, orElse: () => null) != null) {
              // This commit has already been recorded.
              continue;
            }

            final Commit newCommit = Commit(
              key: key,
              repository: 'flutter/flutter',
              sha: commit.sha,
              timestamp: now,
              author: commit.author.login,
              authorAvatarUrl: commit.author.avatarUrl,
            );

            newCommits.add(newCommit);
            transaction.queueMutations(inserts: <Commit>[newCommit]);
          }

          await transaction.commit();
        } catch (error) {
          await transaction.rollback();
          rethrow;
        }
      });
    }
    log.debug('Committed ${newCommits.length} new commits');

    for (Commit commit in newCommits) {
      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          final List<Task> tasks = await _createTasks(
            commitKey: commit.key,
            sha: commit.sha,
            createTimestamp: now,
          );

          transaction.queueMutations(inserts: tasks);
          await transaction.commit();
          log.debug('Committed ${tasks.length} new tasks for commit ${commit.sha}');
        } catch (error) {
          await transaction.rollback();
          rethrow;
        }
      });
    }

    return Body.empty;
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
      newTask('mac_bot', 'chromebot', <String>['can-update-chromebots'], false, 0),
      newTask('linux_bot', 'chromebot', <String>['can-update-chromebots'], false, 0),
      newTask('windows_bot', 'chromebot', <String>['can-update-chromebots'], false, 0),
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

    final HttpClient client = HttpClient();
    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        final HttpClientRequest clientRequest = await client.getUrl(url);

        try {
          final HttpClientResponse clientResponse = await clientRequest.close();
          final int status = clientResponse.statusCode;

          if (status == HttpStatus.ok) {
            final String content = await utf8.decoder.bind(clientResponse).join();
            return loadYaml(content);
          } else {
            log.warning('Attempt to download manifest.yaml failed (HTTP $status)');
          }
        } catch (error) {
          log.warning('Attempt to download manifest.yaml failed ($error)');
        }

        await Future<void>.delayed(const Duration(seconds: 2) * (attempt + 1));
      }
    } finally {
      client.close(force: true);
    }

    log.error('GitHub not responding; giving up');
    response.headers.set(HttpHeaders.retryAfterHeader, '120');
    throw HttpStatusException(HttpStatus.serviceUnavailable, 'GitHub not responding');
  }
}
