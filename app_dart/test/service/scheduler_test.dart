// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/testing/mocks.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/checks_test_data.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_build_bucket_client.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_fusion_tester.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/webhook_generators.dart';

const String singleCiYaml = r'''
enabled_branches:
  - master
  - main
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux A
    properties:
      custom: abc
  - name: Linux B
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux runIf
    runIf:
      - .ci.yaml
      - DEPS
      - dev/**
      - engine/**
  - name: Google Internal Roll
    postsubmit: true
    presubmit: false
    scheduler: google_internal
''';

const String fusionCiYaml = r'''
enabled_branches:
  - master
  - main
  - codefu
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux Z
    properties:
      custom: abc
  - name: Linux Y
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux engine_build
    scheduler: luci
    properties:
      release_build: "true"
  - name: Linux runIf engine
    runIf:
      - DEPS
      - engine/src/flutter/.ci.yaml
      - engine/src/flutter/dev/**
''';

const String fusionDualCiYaml = r'''
enabled_branches:
  - master
  - main
  - codefu
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux Z
    properties:
      custom: abc
  - name: Linux Y
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux engine_build
    scheduler: luci
    properties:
      release_build: "true"
  - name: Mac engine_build
    scheduler: luci
    properties:
      release_build: "true"
  - name: Linux runIf engine
    runIf:
      - DEPS
      - engine/src/flutter/.ci.yaml
      - engine/src/flutter/dev/**
''';

