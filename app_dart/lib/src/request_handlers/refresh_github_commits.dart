// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:http/http.dart' as http;
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

const String _githubCommitsPath = '/repos/flutter/flutter/commits';

/// Per the docs in [DatastoreDB.withTransaction], only 5 entity groups can be
/// touched in any given transaction, or the backing datastore will throw an
/// error.
const int _maxEntityGroups = 5;

@immutable
class RefreshGithubCommits extends ApiRequestHandler<Body> {
  const RefreshGithubCommits(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  @override
  Future<Body> get() async {
    final GitHub github = await config.createGitHubClient();
    final http.Response response = await github.request(
      'GET',
      _githubCommitsPath,
      statusCode: HttpStatus.ok,
      headers: <String, String>{
        HttpHeaders.acceptHeader: 'application/json; version=2',
      },
    );
    final List<dynamic> rawCommits = json.decode(response.body);
    final List<RepositoryCommit> commits = rawCommits
        .cast<Map<String, dynamic>>()
        .map<RepositoryCommit>((Map<String, dynamic> json) => RepositoryCommit.fromJSON(json))
        .toList();

    if (commits.isEmpty) {
      return Body.empty;
    } else {
      log.debug('Downloaded ${commits.length} commits from GitHub');
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<Key> newCommits = <Key>[];
    for (int i = 0; i < commits.length; i += _maxEntityGroups) {
      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          for (RepositoryCommit commit in commits.skip(i).take(_maxEntityGroups)) {
            final String id = 'flutter/flutter/${commit.sha}';
            final Key key = transaction.db.emptyKey.append(Commit, id: id);
            if (await transaction.lookupValue<Commit>(key, orElse: () => null) != null) {
              // This commit has already been recorded.
              continue;
            }

            newCommits.add(key);
            transaction.queueMutations(inserts: <Commit>[
              Commit(
                key: key,
                repository: 'flutter/flutter',
                sha: commit.sha,
                timestamp: now,
                author: commit.author.login,
                authorAvatarUrl: commit.author.avatarUrl,
              ),
            ]);
          }

          await transaction.commit();
        } catch (error) {
          await transaction.rollback();
          rethrow;
        }
      });
    }
    log.debug('Committed ${newCommits.length} new commits');

    for (Key key in newCommits) {
      await config.db.withTransaction<void>((Transaction transaction) async {
        try {
          transaction.queueMutations(
            inserts: await _createTasks(
              commitKey: key,
              sha: key.id.toString().split('/').last,
              createTimestamp: now,
            ),
          );
          await transaction.commit();
        } catch (error) {
          await transaction.rollback();
          rethrow;
        }
      });
    }
    log.debug('Committed all tasks');

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

class ManifestValidationException implements Exception {
  const ManifestValidationException();
}
