// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:cocoon_service/protos.dart' show SchedulerConfig, SchedulerSystem, Target;
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/scheduler.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/utilities/mocks.dart';

const String emptyDeviceLabTaskManifestYaml = '''
tasks:
''';

const String singleDeviceLabTaskManifestYaml = '''
tasks:
  linux_test:
    stage: devicelab
    required_agent_capabilities: ["linux/android"]
''';

const String singleCiYaml = '''
enabled_branches:
  - master
targets:
  - name: A
''';

void main() {
  CacheService cache;
  FakeConfig config;
  FakeDatastoreDB db;
  FakeHttpClient httpClient;
  Scheduler scheduler;

  Commit shaToCommit(String sha, {String branch = 'master'}) {
    return Commit(
      key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
      sha: sha,
      branch: branch,
      timestamp: int.parse(sha),
    );
  }

  group('add commits', () {
    setUp(() {
      final MockTabledataResourceApi tabledataResourceApi = MockTabledataResourceApi();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      cache = CacheService(inMemory: true);
      db = FakeDatastoreDB();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi, dbValue: db);
      httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
        if (request.uri.path.contains('dev/devicelab/manifest.yaml')) {
          httpClient.request.response.body = singleDeviceLabTaskManifestYaml;
        } else if (request.uri.path.contains('.ci.yaml')) {
          httpClient.request.response.body = singleCiYaml;
        } else {
          throw Exception('Failed to find ${request.uri.path}');
        }
      });

      scheduler = Scheduler(
        cache: cache,
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
        httpClientProvider: () => httpClient,
        log: FakeLogging(),
      );
    });

    List<Commit> createCommitList(
      List<String> shas, {
      String repo = 'flutter',
    }) {
      return List<Commit>.generate(
          shas.length,
          (int index) => Commit(
                author: 'Username',
                authorAvatarUrl: 'http://example.org/avatar.jpg',
                branch: 'master',
                key: db.emptyKey.append(Commit, id: 'flutter/$repo/master/${shas[index]}'),
                message: 'commit message',
                repository: 'flutter/$repo',
                sha: shas[index],
                timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(shas[index])).millisecondsSinceEpoch,
              ));
    }

    test('succeeds when GitHub returns no commits', () async {
      await scheduler.addCommits(<Commit>[]);
      expect(db.values, isEmpty);
    });

    test('schedules commit when devicelab manifest is empty', () async {
      config.flutterBranchesValue = <String>['master'];
      httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
        if (request.uri.path.contains('dev/devicelab/manifest.yaml')) {
          httpClient.request.response.body = emptyDeviceLabTaskManifestYaml;
        } else if (request.uri.path.contains('.ci.yaml')) {
          httpClient.request.response.body = singleCiYaml;
        } else {
          throw Exception('Failed to find ${request.uri.path}');
        }
      });
      expect(db.values.values.whereType<Commit>().length, 0);
      await scheduler.addCommits(createCommitList(<String>['1']));
      expect(db.values.values.whereType<Commit>().length, 1);
    });

    test('schedules commit when devicelab manifest 404s', () async {
      config.flutterBranchesValue = <String>['master'];
      httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
        if (request.uri.path.contains('dev/devicelab/manifest.yaml')) {
          httpClient.request.response.statusCode = HttpStatus.notFound;
        } else if (request.uri.path.contains('.ci.yaml')) {
          httpClient.request.response.body = singleCiYaml;
        } else {
          throw Exception('Failed to find ${request.uri.path}');
        }
      });
      expect(db.values.values.whereType<Commit>().length, 0);
      await scheduler.addCommits(createCommitList(<String>['1']));
      expect(db.values.values.whereType<Commit>().length, 1);
    });


    test('inserts all relevant fields of the commit', () async {
      config.flutterBranchesValue = <String>['master'];
      expect(db.values.values.whereType<Commit>().length, 0);
      await scheduler.addCommits(createCommitList(<String>['1']));
      expect(db.values.values.whereType<Commit>().length, 1);
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, 'flutter/flutter');
      expect(commit.branch, 'master');
      expect(commit.sha, '1');
      expect(commit.timestamp, 1);
      expect(commit.author, 'Username');
      expect(commit.authorAvatarUrl, 'http://example.org/avatar.jpg');
      expect(commit.message, 'commit message');
    });

    test('skips scheduling for unsupported repos', () async {
      config.flutterBranchesValue = <String>['master'];
      await scheduler.addCommits(createCommitList(<String>['1'], repo: 'not-supported'));
      expect(db.values.values.whereType<Commit>().length, 0);
    });

    test('skips commits for which transaction commit fails', () async {
      config.flutterBranchesValue = <String>['master'];

      // Existing commits should not be duplicated.
      final Commit commit = shaToCommit('1');
      db.values[commit.key] = commit;

      db.onCommit = (List<gcloud_db.Model<dynamic>> inserts, List<gcloud_db.Key<dynamic>> deletes) {
        if (inserts.whereType<Commit>().where((Commit commit) => commit.sha == '3').isNotEmpty) {
          throw StateError('Commit failed');
        }
      };
      // Commits are expect from newest to oldest timestamps
      await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
      expect(db.values.values.whereType<Commit>().length, 3);
      // The 2 new commits are scheduled tasks, existing commit has none.
      expect(db.values.values.whereType<Task>().length, 2 * 5);
      // Check commits were added, but 3 was not
      expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
      expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
    });

    test('skips commits for which task transaction fails', () async {
      config.flutterBranchesValue = <String>['master'];

      // Existing commits should not be duplicated.
      final Commit commit = shaToCommit('1');
      db.values[commit.key] = commit;

      db.onCommit = (List<gcloud_db.Model<dynamic>> inserts, List<gcloud_db.Key<dynamic>> deletes) {
        if (inserts.whereType<Task>().where((Task task) => task.createTimestamp == 3).isNotEmpty) {
          throw StateError('Task failed');
        }
      };
      // Commits are expect from newest to oldest timestamps
      await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
      expect(db.values.values.whereType<Commit>().length, 3);
      // The 2 new commits are scheduled tasks, existing commit has none.
      expect(db.values.values.whereType<Task>().length, 2 * 5);
      // Check commits were added, but 3 was not
      expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
      expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
    });

    test('retries manifest download upon HTTP failure', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) {
        request.response.statusCode = retry == 0 ? HttpStatus.serviceUnavailable : HttpStatus.ok;
        retry++;
      };

      config.flutterBranchesValue = <String>['master'];
      await scheduler.loadDevicelabManifest(shaToCommit('123'));
      expect(retry, 2);
    });

    test('gives up devicelab manifest download after 3 tries', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;

      config.flutterBranchesValue = <String>['master'];
      httpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
      await expectLater(
          scheduler.loadDevicelabManifest(
            shaToCommit('123'),
            retryOptions: const RetryOptions(
              maxAttempts: 3,
              maxDelay: Duration.zero,
            ),
          ),
          throwsA(isA<HttpException>()));
      expect(retry, 3);
    });
  });

  group('add pull request', () {
    setUp(() {
      final MockTabledataResourceApi tabledataResourceApi = MockTabledataResourceApi();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      cache = CacheService(inMemory: true);
      db = FakeDatastoreDB();
      config = FakeConfig(
        tabledataResourceApi: tabledataResourceApi,
        dbValue: db,
        flutterBranchesValue: <String>['master'],
      );
      httpClient = FakeHttpClient(onIssueRequest: (FakeHttpClientRequest request) {
        if (request.uri.path.contains('dev/devicelab/manifest.yaml')) {
          httpClient.request.response.body = singleDeviceLabTaskManifestYaml;
        } else if (request.uri.path.contains('.ci.yaml')) {
          httpClient.request.response.body = singleCiYaml;
        } else {
          throw Exception('Failed to find ${request.uri.path}');
        }
      });
      scheduler = Scheduler(
        cache: cache,
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
        httpClientProvider: () => httpClient,
        log: FakeLogging(),
      );
    });

    test('creates expected commit', () async {
      final PullRequest mergedPr = createPullRequest();
      await scheduler.addPullRequest(mergedPr);

      expect(db.values.values.whereType<Commit>().length, 1);
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, 'flutter/flutter');
      expect(commit.branch, 'master');
      expect(commit.sha, 'abc');
      expect(commit.timestamp, 1);
      expect(commit.author, 'dash');
      expect(commit.authorAvatarUrl, 'dashatar');
      expect(commit.message, 'example message');
    });

    test('schedules tasks against merged PRs', () async {
      final PullRequest mergedPr = createPullRequest();
      await scheduler.addPullRequest(mergedPr);

      expect(db.values.values.whereType<Commit>().length, 1);
      expect(db.values.values.whereType<Task>().length, 5);
    });

    test('does not schedule tasks against non-merged PRs', () async {
      final PullRequest notMergedPr = createPullRequest(merged: false);
      await scheduler.addPullRequest(notMergedPr);

      expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 0);
      expect(db.values.values.whereType<Task>().length, 0);
    });

    test('does not schedule tasks against already added PRs', () async {
      // Existing commits should not be duplicated.
      final Commit commit = shaToCommit('1');
      db.values[commit.key] = commit;

      final PullRequest alreadyLandedPr = createPullRequest(mergedCommitSha: '1');
      await scheduler.addPullRequest(alreadyLandedPr);

      expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 1);
      // No tasks should be scheduled as that is done on commit insert.
      expect(db.values.values.whereType<Task>().length, 0);
    });

    test('creates expected commit from release branch PR', () async {
      final PullRequest mergedPr = createPullRequest(branch: '1.26');
      await scheduler.addPullRequest(mergedPr);

      expect(db.values.values.whereType<Commit>().length, 1);
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, 'flutter/flutter');
      expect(commit.branch, '1.26');
      expect(commit.sha, 'abc');
      expect(commit.timestamp, 1);
      expect(commit.author, 'dash');
      expect(commit.authorAvatarUrl, 'dashatar');
      expect(commit.message, 'example message');
    });
  });

  group('scheduler config', () {
    test('constructs graph with one target', () {
      final YamlMap singleTargetConfig = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    builder: builderA
    properties:
      test: abc
      ''') as YamlMap;
      final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(singleTargetConfig);
      expect(schedulerConfig.enabledBranches, <String>['master']);
      expect(schedulerConfig.targets.length, 1);
      final Target target = schedulerConfig.targets.first;
      expect(target.bringup, false);
      expect(target.name, 'A');
      expect(target.properties, <String, String>{
        'test': 'abc',
      });
      expect(target.builder, 'builderA');
      expect(target.scheduler, SchedulerSystem.cocoon);
      expect(target.testbed, 'linux-vm');
      expect(target.timeout, 30);
    });

    test('throws exception when non-existent scheduler is given', () {
      final YamlMap targetWithNonexistentScheduler = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    scheduler: dashatar
      ''') as YamlMap;
      expect(() => schedulerConfigFromYaml(targetWithNonexistentScheduler), throwsA(isA<FormatException>()));
    });

    test('constructs graph with dependency chain', () {
      final YamlMap dependentTargetConfig = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
    dependencies:
      - A
  - name: C
    dependencies:
      - B
      ''') as YamlMap;
      final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(dependentTargetConfig);
      expect(schedulerConfig.targets.length, 3);
      final Target a = schedulerConfig.targets.first;
      final Target b = schedulerConfig.targets[1];
      final Target c = schedulerConfig.targets[2];
      expect(a.name, 'A');
      expect(b.name, 'B');
      expect(b.dependencies, <String>['A']);
      expect(c.name, 'C');
      expect(c.dependencies, <String>['B']);
    });

    test('constructs graph with parent with two dependents', () {
      final YamlMap twoDependentTargetConfig = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B1
    dependencies:
      - A
  - name: B2
    dependencies:
      - A
      ''') as YamlMap;
      final SchedulerConfig schedulerConfig = schedulerConfigFromYaml(twoDependentTargetConfig);
      expect(schedulerConfig.targets.length, 3);
      final Target a = schedulerConfig.targets.first;
      final Target b1 = schedulerConfig.targets[1];
      final Target b2 = schedulerConfig.targets[2];
      expect(a.name, 'A');
      expect(b1.name, 'B1');
      expect(b1.dependencies, <String>['A']);
      expect(b2.name, 'B2');
      expect(b2.dependencies, <String>['A']);
    });

    test('fails when there are cyclic targets', () {
      final YamlMap configWithCycle = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    dependencies:
      - B
  - name: B
    dependencies:
      - A
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithCycle),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: A depends on B which does not exist'),
            ),
          ));
    });

    test('fails when there are duplicate targets', () {
      final YamlMap configWithDuplicateTargets = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: A
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithDuplicateTargets),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: A already exists in graph'),
            ),
          ));
    });

    test('fails when there are multiple dependencies', () {
      final YamlMap configWithMultipleDependencies = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
  - name: B
  - name: C
    dependencies:
      - A
      - B
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithMultipleDependencies),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: C has multiple dependencies which is not supported. Use only one dependency'),
            ),
          ));
    });

    test('fails when dependency does not exist', () {
      final YamlMap configWithMissingTarget = loadYaml('''
enabled_branches:
  - master
targets:
  - name: A
    dependencies:
      - B
      ''') as YamlMap;
      expect(
          () => schedulerConfigFromYaml(configWithMissingTarget),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.toString(),
              'message',
              contains('ERROR: A depends on B which does not exist'),
            ),
          ));
    });
  });
}

PullRequest createPullRequest({
  int id = 789,
  String branch = 'master',
  String repo = 'flutter',
  String authorLogin = 'dash',
  String authorAvatar = 'dashatar',
  String title = 'example message',
  int number = 123,
  DateTime mergedAt,
  String mergedCommitSha = 'abc',
  bool merged = true,
}) {
  mergedAt ??= DateTime.fromMillisecondsSinceEpoch(1);
  return PullRequest(
    id: id,
    title: title,
    number: number,
    mergedAt: mergedAt,
    base: PullRequestHead(
        ref: branch,
        repo: Repository(
          fullName: 'flutter/$repo',
          name: repo,
        )),
    user: User(
      login: authorLogin,
      avatarUrl: authorAvatar,
    ),
    mergeCommitSha: mergedCommitSha,
    merged: merged,
  );
}

String toSha(Commit commit) => commit.sha;

int toTimestamp(Commit commit) => commit.timestamp;