void main() {
  late CacheService cache;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late FakeBuildStatusService buildStatusService;
  late MockClient httpClient;
  late MockFirestoreService mockFirestoreService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Scheduler scheduler;
  late FakeFusionTester fakeFusion;
  late MockCallbacks callbacks;

  final PullRequest pullRequest = generatePullRequest(id: 42);

  Commit shaToCommit(String sha, {String branch = 'master'}) {
    return Commit(
      key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
      repository: 'flutter/flutter',
      sha: sha,
      branch: branch,
      timestamp: int.parse(sha),
    );
  }

  group('Scheduler', () {
    setUp(() {
      final MockTabledataResource tabledataResource = MockTabledataResource();
      when(tabledataResource.insertAll(any, any, any, any)).thenAnswer((_) async {
        return TableDataInsertAllResponse();
      });

      cache = CacheService(inMemory: true);
      db = FakeDatastoreDB();
      mockFirestoreService = MockFirestoreService();
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(generateCommit(1), const <Stage>[]),
          CommitStatus(generateCommit(1, branch: 'main', repo: Config.engineSlug.name), const <Stage>[]),
        ],
      );
      config = FakeConfig(
        tabledataResource: tabledataResource,
        dbValue: db,
        githubService: FakeGithubService(),
        githubClient: MockGitHub(),
        firestoreService: mockFirestoreService,
        supportedReposValue: <RepositorySlug>{
          Config.engineSlug,
          Config.flutterSlug,
        },
      );
      httpClient = MockClient((http.Request request) async {
        if (request.url.path.contains('.ci.yaml')) {
          return http.Response(singleCiYaml, 200);
        }
        throw Exception('Failed to find ${request.url.path}');
      });

      mockGithubChecksUtil = MockGithubChecksUtil();
      // Generate check runs based on the name hash code
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
          .thenAnswer((Invocation invocation) async => generateCheckRun(invocation.positionalArguments[2].hashCode));

      fakeFusion = FakeFusionTester();
      callbacks = MockCallbacks();

      scheduler = Scheduler(
        cache: cache,
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
        buildStatusProvider: (_, __) => buildStatusService,
        githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
        httpClientProvider: () => httpClient,
        luciBuildService: FakeLuciBuildService(
          config: config,
          githubChecksUtil: mockGithubChecksUtil,
          gerritService: FakeGerritService(
            branchesValue: <String>['master', 'main'],
          ),
        ),
        fusionTester: fakeFusion,
        markCheckRunConclusion: callbacks.markCheckRunConclusion,
      );

      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2},
        });
      });
    });

    test('fusion, getPresubmitTargets supports two ci.yamls', () async {
      httpClient = MockClient((http.Request request) async {
        if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
          return http.Response(fusionCiYaml, 200);
        } else if (request.url.path.endsWith('.ci.yaml')) {
          return http.Response(singleCiYaml, 200);
        }
        throw Exception('Failed to find ${request.url.path}');
      });

      fakeFusion.isFusion = (_, __) => true;

      final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(pullRequest);

      expect(
        [...presubmitTargets.map((Target target) => target.value.name)],
        containsAll(<String>['Linux A']),
      );
      presubmitTargets
        ..clear()
        ..addAll(
          await scheduler.getPresubmitTargets(
            pullRequest,
            type: CiType.fusionEngine,
          ),
        );
      expect(
        [...presubmitTargets.map((Target target) => target.value.name)],
        containsAll(<String>['Linux Z']),
      );
    });

    group('add commits', () {
      final FakePubSub pubsub = FakePubSub();
      List<Commit> createCommitList(
        List<String> shas, {
        String repo = 'flutter',
        String branch = 'master',
      }) {
        return List<Commit>.generate(
          shas.length,
          (int index) => Commit(
            author: 'Username',
            authorAvatarUrl: 'http://example.org/avatar.jpg',
            branch: branch,
            key: db.emptyKey.append(Commit, id: 'flutter/$repo/$branch/${shas[index]}'),
            message: 'commit message',
            repository: 'flutter/$repo',
            sha: shas[index],
            timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(shas[index])).millisecondsSinceEpoch,
          ),
        );
      }

      test('succeeds when GitHub returns no commits', () async {
        await scheduler.addCommits(<Commit>[]);
        expect(db.values, isEmpty);
      });

      test('inserts all relevant fields of the commit', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        config.supportedBranchesValue = <String>['master'];
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
        config.supportedBranchesValue = <String>['master'];
        await scheduler.addCommits(createCommitList(<String>['1'], repo: 'not-supported'));
        expect(db.values.values.whereType<Commit>().length, 0);
      });

      test('skips commits for which transaction commit fails', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        config.supportedBranchesValue = <String>['master'];

        // Existing commits should not be duplicated.
        final Commit commit = shaToCommit('1');
        db.values[commit.key] = commit;

        db.onCommit = (List<gcloud_db.Model<Object?>> inserts, List<gcloud_db.Key<Object?>> deletes) {
          if (inserts.whereType<Commit>().where((Commit commit) => commit.sha == '3').isNotEmpty) {
            throw StateError('Commit failed');
          }
        };
        // Commits are expect from newest to oldest timestamps
        await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
        expect(db.values.values.whereType<Commit>().length, 3);
        // The 2 new commits are scheduled 3 tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 3);
        // Check commits were added, but 3 was not
        expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
        expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
      });

      test('skips commits for which task transaction fails', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        config.supportedBranchesValue = <String>['master'];

        // Existing commits should not be duplicated.
        final Commit commit = shaToCommit('1');
        db.values[commit.key] = commit;

        db.onCommit = (List<gcloud_db.Model<Object?>> inserts, List<gcloud_db.Key<Object?>> deletes) {
          if (inserts.whereType<Task>().where((Task task) => task.createTimestamp == 3).isNotEmpty) {
            throw StateError('Task failed');
          }
        };
        // Commits are expect from newest to oldest timestamps
        await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
        expect(db.values.values.whereType<Commit>().length, 3);
        // The 2 new commits are scheduled 3 tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 3);
        // Check commits were added, but 3 was not
        expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
        expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
      });

      test('schedules cocoon based targets', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final MockLuciBuildService luciBuildService = MockLuciBuildService();
        when(
          luciBuildService.schedulePostsubmitBuilds(
            commit: anyNamed('commit'),
            toBeScheduled: captureAnyNamed('toBeScheduled'),
          ),
        ).thenAnswer((_) => Future<List<Tuple<Target, Task, int>>>.value(<Tuple<Target, Task, int>>[]));
        buildStatusService = FakeBuildStatusService(
          commitStatuses: <CommitStatus>[
            CommitStatus(generateCommit(1, repo: 'engine', branch: 'main'), const <Stage>[]),
          ],
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_, __) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luciBuildService,
          fusionTester: fakeFusion,
        );

        await scheduler.addCommits(createCommitList(<String>['1'], repo: 'engine', branch: 'main'));
        final List<Object?> captured = verify(
          luciBuildService.schedulePostsubmitBuilds(
            commit: anyNamed('commit'),
            toBeScheduled: captureAnyNamed('toBeScheduled'),
          ),
        ).captured;
        final List<Object?> toBeScheduled = captured.first as List<Object?>;
        expect(toBeScheduled.length, 2);
        final Iterable<Tuple<Target, Task, int>> tuples =
            toBeScheduled.map((dynamic tuple) => tuple as Tuple<Target, Task, int>);
        final Iterable<String> scheduledTargetNames =
            tuples.map((Tuple<Target, Task, int> tuple) => tuple.second.name!);
        expect(scheduledTargetNames, ['Linux A', 'Linux runIf']);
        // Tasks triggered by cocoon are marked as in progress
        final Iterable<Task> tasks = db.values.values.whereType<Task>();
        expect(tasks.singleWhere((Task task) => task.name == 'Linux A').status, Task.statusInProgress);
      });

      test('schedules cocoon based targets - multiple batch requests', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
        final FakeLuciBuildService luciBuildService = FakeLuciBuildService(
          config: config,
          buildBucketClient: mockBuildBucketClient,
          gerritService: FakeGerritService(),
          githubChecksUtil: mockGithubChecksUtil,
          pubsub: pubsub,
        );
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
            .thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));

        when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(id: bbv2.BuilderID(bucket: 'prod', project: 'flutter', builder: 'Linux A')),
              bbv2.BuilderItem(id: bbv2.BuilderID(bucket: 'prod', project: 'flutter', builder: 'Linux runIf')),
            ],
          );
        });
        buildStatusService = FakeBuildStatusService(
          commitStatuses: <CommitStatus>[
            CommitStatus(generateCommit(1, repo: 'engine', branch: 'main'), const <Stage>[]),
          ],
        );
        config.batchSizeValue = 1;
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_, __) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luciBuildService,
          fusionTester: fakeFusion,
        );

        await scheduler.addCommits(createCommitList(<String>['1'], repo: 'engine', branch: 'main'));
        expect(pubsub.messages.length, 2);
      });
    });

    group('add pull request', () {
      test('creates expected commit', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final PullRequest mergedPr = generatePullRequest();
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

        final List<Object?> captured = verify(mockFirestoreService.writeViaTransaction(captureAny)).captured;
        expect(captured.length, 1);
        final List<Write> commitResponse = captured[0] as List<Write>;
        expect(commitResponse.length, 4);
      });

      test('schedules tasks against merged PRs', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final PullRequest mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 3);
      });

      test('schedules tasks against merged PRs (fusion)', () async {
        // NOTE: The scheduler doesn't actually do anything except for write backfill requests - unless its a release.
        // When backfills are picked up, they'll go through the same flow (schedulePostsubmitBuilds).
        fakeFusion.isFusion = (_, __) => true;
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
            return http.Response(fusionCiYaml, 200);
          } else if (request.url.path.endsWith('.ci.yaml')) {
            return http.Response(singleCiYaml, 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final PullRequest mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 5, reason: 'removes release_build targets');
        final captured = verify(mockFirestoreService.writeViaTransaction(captureAny)).captured;
        expect(
          captured.first.map((write) => write.update?.name),
          [
            'projects/flutter-dashboard/databases/cocoon/documents/tasks/abc_Linux A_1',
            'projects/flutter-dashboard/databases/cocoon/documents/tasks/abc_Linux runIf_1',
            'projects/flutter-dashboard/databases/cocoon/documents/tasks/abc_Google Internal Roll_1',
            'projects/flutter-dashboard/databases/cocoon/documents/tasks/abc_Linux Z_1',
            'projects/flutter-dashboard/databases/cocoon/documents/tasks/abc_Linux runIf engine_1',
            'projects/flutter-dashboard/databases/cocoon/documents/commits/abc',
          ],
          reason: 'postsubmit release_build targets removed',
        );
      });

      test('guarantees scheduling of tasks against merged release branch PR', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final PullRequest mergedPr = generatePullRequest(branch: 'flutter-3.2-candidate.5');
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 3);
        // Ensure all tasks have been marked in progress
        expect(db.values.values.whereType<Task>().where((Task task) => task.status == Task.statusNew), isEmpty);
      });

      test('guarantees scheduling of tasks against merged engine PR', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final PullRequest mergedPr = generatePullRequest(
          repo: Config.engineSlug.name,
          branch: Config.defaultBranch(Config.engineSlug),
        );
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 3);
        // Ensure all tasks under cocoon scheduler have been marked in progress
        expect(db.values.values.whereType<Task>().where((Task task) => task.status == Task.statusInProgress).length, 2);
      });

      test('Release candidate branch commit filters builders not in default branch', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        const String totCiYaml = r'''
enabled_branches:
  - main
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux A
    properties:
      custom: abc
''';
        httpClient = MockClient((http.Request request) async {
          if (request.url.path == '/flutter/engine/abc/.ci.yaml') {
            return http.Response(totCiYaml, HttpStatus.ok);
          }
          if (request.url.path == '/flutter/engine/1/.ci.yaml') {
            return http.Response(singleCiYaml, HttpStatus.ok);
          }
          print(request.url.path);
          throw Exception('Failed to find ${request.url.path}');
        });
        scheduler = Scheduler(
          cache: cache,
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          buildStatusProvider: (_, __) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            gerritService: FakeGerritService(
              branchesValue: <String>['master', 'main'],
            ),
          ),
          fusionTester: fakeFusion,
        );

        final PullRequest mergedPr = generatePullRequest(
          repo: Config.engineSlug.name,
          branch: 'flutter-3.10-candidate.1',
        );
        await scheduler.addPullRequest(mergedPr);

        final List<Task> tasks = db.values.values.whereType<Task>().toList();
        expect(db.values.values.whereType<Commit>().length, 1);
        expect(tasks, hasLength(1));
        expect(tasks.first.name, 'Linux A');
        // Ensure all tasks under cocoon scheduler have been marked in progress
        expect(db.values.values.whereType<Task>().where((Task task) => task.status == Task.statusInProgress).length, 1);
      });

      test('does not schedule tasks against non-merged PRs', () async {
        final PullRequest notMergedPr = generatePullRequest(merged: false);
        await scheduler.addPullRequest(notMergedPr);

        expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 0);
        expect(db.values.values.whereType<Task>().length, 0);
      });

      test('does not schedule tasks against already added PRs', () async {
        // Existing commits should not be duplicated.
        final Commit commit = shaToCommit('1');
        db.values[commit.key] = commit;

        final PullRequest alreadyLandedPr = generatePullRequest(sha: '1');
        await scheduler.addPullRequest(alreadyLandedPr);

        expect(db.values.values.whereType<Commit>().map<String>(toSha).length, 1);
        // No tasks should be scheduled as that is done on commit insert.
        expect(db.values.values.whereType<Task>().length, 0);
      });

      test('creates expected commit from release branch PR', () async {
        when(
          mockFirestoreService.writeViaTransaction(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final PullRequest mergedPr = generatePullRequest(branch: '1.26');
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

    group('process check run', () {
      test('rerequested ci.yaml check retriggers presubmit', () async {
        final MockGithubService mockGithubService = MockGithubService();
        final MockGitHub mockGithubClient = MockGitHub();
        buildStatusService =
            FakeBuildStatusService(commitStatuses: <CommitStatus>[CommitStatus(generateCommit(1), const <Stage>[])]);
        config = FakeConfig(
          githubService: mockGithubService,
          firestoreService: mockFirestoreService,
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_, __) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          fusionTester: fakeFusion,
        );
        when(mockGithubService.github).thenReturn(mockGithubClient);
        when(mockGithubService.searchIssuesAndPRs(any, any, sort: anyNamed('sort'), pages: anyNamed('pages')))
            .thenAnswer((_) async => [generateIssue(3)]);
        when(mockGithubChecksUtil.listCheckSuitesForRef(any, any, ref: anyNamed('ref'))).thenAnswer(
          (_) async => [
            // From check_run.check_suite.id in [checkRunString].
            generateCheckSuite(668083231),
          ],
        );
        when(mockGithubService.getPullRequest(any, any)).thenAnswer((_) async => generatePullRequest());
        when(mockGithubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
          ),
        ).thenAnswer((_) async {
          return CheckRun.fromJson(const <String, dynamic>{
            'id': 1,
            'started_at': '2020-05-10T02:49:31Z',
            'name': Scheduler.kCiYamlCheckName,
            'check_suite': <String, dynamic>{'id': 2},
          });
        });
        final Map<String, dynamic> checkRunEventJson = jsonDecode(checkRunString) as Map<String, dynamic>;
        checkRunEventJson['check_run']['name'] = Scheduler.kCiYamlCheckName;
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(checkRunEventJson);
        expect(await scheduler.processCheckRun(checkRunEvent), true);
        verify(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            Scheduler.kCiYamlCheckName,
            output: anyNamed('output'),
          ),
        );
        // Verfies Linux A was created
        verify(mockGithubChecksUtil.createCheckRun(any, any, any, any)).called(1);
      });

      test('rerequested merge queue guard check is ignored', () async {
        final MockGithubService mockGithubService = MockGithubService();
        final MockGitHub mockGithubClient = MockGitHub();
        buildStatusService =
            FakeBuildStatusService(commitStatuses: <CommitStatus>[CommitStatus(generateCommit(1), const <Stage>[])]);
        config = FakeConfig(
          githubService: mockGithubService,
          firestoreService: mockFirestoreService,
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_, __) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          fusionTester: fakeFusion,
        );
        when(mockGithubService.github).thenReturn(mockGithubClient);
        when(mockGithubService.searchIssuesAndPRs(any, any, sort: anyNamed('sort'), pages: anyNamed('pages')))
            .thenAnswer((_) async => [generateIssue(3)]);
        when(mockGithubChecksUtil.listCheckSuitesForRef(any, any, ref: anyNamed('ref'))).thenAnswer(
          (_) async => [
            // From check_run.check_suite.id in [checkRunString].
            generateCheckSuite(668083231),
          ],
        );
        when(mockGithubService.getPullRequest(any, any)).thenAnswer((_) async => generatePullRequest());
        when(mockGithubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
          ),
        ).thenAnswer((_) async {
          return CheckRun.fromJson(const <String, dynamic>{
            'id': 1,
            'started_at': '2020-05-10T02:49:31Z',
            'name': Scheduler.kCiYamlCheckName,
            'check_suite': <String, dynamic>{'id': 2},
          });
        });
        final Map<String, dynamic> checkRunEventJson = jsonDecode(checkRunString) as Map<String, dynamic>;
        checkRunEventJson['check_run']['name'] = Scheduler.kMergeQueueLockName;
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(checkRunEventJson);
        expect(await scheduler.processCheckRun(checkRunEvent), true);
        verifyNever(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            Scheduler.kMergeQueueLockName,
            output: anyNamed('output'),
          ),
        );
        // Verfies Linux A was created
        verifyNever(mockGithubChecksUtil.createCheckRun(any, any, any, any));
      });

      test('rerequested presubmit check triggers presubmit build', () async {
        // Note that we're not inserting any commits into the db, because
        // only postsubmit commits are stored in the datastore.
        config = FakeConfig(dbValue: db);
        db = FakeDatastoreDB();

        // Set up mock buildbucket to validate which bucket is requested.
        final MockBuildBucketClient mockBuildbucket = MockBuildBucketClient();

        when(mockBuildbucket.batch(any)).thenAnswer((i) async {
          return FakeBuildBucketClient().batch(i.positionalArguments[0]);
        });

        when(mockBuildbucket.scheduleBuild(any, buildBucketUri: anyNamed('buildBucketUri')))
            .thenAnswer((realInvocation) async {
          final bbv2.ScheduleBuildRequest scheduleBuildRequest = realInvocation.positionalArguments[0];
          // Ensure this is an attempt to schedule a presubmit build by
          // verifying that bucket == 'try'.
          expect(scheduleBuildRequest.builder.bucket, equals('try'));
          return bbv2.Build(builder: bbv2.BuilderID(), id: Int64());
        });

        scheduler = Scheduler(
          cache: cache,
          config: config,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildBucketClient: mockBuildbucket,
          ),
          fusionTester: fakeFusion,
        );

        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunString) as Map<String, dynamic>,
        );

        expect(await scheduler.processCheckRun(checkRunEvent), true);

        verify(mockBuildbucket.scheduleBuild(any, buildBucketUri: anyNamed('buildBucketUri'))).called(1);
        verify(mockGithubChecksUtil.createCheckRun(any, any, any, any)).called(1);
      });

      test('rerequested postsubmit check triggers postsubmit build', () async {
        // Set up datastore with postsubmit entities matching [checkRunString].
        db = FakeDatastoreDB();
        config = FakeConfig(
          dbValue: db,
          postsubmitSupportedReposValue: {RepositorySlug('abc', 'cocoon')},
          firestoreService: mockFirestoreService,
        );
        when(
          mockFirestoreService.queryCommitTasks(
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<List<firestore.Task>>.value(
            <firestore.Task>[generateFirestoreTask(1, name: 'test1')],
          );
        });
        when(
          mockFirestoreService.batchWriteDocuments(
            captureAny,
            captureAny,
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<BatchWriteResponse>.value(BatchWriteResponse());
        });
        final Commit commit = generateCommit(
          1,
          sha: '66d6bd9a3f79a36fe4f5178ccefbc781488a596c',
          branch: 'independent_agent',
          owner: 'abc',
          repo: 'cocoon',
        );
        final Commit commitToT = generateCommit(
          1,
          sha: '66d6bd9a3f79a36fe4f5178ccefbc781488a592c',
          branch: 'master',
          owner: 'abc',
          repo: 'cocoon',
        );
        config.db.values[commit.key] = commit;
        config.db.values[commitToT.key] = commitToT;
        final Task task = generateTask(1, name: 'test1', parent: commit);
        config.db.values[task.key] = task;

        // Set up ci.yaml with task name and branch name from [checkRunString].
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response(
              r'''
enabled_branches:
  - independent_agent
  - master
targets:
  - name: test1
''',
              200,
            );
          }
          throw Exception('Failed to find ${request.url.path}');
        });

        // Set up mock buildbucket to validate which bucket is requested.
        final MockBuildBucketClient mockBuildbucket = MockBuildBucketClient();
        when(mockBuildbucket.batch(any)).thenAnswer((i) async {
          return FakeBuildBucketClient().batch(i.positionalArguments[0]);
        });
        when(mockBuildbucket.scheduleBuild(any, buildBucketUri: anyNamed('buildBucketUri')))
            .thenAnswer((realInvocation) async {
          final bbv2.ScheduleBuildRequest scheduleBuildRequest = realInvocation.positionalArguments[0];
          // Ensure this is an attempt to schedule a postsubmit build by
          // verifying that bucket == 'prod'.
          expect(scheduleBuildRequest.builder.bucket, equals('prod'));
          return bbv2.Build(builder: bbv2.BuilderID(), id: Int64());
        });
        final FakePubSub pubsub = FakePubSub();
        final FakeLuciBuildService luciBuildService = FakeLuciBuildService(
          config: config,
          githubChecksUtil: mockGithubChecksUtil,
          buildBucketClient: mockBuildbucket,
          gerritService: FakeGerritService(
            branchesValue: <String>['master', 'main'],
          ),
          pubsub: pubsub,
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luciBuildService,
          fusionTester: fakeFusion,
        );
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunString) as Map<String, dynamic>,
        );
        expect(await scheduler.processCheckRun(checkRunEvent), true);
        verify(mockGithubChecksUtil.createCheckRun(any, any, any, any)).called(1);
        expect(pubsub.messages.length, 1);
      });

      test('rerequested does not fail on empty pull request list', () async {
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
          return CheckRun.fromJson(const <String, dynamic>{
            'id': 1,
            'started_at': '2020-05-10T02:49:31Z',
            'check_suite': <String, dynamic>{'id': 2},
          });
        });
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunWithEmptyPullRequests) as Map<String, dynamic>,
        );
        expect(await scheduler.processCheckRun(checkRunEvent), true);
        verify(mockGithubChecksUtil.createCheckRun(any, any, any, any)).called(1);
      });

      group('completed action', () {
        test('works for non fusion cases', () async {
          fakeFusion.isFusion = (_, __) => false;
          expect(
            await scheduler.processCheckRun(
              cocoon_checks.CheckRunEvent.fromJson(
                json.decode(checkRunEventFor()),
              ),
            ),
            true,
          );
        });

        group('in fusion', () {
          setUp(() {
            fakeFusion.isFusion = (_, __) => true;
          });

          test('ignores default check runs that have no side effects', () async {
            when(
              callbacks.markCheckRunConclusion(
                firestoreService: anyNamed('firestoreService'),
                slug: anyNamed('slug'),
                sha: anyNamed('sha'),
                stage: anyNamed('stage'),
                checkRun: anyNamed('checkRun'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((_) async {
              return const StagingConclusion(valid: false, remaining: 1, checkRunGuard: '{}', failed: 0);
            });

            for (final ignored in Scheduler.kCheckRunsToIgnore) {
              expect(
                await scheduler.processCheckRunCompletion(
                  cocoon_checks.CheckRunEvent.fromJson(
                    json.decode(checkRunEventFor(test: ignored)),
                  ),
                ),
                isTrue,
              );

              verifyNever(
                callbacks.markCheckRunConclusion(
                  firestoreService: anyNamed('firestoreService'),
                  slug: anyNamed('slug'),
                  sha: anyNamed('sha'),
                  stage: anyNamed('stage'),
                  checkRun: anyNamed('checkRun'),
                  conclusion: anyNamed('conclusion'),
                ),
              );
            }
          });

          test('ignores invalid conclusions', () async {
            when(
              callbacks.markCheckRunConclusion(
                firestoreService: anyNamed('firestoreService'),
                slug: anyNamed('slug'),
                sha: anyNamed('sha'),
                stage: anyNamed('stage'),
                checkRun: anyNamed('checkRun'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((_) async {
              return const StagingConclusion(valid: false, remaining: 1, checkRunGuard: '{}', failed: 0);
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar')),
                ),
              ),
              isFalse,
            );
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flauxSlug), named: 'slug'),
                sha: '1234',
                stage: argThat(equals(CiStage.fusionEngineBuild), named: 'stage'),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            verifyNever(
              mockGithubChecksUtil.updateCheckRun(
                any,
                any,
                any,
                status: anyNamed('status'),
                conclusion: anyNamed('conclusion'),
                output: anyNamed('output'),
              ),
            );
          });

          test('does not complete with remaining tests', () async {
            when(
              callbacks.markCheckRunConclusion(
                firestoreService: anyNamed('firestoreService'),
                slug: anyNamed('slug'),
                sha: anyNamed('sha'),
                stage: anyNamed('stage'),
                checkRun: anyNamed('checkRun'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((inv) async {
              return const StagingConclusion(valid: true, remaining: 1, checkRunGuard: '{}', failed: 0);
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar')),
                ),
              ),
              isFalse,
            );
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flauxSlug), named: 'slug'),
                sha: '1234',
                stage: argThat(equals(CiStage.fusionEngineBuild), named: 'stage'),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            verifyNever(
              mockGithubChecksUtil.updateCheckRun(
                any,
                any,
                any,
                status: anyNamed('status'),
                conclusion: anyNamed('conclusion'),
                output: anyNamed('output'),
              ),
            );
          });

          test('failed tests unlocks but does not schedule more', () async {
            when(
              callbacks.markCheckRunConclusion(
                firestoreService: anyNamed('firestoreService'),
                slug: anyNamed('slug'),
                sha: anyNamed('sha'),
                stage: anyNamed('stage'),
                checkRun: anyNamed('checkRun'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((inv) async {
              return StagingConclusion(
                valid: true,
                remaining: 0,
                checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                failed: 1,
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar')),
                ),
              ),
              isTrue,
            );
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flauxSlug), named: 'slug'),
                sha: '1234',
                stage: argThat(equals(CiStage.fusionEngineBuild), named: 'stage'),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            verify(
              mockGithubChecksUtil.updateCheckRun(
                any,
                argThat(equals(RepositorySlug('flutter', 'flaux'))),
                argThat(
                  predicate<CheckRun>((arg) {
                    expect(arg.name, 'GUARD TEST');
                    return true;
                  }),
                ),
                status: argThat(equals(CheckRunStatus.completed), named: 'status'),
                conclusion: argThat(equals(CheckRunConclusion.failure), named: 'conclusion'),
                output: anyNamed('output'),
              ),
            ).called(1);
          });

          test('schedules tests after engine stage', () async {
            final githubService = config.githubService = MockGithubService();
            final githubClient = MockGitHub();
            when(githubService.github).thenReturn(githubClient);
            when(githubService.searchIssuesAndPRs(any, any, sort: anyNamed('sort'), pages: anyNamed('pages')))
                .thenAnswer((_) async => [generateIssue(42)]);

            final pullRequest = generatePullRequest();
            when(githubService.getPullRequest(any, any)).thenAnswer((_) async => pullRequest);
            when(githubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);
            when(mockGithubChecksUtil.listCheckSuitesForRef(any, any, ref: anyNamed('ref'))).thenAnswer(
              (_) async => [
                // From check_run.check_suite.id in [checkRunString].
                generateCheckSuite(668083231),
              ],
            );

            httpClient = MockClient((http.Request request) async {
              if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
                return http.Response(fusionCiYaml, 200);
              } else if (request.url.path.endsWith('.ci.yaml')) {
                return http.Response(singleCiYaml, 200);
              }
              throw Exception('Failed to find ${request.url.path}');
            });
            final luci = MockLuciBuildService();
            when(luci.scheduleTryBuilds(targets: anyNamed('targets'), pullRequest: anyNamed('pullRequest')))
                .thenAnswer((inv) async {
              return [];
            });

            final gitHubChecksService = MockGithubChecksService();
            when(gitHubChecksService.githubChecksUtil).thenReturn(mockGithubChecksUtil);
            when(gitHubChecksService.findMatchingPullRequest(any, any, any)).thenAnswer((inv) async {
              return pullRequest;
            });

            scheduler = Scheduler(
              cache: cache,
              config: config,
              datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
              buildStatusProvider: (_, __) => buildStatusService,
              githubChecksService: gitHubChecksService,
              httpClientProvider: () => httpClient,
              luciBuildService: luci,
              fusionTester: fakeFusion,
              markCheckRunConclusion: callbacks.markCheckRunConclusion,
            );

            when(
              callbacks.markCheckRunConclusion(
                firestoreService: anyNamed('firestoreService'),
                slug: anyNamed('slug'),
                sha: anyNamed('sha'),
                stage: anyNamed('stage'),
                checkRun: anyNamed('checkRun'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((inv) async {
              return StagingConclusion(
                valid: true,
                remaining: 0,
                checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                failed: 0,
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar', sha: 'testSha')),
                ),
              ),
              isTrue,
            );

            verify(gitHubChecksService.findMatchingPullRequest(Config.flauxSlug, 'testSha', 668083231)).called(1);

            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flauxSlug), named: 'slug'),
                sha: 'testSha',
                stage: argThat(equals(CiStage.fusionEngineBuild), named: 'stage'),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            verify(
              mockGithubChecksUtil.updateCheckRun(
                any,
                argThat(equals(RepositorySlug('flutter', 'flaux'))),
                argThat(
                  predicate<CheckRun>((arg) {
                    expect(arg.name, 'GUARD TEST');
                    return true;
                  }),
                ),
                status: argThat(equals(CheckRunStatus.completed), named: 'status'),
                conclusion: argThat(equals(CheckRunConclusion.success), named: 'conclusion'),
                output: anyNamed('output'),
              ),
            ).called(1);

            final result = verify(
              luci.scheduleTryBuilds(
                targets: captureAnyNamed('targets'),
                pullRequest: captureAnyNamed('pullRequest'),
              ),
            );
            expect(result.callCount, 1);
            final captured = result.captured;
            expect(captured[0], hasLength(2));
            // see the blend of fusionCiYaml and singleCiYaml
            expect(captured[0][0].getTestName, 'A');
            expect(captured[0][1].getTestName, 'Z');
            expect(captured[1], pullRequest);
          });

          test('schedules tests after engine stage - with pr caching', () async {
            final githubService = config.githubService = MockGithubService();
            final githubClient = MockGitHub();
            when(githubService.github).thenReturn(githubClient);
            when(githubService.searchIssuesAndPRs(any, any, sort: anyNamed('sort'), pages: anyNamed('pages')))
                .thenAnswer((_) async => [generateIssue(42)]);

            final pullRequest = generatePullRequest();
            when(githubService.getPullRequest(any, any)).thenAnswer((_) async => pullRequest);
            when(githubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);
            when(mockGithubChecksUtil.listCheckSuitesForRef(any, any, ref: anyNamed('ref'))).thenAnswer(
              (_) async => [
                // From check_run.check_suite.id in [checkRunString].
                generateCheckSuite(668083231),
              ],
            );

            when(callbacks.findPullRequestFor(any, any, any)).thenAnswer((inv) async {
              return pullRequest;
            });

            httpClient = MockClient((http.Request request) async {
              if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
                return http.Response(fusionCiYaml, 200);
              } else if (request.url.path.endsWith('.ci.yaml')) {
                return http.Response(singleCiYaml, 200);
              }
              throw Exception('Failed to find ${request.url.path}');
            });
            final luci = MockLuciBuildService();
            when(luci.scheduleTryBuilds(targets: anyNamed('targets'), pullRequest: anyNamed('pullRequest')))
                .thenAnswer((inv) async {
              return [];
            });

            final gitHubChecksService = MockGithubChecksService();
            when(gitHubChecksService.githubChecksUtil).thenReturn(mockGithubChecksUtil);

            scheduler = Scheduler(
              cache: cache,
              config: config,
              datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
              buildStatusProvider: (_, __) => buildStatusService,
              githubChecksService: gitHubChecksService,
              httpClientProvider: () => httpClient,
              luciBuildService: luci,
              fusionTester: fakeFusion,
              markCheckRunConclusion: callbacks.markCheckRunConclusion,
              findPullRequestFor: callbacks.findPullRequestFor,
            );

            when(
              callbacks.markCheckRunConclusion(
                firestoreService: anyNamed('firestoreService'),
                slug: anyNamed('slug'),
                sha: anyNamed('sha'),
                stage: anyNamed('stage'),
                checkRun: anyNamed('checkRun'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((inv) async {
              return StagingConclusion(
                valid: true,
                remaining: 0,
                checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                failed: 0,
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar')),
                ),
              ),
              isTrue,
            );

            verify(callbacks.findPullRequestFor(mockFirestoreService, 1, 'Bar bar')).called(1);
            verifyNever(gitHubChecksService.findMatchingPullRequest(any, any, any));

            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flauxSlug), named: 'slug'),
                sha: '1234',
                stage: argThat(equals(CiStage.fusionEngineBuild), named: 'stage'),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            verify(
              mockGithubChecksUtil.updateCheckRun(
                any,
                argThat(equals(RepositorySlug('flutter', 'flaux'))),
                argThat(
                  predicate<CheckRun>((arg) {
                    expect(arg.name, 'GUARD TEST');
                    return true;
                  }),
                ),
                status: argThat(equals(CheckRunStatus.completed), named: 'status'),
                conclusion: argThat(equals(CheckRunConclusion.success), named: 'conclusion'),
                output: anyNamed('output'),
              ),
            ).called(1);

            final result = verify(
              luci.scheduleTryBuilds(
                targets: captureAnyNamed('targets'),
                pullRequest: captureAnyNamed('pullRequest'),
              ),
            );
            expect(result.callCount, 1);
            final captured = result.captured;
            expect(captured[0], hasLength(2));
            // see the blend of fusionCiYaml and singleCiYaml
            expect(captured[0][0].getTestName, 'A');
            expect(captured[0][1].getTestName, 'Z');
            expect(captured[1], pullRequest);
          });
          // end of group
        });
      });
    });

    group('presubmit', () {
      test('gets only enabled .ci.yaml builds', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response(
              '''
enabled_branches:
  - master
targets:
  - name: Linux A
    presubmit: true
    scheduler: luci
  - name: Linux B
    scheduler: luci
    enabled_branches:
      - stable
    presubmit: true
  - name: Linux C
    scheduler: luci
    enabled_branches:
      - master
    presubmit: true
  - name: Linux D
    scheduler: luci
    bringup: true
    presubmit: true
  - name: Google-internal roll
    scheduler: google_internal
    enabled_branches:
      - master
    presubmit: true
          ''',
              200,
            );
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(pullRequest);
        expect(
          presubmitTargets.map((Target target) => target.value.name).toList(),
          containsAll(<String>['Linux A', 'Linux C']),
        );
      });

      group('treats postsubmit as presubmit if a label is present', () {
        final IssueLabel runAllTests = IssueLabel(name: 'test: all');
        setUp(() async {
          httpClient = MockClient((http.Request request) async {
            if (request.url.path.contains('.ci.yaml')) {
              return http.Response(
                '''
  enabled_branches:
    - main
    - master
  targets:
    - name: Linux Presubmit
      presubmit: true
      scheduler: luci
    - name: Linux Conditional Presubmit (runIf)
      presubmit: true
      scheduler: luci
      runIf:
        - .ci.yaml
        - DEPS
        - dev/run_if/**
    - name: Linux Postsubmit
      presubmit: false
      scheduler: luci
    - name: Linux Cache
      presubmit: false
      scheduler: luci
      properties:
        cache_name: "builder"
  ''',
                200,
              );
            }
            throw Exception('Failed to find ${request.url.path}');
          });
        });

        test('with a specific label in the flutter/engine repo', () async {
          final enginePr = generatePullRequest(
            branch: Config.defaultBranch(Config.engineSlug),
            labels: <IssueLabel>[runAllTests],
            repo: Config.engineSlug.name,
          );
          final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(enginePr);
          expect(
            presubmitTargets.map((Target target) => target.value.name).toList(),
            <String>[
              // Always runs.
              'Linux Presubmit',
              // test: all label is present, so runIf is skipped.
              'Linux Conditional Presubmit (runIf)',
              // test: all label is present, so postsubmit is treated as presubmit.
              'Linux Postsubmit',
            ],
          );
        });

        test('with a specific label in the flutter/flutter repo', () async {
          final frameworkPr = generatePullRequest(
            branch: Config.defaultBranch(Config.flutterSlug),
            labels: <IssueLabel>[runAllTests],
            repo: Config.flutterSlug.name,
          );
          final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(frameworkPr);
          expect(
            presubmitTargets.map((Target target) => target.value.name).toList(),
            <String>[
              // Always runs.
              'Linux Presubmit',
              // test: all label is present, so runIf is skipped.
              'Linux Conditional Presubmit (runIf)',
              // test: all label is present, so postsubmit is treated as presubmit.
              'Linux Postsubmit',
            ],
          );
        });

        test('without a specific label', () async {
          final enginePr = generatePullRequest(
            branch: Config.defaultBranch(Config.engineSlug),
            labels: <IssueLabel>[],
            repo: Config.engineSlug.name,
          );
          final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(enginePr);
          expect(
            presubmitTargets.map((Target target) => target.value.name).toList(),
            (<String>[
              // Always runs.
              'Linux Presubmit',
            ]),
          );
        });
      });

      test('checks for release branches', () async {
        const String branch = 'flutter-1.24-candidate.1';
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response(
              '''
enabled_branches:
  - master
targets:
  - name: Linux A
    presubmit: true
    scheduler: luci
          ''',
              200,
            );
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        expect(
          scheduler.getPresubmitTargets(generatePullRequest(branch: branch)),
          throwsA(predicate((Exception e) => e.toString().contains('$branch is not enabled'))),
        );
      });

      test('checks for release branch regex', () async {
        const String branch = 'flutter-1.24-candidate.1';
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response(
              '''
enabled_branches:
  - main
  - master
  - flutter-\\d+.\\d+-candidate.\\d+
targets:
  - name: Linux A
    scheduler: luci
          ''',
              200,
            );
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        final List<Target> targets = await scheduler.getPresubmitTargets(generatePullRequest(branch: branch));
        expect(targets.single.value.name, 'Linux A');
      });

      test('triggers expected presubmit build checks', () async {
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
              .captured,
          <Object?>[
            Scheduler.kMergeQueueLockName,
            const CheckRunOutput(
              title: Scheduler.kMergeQueueLockName,
              summary: Scheduler.kMergeQueueLockDescription,
            ),
            Scheduler.kCiYamlCheckName,
            const CheckRunOutput(
              title: Scheduler.kCiYamlCheckName,
              summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
            ),
            'Linux A',
            null,
            // Linux runIf is not run as this is for tip of tree and the files weren't affected
          ],
        );
      });

      test('Do not schedule other targets on revert request.', () async {
        final PullRequest releasePullRequest = generatePullRequest(
          labels: [IssueLabel(name: 'revert of')],
        );

        releasePullRequest.user = User(login: 'auto-submit[bot]');

        await scheduler.triggerPresubmitTargets(pullRequest: releasePullRequest);
        expect(
          verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
              .captured,
          <Object?>[
            Scheduler.kMergeQueueLockName,
            const CheckRunOutput(
              title: Scheduler.kMergeQueueLockName,
              summary: Scheduler.kMergeQueueLockDescription,
            ),
            Scheduler.kCiYamlCheckName,
            // No other targets should be created.
            const CheckRunOutput(
              title: Scheduler.kCiYamlCheckName,
              summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
            ),
          ],
        );
      });

      test('filters out presubmit targets that do not exist in main and do not filter targets not in main', () async {
        const String singleCiYaml = r'''
enabled_branches:
  - master
  - main
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux A
    properties:
      custom: abc
  - name: Linux B
    enabled_branches:
      - flutter-\d+\.\d+-candidate\.\d+
    scheduler: luci
  - name: Linux C
    enabled_branches:
      - main
      - flutter-\d+\.\d+-candidate\.\d+
    scheduler: luci
''';
        const String totCiYaml = r'''
enabled_branches:
  - main
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux A
    bringup: true
    properties:
      custom: abc
''';
        httpClient = MockClient((http.Request request) async {
          if (request.url.path == '/flutter/engine/1/.ci.yaml') {
            return http.Response(totCiYaml, HttpStatus.ok);
          }
          if (request.url.path == '/flutter/engine/abc/.ci.yaml') {
            return http.Response(singleCiYaml, HttpStatus.ok);
          }
          print(request.url.path);
          throw Exception('Failed to find ${request.url.path}');
        });
        scheduler = Scheduler(
          cache: cache,
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          buildStatusProvider: (_, __) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            gerritService: FakeGerritService(
              branchesValue: <String>['master', 'main'],
            ),
          ),
          fusionTester: fakeFusion,
        );
        final PullRequest pr = generatePullRequest(
          repo: Config.engineSlug.name,
          branch: 'flutter-3.10-candidate.1',
        );
        final List<Target> targets = await scheduler.getPresubmitTargets(pr);
        expect(
          targets.map((Target target) => target.value.name).toList(),
          containsAll(<String>['Linux A', 'Linux B']),
        );
      });

      test('triggers all presubmit build checks when diff cannot be found', () async {
        final MockGithubService mockGithubService = MockGithubService();
        when(mockGithubService.listFiles(pullRequest))
            .thenThrow(GitHubError(GitHub(), 'Requested Resource was Not Found'));
        buildStatusService =
            FakeBuildStatusService(commitStatuses: <CommitStatus>[CommitStatus(generateCommit(1), const <Stage>[])]);
        scheduler = Scheduler(
          cache: cache,
          config: FakeConfig(
            // tabledataResource: tabledataResource,
            dbValue: db,
            githubService: mockGithubService,
            githubClient: MockGitHub(),
            firestoreService: mockFirestoreService,
          ),
          buildStatusProvider: (_, __) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            gerritService: FakeGerritService(branchesValue: <String>['master']),
          ),
          fusionTester: fakeFusion,
        );
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
              .captured,
          <Object?>[
            Scheduler.kMergeQueueLockName,
            const CheckRunOutput(
              title: Scheduler.kMergeQueueLockName,
              summary: Scheduler.kMergeQueueLockDescription,
            ),
            Scheduler.kCiYamlCheckName,
            const CheckRunOutput(
              title: Scheduler.kCiYamlCheckName,
              summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
            ),
            'Linux A',
            null,
            // runIf requires a diff in dev, so an error will cause it to be triggered
            'Linux runIf',
            null,
          ],
        );
      });

      test('triggers all presubmit targets on release branch pull request', () async {
        final PullRequest releasePullRequest = generatePullRequest(
          branch: 'flutter-1.24-candidate.1',
        );
        await scheduler.triggerPresubmitTargets(pullRequest: releasePullRequest);
        expect(
          verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
              .captured,
          <Object?>[
            Scheduler.kMergeQueueLockName,
            const CheckRunOutput(
              title: Scheduler.kMergeQueueLockName,
              summary: Scheduler.kMergeQueueLockDescription,
            ),
            Scheduler.kCiYamlCheckName,
            const CheckRunOutput(
              title: Scheduler.kCiYamlCheckName,
              summary: 'If this check is stuck pending, push an empty commit to retrigger the checks',
            ),
            'Linux A',
            null,
            'Linux runIf',
            null,
          ],
        );
      });

      test('ci.yaml validation passes with default config', () async {
        when(mockGithubChecksUtil.getCheckRun(any, any, any))
            .thenAnswer((Invocation invocation) async => createCheckRun(id: 0));
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              any,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              output: anyNamed('output'),
            ),
          ).captured,
          <Object?>[
            CheckRunStatus.completed,
            CheckRunConclusion.success,
            CheckRunStatus.completed,
            CheckRunConclusion.success,
          ],
        );
      });

      test('ci.yaml validation fails with empty config', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response('', 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              any,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              output: anyNamed('output'),
            ),
          ).captured,
          <Object?>[
            CheckRunStatus.completed,
            CheckRunConclusion.failure,
            CheckRunStatus.completed,
            CheckRunConclusion.failure,
          ],
        );
      });

      test('ci.yaml validation fails on not enabled branch', () async {
        final PullRequest pullRequest = generatePullRequest(branch: 'not-valid');
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              any,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              output: anyNamed('output'),
            ),
          ).captured,
          <Object?>[
            CheckRunStatus.completed,
            CheckRunConclusion.failure,
            CheckRunStatus.completed,
            CheckRunConclusion.failure,
          ],
        );
      });

      test('ci.yaml validation fails with config with unknown dependencies', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.contains('.ci.yaml')) {
            return http.Response(
              '''
enabled_branches:
  - master
targets:
  - name: A
    builder: Linux A
    dependencies:
      - B
          ''',
              200,
            );
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              any,
              status: anyNamed('status'),
              conclusion: anyNamed('conclusion'),
              output: captureAnyNamed('output'),
            ),
          ).captured.first.text,
          'FormatException: ERROR: A depends on B which does not exist',
        );
      });

      test('retries only triggers failed builds only', () async {
        final MockBuildBucketClient mockBuildbucket = MockBuildBucketClient();
        buildStatusService =
            FakeBuildStatusService(commitStatuses: <CommitStatus>[CommitStatus(generateCommit(1), const <Stage>[])]);
        final FakePubSub pubsub = FakePubSub();
        scheduler = Scheduler(
          cache: cache,
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          buildStatusProvider: (_, __) => buildStatusService,
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildBucketClient: mockBuildbucket,
            gerritService: FakeGerritService(branchesValue: <String>['master']),
            pubsub: pubsub,
          ),
          fusionTester: fakeFusion,
        );
        when(mockBuildbucket.batch(any)).thenAnswer(
          (_) async => bbv2.BatchResponse(
            responses: <bbv2.BatchResponse_Response>[
              bbv2.BatchResponse_Response(
                searchBuilds: bbv2.SearchBuildsResponse(
                  builds: <bbv2.Build>[
                    generateBbv2Build(Int64(1000), name: 'Linux', bucket: 'try'),
                    generateBbv2Build(Int64(2000), name: 'Linux Coverage', bucket: 'try'),
                    generateBbv2Build(Int64(3000), name: 'Mac', bucket: 'try', status: bbv2.Status.SCHEDULED),
                    generateBbv2Build(Int64(4000), name: 'Windows', bucket: 'try', status: bbv2.Status.STARTED),
                    generateBbv2Build(Int64(5000), name: 'Linux A', bucket: 'try', status: bbv2.Status.FAILURE),
                  ],
                ),
              ),
            ],
          ),
        );
        when(mockBuildbucket.scheduleBuild(any)).thenAnswer(
          (_) async => generateBbv2Build(Int64(5001), name: 'Linux A', bucket: 'try', status: bbv2.Status.SCHEDULED),
        );
        // Only Linux A should be retried
        final Map<String, CheckRun> checkRuns = <String, CheckRun>{
          'Linux': createCheckRun(name: 'Linux', id: 100),
          'Linux Coverage': createCheckRun(name: 'Linux Coverage', id: 200),
          'Mac': createCheckRun(name: 'Mac', id: 300, status: CheckRunStatus.queued),
          'Windows': createCheckRun(name: 'Windows', id: 400, status: CheckRunStatus.inProgress),
          'Linux A': createCheckRun(name: 'Linux A', id: 500),
        };
        when(mockGithubChecksUtil.allCheckRuns(any, any)).thenAnswer((_) async {
          return checkRuns;
        });

        final CheckSuiteEvent checkSuiteEvent =
            CheckSuiteEvent.fromJson(jsonDecode(checkSuiteTemplate('rerequested')) as Map<String, dynamic>);
        await scheduler.retryPresubmitTargets(
          pullRequest: pullRequest,
          checkSuiteEvent: checkSuiteEvent,
        );

        expect(pubsub.messages.length, 1);
        final bbv2.BatchRequest batchRequest = bbv2.BatchRequest().createEmptyInstance();
        batchRequest.mergeFromProto3Json(pubsub.messages.single);
        expect(batchRequest.requests.length, 1);
        // Schedule build should have been sent
        expect(batchRequest.requests.single.scheduleBuild, isNotNull);
        final bbv2.ScheduleBuildRequest scheduleBuildRequest = batchRequest.requests.single.scheduleBuild;
        // Verify expected parameters to schedule build
        expect(scheduleBuildRequest.builder.builder, 'Linux A');
        expect(scheduleBuildRequest.properties.fields['custom']?.stringValue, 'abc');
      });

      test('pass github_build_label to properties', () async {
        final MockBuildBucketClient mockBuildbucket = MockBuildBucketClient();
        buildStatusService =
            FakeBuildStatusService(commitStatuses: <CommitStatus>[CommitStatus(generateCommit(1), const <Stage>[])]);
        final FakePubSub pubsub = FakePubSub();
        scheduler = Scheduler(
          cache: cache,
          config: config,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          buildStatusProvider: (_, __) => buildStatusService,
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildBucketClient: mockBuildbucket,
            gerritService: FakeGerritService(branchesValue: <String>['master']),
            pubsub: pubsub,
          ),
          fusionTester: fakeFusion,
        );
        when(mockBuildbucket.batch(any)).thenAnswer(
          (_) async => bbv2.BatchResponse(
            responses: <bbv2.BatchResponse_Response>[
              bbv2.BatchResponse_Response(
                searchBuilds: bbv2.SearchBuildsResponse(
                  builds: <bbv2.Build>[
                    generateBbv2Build(Int64(1000), name: 'Linux', bucket: 'try'),
                    generateBbv2Build(Int64(2000), name: 'Linux Coverage', bucket: 'try'),
                    generateBbv2Build(Int64(3000), name: 'Mac', bucket: 'try', status: bbv2.Status.SCHEDULED),
                    generateBbv2Build(Int64(4000), name: 'Windows', bucket: 'try', status: bbv2.Status.STARTED),
                    generateBbv2Build(Int64(5000), name: 'Linux A', bucket: 'try', status: bbv2.Status.FAILURE),
                  ],
                ),
              ),
            ],
          ),
        );
        when(mockBuildbucket.scheduleBuild(any)).thenAnswer(
          (_) async => generateBbv2Build(Int64(5001), name: 'Linux A', bucket: 'try', status: bbv2.Status.SCHEDULED),
        );
        // Only Linux A should be retried
        final Map<String, CheckRun> checkRuns = <String, CheckRun>{
          'Linux': createCheckRun(name: 'Linux', id: 100),
          'Linux Coverage': createCheckRun(name: 'Linux Coverage', id: 200),
          'Mac': createCheckRun(name: 'Mac', id: 300, status: CheckRunStatus.queued),
          'Windows': createCheckRun(name: 'Windows', id: 400, status: CheckRunStatus.inProgress),
          'Linux A': createCheckRun(name: 'Linux A', id: 500),
        };
        when(mockGithubChecksUtil.allCheckRuns(any, any)).thenAnswer((_) async {
          return checkRuns;
        });

        final CheckSuiteEvent checkSuiteEvent =
            CheckSuiteEvent.fromJson(jsonDecode(checkSuiteTemplate('rerequested')) as Map<String, dynamic>);
        await scheduler.retryPresubmitTargets(
          pullRequest: pullRequest,
          checkSuiteEvent: checkSuiteEvent,
        );

        expect(pubsub.messages.length, 1);
        final bbv2.BatchRequest batchRequest = bbv2.BatchRequest().createEmptyInstance();
        batchRequest.mergeFromProto3Json(pubsub.messages.single);
        expect(batchRequest.requests.length, 1);
        // Schedule build should have been sent
        expect(batchRequest.requests.single.scheduleBuild, isNotNull);
        final bbv2.ScheduleBuildRequest scheduleBuildRequest = batchRequest.requests.single.scheduleBuild;
        // Verify expected parameters to schedule build
        expect(scheduleBuildRequest.builder.builder, 'Linux A');
        expect(scheduleBuildRequest.properties.fields['custom']?.stringValue, 'abc');
      });

      test('triggers only specificed targets', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets = scheduler.filterTargets(presubmitTargets, <String>['Linux 1']);
        expect(presubmitTriggerTargets.length, 1);
      });

      test('triggers all presubmit targets when trigger list is null', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets = scheduler.filterTargets(presubmitTargets, null);
        expect(presubmitTriggerTargets.length, 2);
      });

      test('triggers all presubmit targets when trigger list is empty', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets = scheduler.filterTargets(presubmitTargets, <String>[]);
        expect(presubmitTriggerTargets.length, 2);
      });

      test('triggers only targets that are contained in the trigger list', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets =
            scheduler.filterTargets(presubmitTargets, <String>['Linux 1', 'Linux 3']);
        expect(presubmitTriggerTargets.length, 1);
        expect(presubmitTargets[0].value.name, 'Linux 1');
      });

      test('in fusion gathers creates engine builds', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
            return http.Response(fusionCiYaml, 200);
          } else if (request.url.path.endsWith('.ci.yaml')) {
            return http.Response(singleCiYaml, 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        final luci = MockLuciBuildService();
        when(luci.scheduleTryBuilds(targets: anyNamed('targets'), pullRequest: anyNamed('pullRequest')))
            .thenAnswer((inv) async {
          return [];
        });
        final MockGithubService mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
            .thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2];
          final name = inv.positionalArguments[3];
          checkRuns.add(createCheckRun(id: 1, owner: slug.owner, repo: slug.name, sha: sha, name: name));
          return checkRuns.last;
        });
        when(mockGithubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);

        fakeFusion.isFusion = (_, __) => true;

        when(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: anyNamed('sha'),
            stage: anyNamed('stage'),
            tasks: anyNamed('tasks'),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).thenAnswer((_) async => CiStaging());

        scheduler = Scheduler(
          cache: cache,
          config: FakeConfig(
            // tabledataResource: tabledataResource,
            dbValue: db,
            githubService: mockGithubService,
            githubClient: MockGitHub(),
            firestoreService: mockFirestoreService,
          ),
          buildStatusProvider: (_, __) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luci,
          fusionTester: fakeFusion,
          initializeCiStagingDocument: callbacks.initializeDocument,
        );
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        final results =
            verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
                .captured;
        stdout.writeAll(results);

        final result =
            verify(luci.scheduleTryBuilds(targets: captureAnyNamed('targets'), pullRequest: anyNamed('pullRequest')));
        expect(result.callCount, 1);
        final captured = result.captured;
        expect(captured[0], hasLength(1));
        // see the blend of fusionCiYaml and singleCiYaml
        expect(captured[0][0].getTestName, 'engine_build');

        expect(checkRuns, hasLength(2));
        verify(
          mockGithubChecksUtil.updateCheckRun(
            any,
            Config.flutterSlug,
            checkRuns[1],
            status: argThat(equals(CheckRunStatus.completed), named: 'status'),
            conclusion: argThat(equals(CheckRunConclusion.success), named: 'conclusion'),
            output: anyNamed('output'),
          ),
        ).called(1);

        verifyNever(
          mockGithubChecksUtil.updateCheckRun(
            any,
            Config.flutterSlug,
            checkRuns[0],
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            output: anyNamed('output'),
          ),
        );
      });
    });

    test('busted CheckRun does not kill the system', () {
      final data = scheduler.checkRunFromString(
        '{"name":"Merge Queue Guard","id":33947747856,"external_id":"","status":"queued","head_sha":"","check_suite":{"id":31681571627},"details_url":"https://flutter-dashboard.appspot.com","started_at":"2024-12-05T01:05:24.000Z","conclusion":"null"}',
      );
      expect(data.name, 'Merge Queue Guard');
      expect(data.id, 33947747856);
      expect(data.conclusion, CheckRunConclusion.empty);
    });

    group('merge groups', () {
      test('schedule some work on prod', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
            return http.Response(fusionDualCiYaml, 200);
          } else if (request.url.path.endsWith('.ci.yaml')) {
            return http.Response(singleCiYaml, 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        final luci = MockLuciBuildService();
        when(luci.getAvailableBuilderSet(project: anyNamed('project'), bucket: anyNamed('bucket')))
            .thenAnswer((inv) async {
          return {
            'Mac engine_build',
            'Linux engine_build',
          };
        });
        when(luci.scheduleTryBuilds(targets: anyNamed('targets'), pullRequest: anyNamed('pullRequest')))
            .thenAnswer((inv) async {
          return [];
        });
        final MockGithubService mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
            .thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2];
          final name = inv.positionalArguments[3];
          checkRuns.add(createCheckRun(id: 1, owner: slug.owner, repo: slug.name, sha: sha, name: name));
          return checkRuns.last;
        });
        when(mockGithubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);

        fakeFusion.isFusion = (_, __) => true;

        when(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: anyNamed('sha'),
            stage: anyNamed('stage'),
            tasks: anyNamed('tasks'),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).thenAnswer((_) async => CiStaging());

        scheduler = Scheduler(
          cache: cache,
          config: FakeConfig(
            // tabledataResource: tabledataResource,
            dbValue: db,
            githubService: mockGithubService,
            githubClient: MockGitHub(),
            firestoreService: mockFirestoreService,
          ),
          buildStatusProvider: (_, __) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luci,
          fusionTester: fakeFusion,
          initializeCiStagingDocument: callbacks.initializeDocument,
        );

        final mergeGroupEvent = cocoon_checks.MergeGroupEvent.fromJson(
          json.decode(
            generateMergeGroupEventString(
              repository: 'flutter/flutter',
              action: 'checks_requested',
              message: 'Implement an amazing feature',
            ),
          ),
        );

        await scheduler.triggerMergeGroupTargets(mergeGroupEvent: mergeGroupEvent);
        verify(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: argThat(equals('c9affbbb12aa40cb3afbe94b9ea6b119a256bebf'), named: 'sha'),
            stage: anyNamed('stage'),
            tasks: argThat(equals(['Linux engine_build', 'Mac engine_build']), named: 'tasks'),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).called(1);
        verify(
          luci.getAvailableBuilderSet(
            project: argThat(equals('flutter'), named: 'project'),
            bucket: argThat(equals('prod'), named: 'bucket'),
          ),
        ).called(1);

        verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
            .called(2);
        final result =
            verify(luci.scheduleMergeGroupBuilds(targets: captureAnyNamed('targets'), commit: anyNamed('commit')));
        expect(result.callCount, 1);
        expect(result.captured[0].map((target) => target.value.name), ['Linux engine_build', 'Mac engine_build']);

        expect(checkRuns, hasLength(2));
        verify(
          mockGithubChecksUtil.updateCheckRun(
            any,
            Config.flutterSlug,
            checkRuns[1],
            status: argThat(equals(CheckRunStatus.completed), named: 'status'),
            conclusion: argThat(equals(CheckRunConclusion.success), named: 'conclusion'),
            output: anyNamed('output'),
          ),
        ).called(1);

        verifyNever(
          mockGithubChecksUtil.updateCheckRun(
            any,
            Config.flutterSlug,
            checkRuns[0],
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            output: anyNamed('output'),
          ),
        );
      });

      test('handles missing builders', () async {
        httpClient = MockClient((http.Request request) async {
          if (request.url.path.endsWith('engine/src/flutter/.ci.yaml')) {
            return http.Response(fusionDualCiYaml, 200);
          } else if (request.url.path.endsWith('.ci.yaml')) {
            return http.Response(singleCiYaml, 200);
          }
          throw Exception('Failed to find ${request.url.path}');
        });
        final luci = MockLuciBuildService();
        when(luci.getAvailableBuilderSet(project: anyNamed('project'), bucket: anyNamed('bucket')))
            .thenAnswer((inv) async {
          return {
            'Mac engine_build',
          };
        });
        when(luci.scheduleTryBuilds(targets: anyNamed('targets'), pullRequest: anyNamed('pullRequest')))
            .thenAnswer((inv) async {
          return [];
        });
        final MockGithubService mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
            .thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2];
          final name = inv.positionalArguments[3];
          checkRuns.add(createCheckRun(id: 1, owner: slug.owner, repo: slug.name, sha: sha, name: name));
          return checkRuns.last;
        });
        when(mockGithubService.listFiles(any)).thenAnswer((_) async => ['abc/def']);

        fakeFusion.isFusion = (_, __) => true;
        when(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: anyNamed('sha'),
            stage: anyNamed('stage'),
            tasks: anyNamed('tasks'),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).thenAnswer((_) async => CiStaging());

        scheduler = Scheduler(
          cache: cache,
          config: FakeConfig(
            // tabledataResource: tabledataResource,
            dbValue: db,
            githubService: mockGithubService,
            githubClient: MockGitHub(),
            firestoreService: mockFirestoreService,
          ),
          buildStatusProvider: (_, __) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luci,
          fusionTester: fakeFusion,
          initializeCiStagingDocument: callbacks.initializeDocument,
        );

        final mergeGroupEvent = cocoon_checks.MergeGroupEvent.fromJson(
          json.decode(
            generateMergeGroupEventString(
              repository: 'flutter/flutter',
              action: 'checks_requested',
              message: 'Implement an amazing feature',
            ),
          ),
        );

        await scheduler.triggerMergeGroupTargets(mergeGroupEvent: mergeGroupEvent);
        verify(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: argThat(equals('c9affbbb12aa40cb3afbe94b9ea6b119a256bebf'), named: 'sha'),
            stage: anyNamed('stage'),
            tasks: argThat(equals(['Mac engine_build']), named: 'tasks'),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).called(1);
        verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
            .called(2);
        final result =
            verify(luci.scheduleMergeGroupBuilds(targets: captureAnyNamed('targets'), commit: anyNamed('commit')));
        expect(result.callCount, 1);
        expect(result.captured[0].map((target) => target.value.name), ['Mac engine_build']);

        expect(checkRuns, hasLength(2));
        verify(
          mockGithubChecksUtil.updateCheckRun(
            any,
            Config.flutterSlug,
            checkRuns[1],
            status: argThat(equals(CheckRunStatus.completed), named: 'status'),
            conclusion: argThat(equals(CheckRunConclusion.success), named: 'conclusion'),
            output: anyNamed('output'),
          ),
        ).called(1);

        verifyNever(
          mockGithubChecksUtil.updateCheckRun(
            any,
            Config.flutterSlug,
            checkRuns[0],
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            output: anyNamed('output'),
          ),
        );
      });
    });
  });
}

CheckRun createCheckRun({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flaux',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final String checkRunJson = checkRunFor(
    id: id,
    sha: sha,
    name: name,
    conclusion: conclusion,
    owner: owner,
    repo: repo,
    headBranch: headBranch,
    status: status,
    checkSuiteId: checkSuiteId,
  );
  return CheckRun.fromJson(jsonDecode(checkRunJson) as Map<String, dynamic>);
}

String toSha(Commit commit) => commit.sha!;

int toTimestamp(Commit commit) => commit.timestamp!;

String checkRunFor({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flaux',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final int externalId = id * 2;
  return '''{
  "id": $id,
  "external_id": "{$externalId}",
  "head_sha": "$sha",
  "name": "$name",
  "conclusion": "$conclusion",
  "started_at": "2020-05-10T02:49:31Z",
  "completed_at": "2020-05-10T03:11:08Z",
  "status": "$status",
  "check_suite": {
    "id": $checkSuiteId,
    "pull_requests": [],
    "conclusion": "$conclusion",
    "head_branch": "$headBranch"
  }
}''';
}

String checkRunEventFor({
  String action = 'completed',
  String sha = '1234',
  String test = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flaux',
}) =>
    '''{
  "action": "$action",
  "check_run": ${checkRunFor(name: test, sha: sha, conclusion: conclusion, owner: owner, repo: repo)},
  "repository": {
    "name": "$repo",
    "full_name": "$owner/$repo",
    "owner": {
      "avatar_url": "",
      "html_url": "",
      "login": "$owner",
      "id": 54371434
    }
  }
}''';
