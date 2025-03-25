// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/model/firestore/commit_tasks_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci_build_service/engine_artifacts.dart';
import 'package:cocoon_service/src/service/luci_build_service/pending_task.dart';
import 'package:cocoon_service/src/service/scheduler/process_check_run_result.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/checks_test_data.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_build_bucket_client.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_ci_yaml_fetcher.dart';
import '../src/service/fake_fusion_tester.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_get_files_changed.dart';
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
  useTestLoggerPerTest();

  late CacheService cache;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late FakeBuildStatusService buildStatusService;
  late FakeCiYamlFetcher ciYamlFetcher;
  late MockFirestoreService mockFirestoreService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Scheduler scheduler;
  late FakeFusionTester fakeFusion;
  late MockCallbacks callbacks;
  late FakeGetFilesChanged getFilesChanged;

  final pullRequest = generatePullRequest(id: 42);

  Commit shaToCommit(String sha, {String branch = 'master'}) {
    return Commit(
      key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
      repository: 'flutter/flutter',
      sha: sha,
      branch: branch,
      timestamp: int.parse(sha),
    );
  }

  setUp(() {
    ciYamlFetcher = FakeCiYamlFetcher();
    ciYamlFetcher.setCiYamlFrom(singleCiYaml);
  });

  group('Scheduler', () {
    setUp(() {
      final tabledataResource = MockTabledataResource();
      // ignore: discarded_futures
      when(tabledataResource.insertAll(any, any, any, any)).thenAnswer((
        _,
      ) async {
        return TableDataInsertAllResponse();
      });

      cache = CacheService(inMemory: true);
      getFilesChanged = FakeGetFilesChanged();
      db = FakeDatastoreDB();

      mockFirestoreService = MockFirestoreService();
      when(
        // ignore: discarded_futures
        mockFirestoreService.queryRecentTasksByName(
          name: anyNamed('name'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => []);

      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: [
          CommitTasksStatus(generateFirestoreCommit(1), []),
        ],
      );
      config = FakeConfig(
        tabledataResource: tabledataResource,
        dbValue: db,
        githubService: FakeGithubService(),
        githubClient: MockGitHub(),
        firestoreService: mockFirestoreService,
        supportedReposValue: <RepositorySlug>{
          Config.flutterSlug,
          Config.packagesSlug,
        },
      );

      mockGithubChecksUtil = MockGithubChecksUtil();
      // Generate check runs based on the name hash code
      when(
        // ignore: discarded_futures
        mockGithubChecksUtil.createCheckRun(
          any,
          any,
          any,
          any,
          output: anyNamed('output'),
        ),
      ).thenAnswer((Invocation invocation) async {
        return generateCheckRun(
          invocation.positionalArguments[2].hashCode,
          name: invocation.positionalArguments[3] as String,
        );
      });

      fakeFusion = FakeFusionTester();
      callbacks = MockCallbacks();

      scheduler = Scheduler(
        cache: cache,
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
        buildStatusProvider: (_) => buildStatusService,
        githubChecksService: GithubChecksService(
          config,
          githubChecksUtil: mockGithubChecksUtil,
        ),
        ciYamlFetcher: ciYamlFetcher,
        getFilesChanged: getFilesChanged,
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

      // ignore: discarded_futures
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((
        _,
      ) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2},
        });
      });
    });

    test('fusion, getPresubmitTargets supports two ci.yamls', () async {
      ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);
      fakeFusion.isFusion = (_, _) => true;

      final presubmitTargets = await scheduler.getPresubmitTargets(pullRequest);

      expect([
        ...presubmitTargets.map((Target target) => target.value.name),
      ], containsAll(<String>['Linux A']));
      presubmitTargets
        ..clear()
        ..addAll(
          await scheduler.getPresubmitTargets(
            pullRequest,
            type: CiType.fusionEngine,
          ),
        );
      expect([
        ...presubmitTargets.map((Target target) => target.value.name),
      ], containsAll(<String>['Linux Z']));
    });

    group('add commits', () {
      final pubsub = FakePubSub();
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
            key: db.emptyKey.append(
              Commit,
              id: 'flutter/$repo/$branch/${shas[index]}',
            ),
            message: 'commit message',
            repository: 'flutter/$repo',
            sha: shas[index],
            timestamp:
                DateTime.fromMillisecondsSinceEpoch(
                  int.parse(shas[index]),
                ).millisecondsSinceEpoch,
          ),
        );
      }

      test('succeeds when GitHub returns no commits', () async {
        await scheduler.addCommits(<Commit>[]);
        expect(db.values, isEmpty);
      });

      test('inserts all relevant fields of the commit', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        config.supportedBranchesValue = <String>['master'];
        expect(db.values.values.whereType<Commit>().length, 0);
        await scheduler.addCommits(createCommitList(<String>['1']));
        expect(db.values.values.whereType<Commit>().length, 1);
        final commit = db.values.values.whereType<Commit>().single;
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
        await scheduler.addCommits(
          createCommitList(<String>['1'], repo: 'not-supported'),
        );
        expect(db.values.values.whereType<Commit>().length, 0);
      });

      test('skips commits for which transaction commit fails', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        config.supportedBranchesValue = <String>['master'];

        // Existing commits should not be duplicated.
        final commit = shaToCommit('1');
        db.values[commit.key] = commit;

        db.onCommit = (
          List<gcloud_db.Model<Object?>> inserts,
          List<gcloud_db.Key<Object?>> deletes,
        ) {
          if (inserts
              .whereType<Commit>()
              .where((Commit commit) => commit.sha == '3')
              .isNotEmpty) {
            throw StateError('Commit failed');
          }
        };
        // Commits are expect from newest to oldest timestamps
        await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
        expect(db.values.values.whereType<Commit>().length, 3);
        // The 2 new commits are scheduled 3 tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 3);
        // Check commits were added, but 3 was not
        expect(
          db.values.values.whereType<Commit>().map<String>(toSha),
          containsAll(<String>['1', '2', '4']),
        );
        expect(
          db.values.values.whereType<Commit>().map<String>(toSha),
          isNot(contains('3')),
        );
      });

      test('skips commits for which task transaction fails', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        config.supportedBranchesValue = <String>['master'];

        // Existing commits should not be duplicated.
        final commit = shaToCommit('1');
        db.values[commit.key] = commit;

        db.onCommit = (
          List<gcloud_db.Model<Object?>> inserts,
          List<gcloud_db.Key<Object?>> deletes,
        ) {
          if (inserts
              .whereType<Task>()
              .where((Task task) => task.createTimestamp == 3)
              .isNotEmpty) {
            throw StateError('Task failed');
          }
        };
        // Commits are expect from newest to oldest timestamps
        await scheduler.addCommits(createCommitList(<String>['2', '3', '4']));
        expect(db.values.values.whereType<Commit>().length, 3);
        // The 2 new commits are scheduled 3 tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 3);
        // Check commits were added, but 3 was not
        expect(
          db.values.values.whereType<Commit>().map<String>(toSha),
          containsAll(<String>['1', '2', '4']),
        );
        expect(
          db.values.values.whereType<Commit>().map<String>(toSha),
          isNot(contains('3')),
        );
      });

      test('schedules cocoon based targets', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final luciBuildService = MockLuciBuildService();
        when(
          luciBuildService.schedulePostsubmitBuilds(
            commit: anyNamed('commit'),
            toBeScheduled: captureAnyNamed('toBeScheduled'),
          ),
        ).thenAnswer((_) async => []);
        buildStatusService = FakeBuildStatusService(
          commitTasksStatuses: [
            CommitTasksStatus(
              generateFirestoreCommit(1, repo: 'packages', branch: 'main'),
              [],
            ),
          ],
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
          luciBuildService: luciBuildService,
          fusionTester: fakeFusion,
        );

        // This test is testing `GuaranteedPolicy` get scheduled - there's only one now.
        await scheduler.addCommits(
          createCommitList(<String>['1'], branch: 'main', repo: 'packages'),
        );
        final List<Object?> captured =
            verify(
              luciBuildService.schedulePostsubmitBuilds(
                commit: anyNamed('commit'),
                toBeScheduled: captureAnyNamed('toBeScheduled'),
              ),
            ).captured;
        final toBeScheduled = captured.first as List<Object?>;
        expect(toBeScheduled.length, 2);
        final tuples = toBeScheduled.map(
          (dynamic tuple) => tuple as PendingTask,
        );
        final scheduledTargetNames = tuples.map(
          (PendingTask tuple) => tuple.task.name!,
        );
        expect(scheduledTargetNames, ['Linux A', 'Linux runIf']);
        // Tasks triggered by cocoon are marked as in progress
        final tasks = db.values.values.whereType<Task>();
        expect(
          tasks.singleWhere((Task task) => task.name == 'Linux A').status,
          Task.statusInProgress,
        );
      });

      test(
        'schedules cocoon based targets - multiple batch requests',
        () async {
          when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer(
            (Invocation invocation) {
              return Future<CommitResponse>.value(CommitResponse());
            },
          );
          final mockBuildBucketClient = MockBuildBucketClient();
          final luciBuildService = FakeLuciBuildService(
            config: config,
            buildBucketClient: mockBuildBucketClient,
            gerritService: FakeGerritService(),
            githubChecksUtil: mockGithubChecksUtil,
            pubsub: pubsub,
          );
          when(
            mockGithubChecksUtil.createCheckRun(
              any,
              any,
              any,
              any,
              output: anyNamed('output'),
            ),
          ).thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));

          when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
            return bbv2.ListBuildersResponse(
              builders: [
                bbv2.BuilderItem(
                  id: bbv2.BuilderID(
                    bucket: 'prod',
                    project: 'flutter',
                    builder: 'Linux A',
                  ),
                ),
                bbv2.BuilderItem(
                  id: bbv2.BuilderID(
                    bucket: 'prod',
                    project: 'flutter',
                    builder: 'Linux runIf',
                  ),
                ),
              ],
            );
          });
          buildStatusService = FakeBuildStatusService(
            commitTasksStatuses: [
              CommitTasksStatus(
                generateFirestoreCommit(1, repo: 'packages', branch: 'main'),
                [],
              ),
            ],
          );
          config.batchSizeValue = 1;
          scheduler = Scheduler(
            cache: cache,
            config: config,
            buildStatusProvider: (_) => buildStatusService,
            datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
            githubChecksService: GithubChecksService(
              config,
              githubChecksUtil: mockGithubChecksUtil,
            ),
            getFilesChanged: getFilesChanged,
            ciYamlFetcher: ciYamlFetcher,
            luciBuildService: luciBuildService,
            fusionTester: fakeFusion,
          );

          await scheduler.addCommits(
            createCommitList(<String>['1'], repo: 'packages', branch: 'main'),
          );
          expect(pubsub.messages.length, 2);
        },
      );
    });

    group('add pull request', () {
      test('creates expected commit', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        final commit = db.values.values.whereType<Commit>().single;
        expect(commit.repository, 'flutter/flutter');
        expect(commit.branch, 'master');
        expect(commit.sha, 'abc');
        expect(commit.timestamp, 1);
        expect(commit.author, 'dash');
        expect(commit.authorAvatarUrl, 'dashatar');
        expect(commit.message, 'example message');

        final List<Object?> captured =
            verify(
              mockFirestoreService.writeViaTransaction(captureAny),
            ).captured;
        expect(captured.length, 1);
        final commitResponse = captured[0] as List<Write>;
        expect(commitResponse.length, 4);
      });

      test('run all tasks if regular release candidate branch', () async {
        fakeFusion.isFusion = (_, _) => true;
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);

        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final mergedPr = generatePullRequest(
          branch: 'flutter-1.23-candidate.0',
        );
        await scheduler.addPullRequest(mergedPr);

        expect(
          db.values.values.whereType<Task>(),
          everyElement(
            isA<Task>().having(
              (t) => t.status,
              'status',
              Task.statusInProgress,
            ),
          ),
          reason: 'Skips all post-submit targets',
        );
      });

      test(
        'skips all tasks if experimental release candidate branch',
        () async {
          fakeFusion.isFusion = (_, _) => true;
          ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);

          when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer(
            (Invocation invocation) {
              return Future<CommitResponse>.value(CommitResponse());
            },
          );
          final mergedPr = generatePullRequest(
            branch: 'flutter-0.42-candidate.0',
          );
          await scheduler.addPullRequest(mergedPr);

          expect(
            db.values.values.whereType<Task>(),
            everyElement(
              isA<Task>().having((t) => t.status, 'status', Task.statusSkipped),
            ),
            reason: 'Skips all post-submit targets',
          );
        },
      );

      test('schedules tasks against merged PRs', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 3);
      });

      test('schedules tasks against merged PRs (fusion)', () async {
        // NOTE: The scheduler doesn't actually do anything except for write backfill requests - unless its a release.
        // When backfills are picked up, they'll go through the same flow (schedulePostsubmitBuilds).
        fakeFusion.isFusion = (_, _) => true;
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(
          db.values.values.whereType<Task>().map((t) => t.name),
          [
            'Linux A',
            'Linux runIf',
            'Google Internal Roll',
            'Linux Z',
            'Linux runIf engine',
          ],
          reason: 'removes release_build targets (Linux engine_build)',
        );
        final captured =
            verify(
              mockFirestoreService.writeViaTransaction(captureAny),
            ).captured.cast<List<Write>>();
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

      test(
        'guarantees scheduling of tasks against merged release branch PR',
        () async {
          when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer(
            (Invocation invocation) {
              return Future<CommitResponse>.value(CommitResponse());
            },
          );
          final mergedPr = generatePullRequest(
            branch: 'flutter-3.2-candidate.5',
          );
          await scheduler.addPullRequest(mergedPr);

          expect(db.values.values.whereType<Commit>().length, 1);
          expect(db.values.values.whereType<Task>().length, 3);
          // Ensure all tasks have been marked in progress
          expect(
            db.values.values.whereType<Task>().where(
              (Task task) => task.status == Task.statusNew,
            ),
            isEmpty,
          );
        },
      );

      test(
        'Release candidate branch commit filters builders not in default branch',
        () async {
          when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer(
            (Invocation invocation) {
              return Future<CommitResponse>.value(CommitResponse());
            },
          );

          ciYamlFetcher.setCiYamlFrom(r'''
          enabled_branches:
            - main
            - flutter-\d+\.\d+-candidate\.\d+
          targets:
            - name: Linux A
              properties:
                custom: abc
          ''');
          scheduler = Scheduler(
            cache: cache,
            config: config,
            datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
            buildStatusProvider: (_) => buildStatusService,
            githubChecksService: GithubChecksService(
              config,
              githubChecksUtil: mockGithubChecksUtil,
            ),
            getFilesChanged: getFilesChanged,
            ciYamlFetcher: ciYamlFetcher,
            luciBuildService: FakeLuciBuildService(
              config: config,
              githubChecksUtil: mockGithubChecksUtil,
              gerritService: FakeGerritService(
                branchesValue: <String>['master', 'main'],
              ),
            ),
            fusionTester: fakeFusion,
          );

          final mergedPr = generatePullRequest(
            repo: Config.flutterSlug.name,
            branch: 'flutter-3.10-candidate.1',
          );
          await scheduler.addPullRequest(mergedPr);

          final tasks = db.values.values.whereType<Task>().toList();
          expect(db.values.values.whereType<Commit>().length, 1);
          expect(tasks, hasLength(1));
          expect(tasks.first.name, 'Linux A');
          // Ensure all tasks under cocoon scheduler have been marked in progress
          expect(
            db.values.values
                .whereType<Task>()
                .where((Task task) => task.status == Task.statusInProgress)
                .length,
            1,
          );
        },
      );

      test('does not schedule tasks against non-merged PRs', () async {
        final notMergedPr = generatePullRequest(merged: false);
        await scheduler.addPullRequest(notMergedPr);

        expect(
          db.values.values.whereType<Commit>().map<String>(toSha).length,
          0,
        );
        expect(db.values.values.whereType<Task>().length, 0);
      });

      test('does not schedule tasks against already added PRs', () async {
        // Existing commits should not be duplicated.
        final commit = shaToCommit('1');
        db.values[commit.key] = commit;

        final alreadyLandedPr = generatePullRequest(headSha: '1');
        await scheduler.addPullRequest(alreadyLandedPr);

        expect(
          db.values.values.whereType<Commit>().map<String>(toSha).length,
          1,
        );
        // No tasks should be scheduled as that is done on commit insert.
        expect(db.values.values.whereType<Task>().length, 0);
      });

      test('creates expected commit from release branch PR', () async {
        when(mockFirestoreService.writeViaTransaction(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<CommitResponse>.value(CommitResponse());
        });
        final mergedPr = generatePullRequest(branch: '1.26');
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        final commit = db.values.values.whereType<Commit>().single;
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
        final mockGithubService = MockGithubService();
        final mockGithubClient = MockGitHub();
        buildStatusService = FakeBuildStatusService(
          commitTasksStatuses: [
            CommitTasksStatus(generateFirestoreCommit(1), []),
          ],
        );
        config = FakeConfig(
          githubService: mockGithubService,
          firestoreService: mockFirestoreService,
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          fusionTester: fakeFusion,
        );
        when(mockGithubService.github).thenReturn(mockGithubClient);
        when(
          mockGithubService.searchIssuesAndPRs(
            any,
            any,
            sort: anyNamed('sort'),
            pages: anyNamed('pages'),
          ),
        ).thenAnswer((_) async => [generateIssue(3)]);
        when(
          mockGithubChecksUtil.listCheckSuitesForRef(
            any,
            any,
            ref: anyNamed('ref'),
          ),
        ).thenAnswer(
          (_) async => [
            // From check_run.check_suite.id in [checkRunString].
            generateCheckSuite(668083231),
          ],
        );
        when(
          mockGithubService.getPullRequest(any, any),
        ).thenAnswer((_) async => generatePullRequest());
        getFilesChanged.cannedFiles = ['abc/def'];
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
            'name': Config.kCiYamlCheckName,
            'check_suite': <String, dynamic>{'id': 2},
          });
        });
        final checkRunEventJson =
            jsonDecode(checkRunString) as Map<String, dynamic>;
        checkRunEventJson['check_run']['name'] = Config.kCiYamlCheckName;
        final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          checkRunEventJson,
        );
        expect(
          await scheduler.processCheckRun(checkRunEvent),
          const ProcessCheckRunResult.success(),
        );
        verify(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            Config.kCiYamlCheckName,
            output: anyNamed('output'),
          ),
        );
        // Verfies Linux A was created
        verify(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).called(1);
      });

      test(
        'rerequested fusion (engine) ci.yaml check retriggers presubmit',
        () async {
          final mockGithubService = MockGithubService();
          final mockGithubClient = MockGitHub();
          buildStatusService = FakeBuildStatusService(
            commitTasksStatuses: [
              CommitTasksStatus(generateFirestoreCommit(1), []),
            ],
          );
          config = FakeConfig(
            githubService: mockGithubService,
            firestoreService: mockFirestoreService,
          );

          final pullRequest = generatePullRequest();

          // Enable fusion (modern flutter/flutter merged)
          fakeFusion.isFusion = (_, _) => true;
          ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);
          config.maxFilesChangedForSkippingEnginePhaseValue = 0;
          scheduler = Scheduler(
            cache: cache,
            config: config,
            buildStatusProvider: (_) => buildStatusService,
            githubChecksService: GithubChecksService(
              config,
              githubChecksUtil: mockGithubChecksUtil,
            ),
            getFilesChanged: getFilesChanged,
            ciYamlFetcher: ciYamlFetcher,
            luciBuildService: FakeLuciBuildService(
              config: config,
              githubChecksUtil: mockGithubChecksUtil,
            ),
            fusionTester: fakeFusion,
            findPullRequestForSha: (_, sha) async {
              return pullRequest;
            },
          );
          when(mockGithubService.github).thenReturn(mockGithubClient);
          when(
            mockGithubService.searchIssuesAndPRs(
              any,
              any,
              sort: anyNamed('sort'),
              pages: anyNamed('pages'),
            ),
          ).thenAnswer((_) async => [generateIssue(3)]);
          when(
            mockGithubChecksUtil.listCheckSuitesForRef(
              any,
              any,
              ref: anyNamed('ref'),
            ),
          ).thenAnswer(
            (_) async => [
              // From check_run.check_suite.id in [checkRunString].
              generateCheckSuite(668083231),
            ],
          );
          when(
            mockGithubService.getPullRequest(any, any),
          ).thenAnswer((_) async => pullRequest);
          getFilesChanged.cannedFiles = ['abc/def'];
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
              'name': 'Linux engine_build',
              'check_suite': <String, dynamic>{'id': 2},
            });
          });
          final checkRunEventJson =
              jsonDecode(checkRunString) as Map<String, dynamic>;
          checkRunEventJson['check_run']['name'] = 'Linux engine_build';
          final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
            checkRunEventJson,
          );
          expect(
            await scheduler.processCheckRun(checkRunEvent),
            const ProcessCheckRunResult.success(),
          );
          verify(
            mockGithubChecksUtil.createCheckRun(
              any,
              any,
              any,
              'Linux engine_build',
              output: anyNamed('output'),
            ),
          );
        },
      );

      test('rerequested merge queue guard check is ignored', () async {
        final mockGithubService = MockGithubService();
        final mockGithubClient = MockGitHub();
        buildStatusService = FakeBuildStatusService(
          commitTasksStatuses: [
            CommitTasksStatus(generateFirestoreCommit(1), []),
          ],
        );
        config = FakeConfig(
          githubService: mockGithubService,
          firestoreService: mockFirestoreService,
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          fusionTester: fakeFusion,
        );
        when(mockGithubService.github).thenReturn(mockGithubClient);
        when(
          mockGithubService.searchIssuesAndPRs(
            any,
            any,
            sort: anyNamed('sort'),
            pages: anyNamed('pages'),
          ),
        ).thenAnswer((_) async => [generateIssue(3)]);
        when(
          mockGithubChecksUtil.listCheckSuitesForRef(
            any,
            any,
            ref: anyNamed('ref'),
          ),
        ).thenAnswer(
          (_) async => [
            // From check_run.check_suite.id in [checkRunString].
            generateCheckSuite(668083231),
          ],
        );
        when(
          mockGithubService.getPullRequest(any, any),
        ).thenAnswer((_) async => generatePullRequest());
        getFilesChanged.cannedFiles = ['abc/def'];
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
            'name': Config.kCiYamlCheckName,
            'check_suite': <String, dynamic>{'id': 2},
          });
        });
        final checkRunEventJson =
            jsonDecode(checkRunString) as Map<String, dynamic>;
        checkRunEventJson['check_run']['name'] = Config.kMergeQueueLockName;
        final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          checkRunEventJson,
        );
        expect(
          await scheduler.processCheckRun(checkRunEvent),
          const ProcessCheckRunResult.success(),
        );
        verifyNever(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            Config.kMergeQueueLockName,
            output: anyNamed('output'),
          ),
        );
        // Verfies Linux A was created
        verifyNever(mockGithubChecksUtil.createCheckRun(any, any, any, any));
      });

      test('rerequested presubmit check triggers presubmit build', () async {
        // Note that we're not inserting any commits into the db, because
        // only postsubmit commits are stored in the datastore.
        db = FakeDatastoreDB();
        config = FakeConfig(
          dbValue: db,
          firestoreService: mockFirestoreService,
        );
        buildStatusService = FakeBuildStatusService(
          commitTasksStatuses: [
            CommitTasksStatus(generateFirestoreCommit(1), []),
          ],
        );

        when(callbacks.findPullRequestForSha(any, any)).thenAnswer((inv) async {
          return pullRequest;
        });

        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);

        final luci = MockLuciBuildService();
        when(
          luci.scheduleTryBuilds(
            targets: anyNamed('targets'),
            pullRequest: anyNamed('pullRequest'),
            engineArtifacts: anyNamed('engineArtifacts'),
          ),
        ).thenAnswer((inv) async {
          return [];
        });

        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          luciBuildService: luci,
          fusionTester: fakeFusion,
          findPullRequestForSha: callbacks.findPullRequestForSha,
          ciYamlFetcher: ciYamlFetcher,
        );

        final checkrun = jsonDecode(checkRunString) as Map<String, dynamic>;
        checkrun['name'] = checkrun['check_run']['name'] = 'Linux A';
        final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(checkrun);

        expect(
          await scheduler.processCheckRun(checkRunEvent),
          const ProcessCheckRunResult.success(),
        );

        verify(
          callbacks.findPullRequestForSha(any, checkRunEvent.checkRun!.headSha),
        ).called(1);
        final captured =
            verify(
              luci.scheduleTryBuilds(
                targets: captureAnyNamed('targets'),
                pullRequest: captureAnyNamed('pullRequest'),
                engineArtifacts: anyNamed('engineArtifacts'),
              ),
            ).captured;

        expect(captured, hasLength(2));
        expect(captured[0].first.value.name, 'Linux A');
        expect(captured[1], pullRequest);
      });

      test('rerequested postsubmit check triggers postsubmit build', () async {
        // Set up datastore with postsubmit entities matching [checkRunString].
        db = FakeDatastoreDB();
        config = FakeConfig(
          dbValue: db,
          postsubmitSupportedReposValue: {RepositorySlug('abc', 'cocoon')},
          firestoreService: mockFirestoreService,
        );
        when(mockFirestoreService.queryCommitTasks(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Future<List<firestore.Task>>.value(<firestore.Task>[
            generateFirestoreTask(1, name: 'test1'),
          ]);
        });
        when(
          mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
        ).thenAnswer((Invocation invocation) {
          return Future<BatchWriteResponse>.value(BatchWriteResponse());
        });
        final commit = generateCommit(
          1,
          sha: '66d6bd9a3f79a36fe4f5178ccefbc781488a596c',
          branch: 'independent_agent',
          owner: 'abc',
          repo: 'cocoon',
        );
        final commitToT = generateCommit(
          1,
          sha: '66d6bd9a3f79a36fe4f5178ccefbc781488a592c',
          branch: 'master',
          owner: 'abc',
          repo: 'cocoon',
        );
        config.db.values[commit.key] = commit;
        config.db.values[commitToT.key] = commitToT;
        final task = generateTask(1, name: 'test1', parent: commit);
        config.db.values[task.key] = task;

        // Set up ci.yaml with task name and branch name from [checkRunString].
        ciYamlFetcher.setCiYamlFrom(r'''
enabled_branches:
  - independent_agent
  - master
targets:
  - name: test1
''');

        // Set up mock buildbucket to validate which bucket is requested.
        final mockBuildbucket = MockBuildBucketClient();
        when(mockBuildbucket.batch(any)).thenAnswer((i) async {
          return FakeBuildBucketClient().batch(
            i.positionalArguments[0] as bbv2.BatchRequest,
          );
        });
        when(
          mockBuildbucket.scheduleBuild(
            any,
            buildBucketUri: anyNamed('buildBucketUri'),
          ),
        ).thenAnswer((realInvocation) async {
          final scheduleBuildRequest =
              realInvocation.positionalArguments[0]
                  as bbv2.ScheduleBuildRequest;
          // Ensure this is an attempt to schedule a postsubmit build by
          // verifying that bucket == 'prod'.
          expect(scheduleBuildRequest.builder.bucket, equals('prod'));
          return bbv2.Build(builder: bbv2.BuilderID(), id: Int64());
        });
        final pubsub = FakePubSub();
        final luciBuildService = FakeLuciBuildService(
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
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
          luciBuildService: luciBuildService,
          fusionTester: fakeFusion,
        );
        final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunString) as Map<String, dynamic>,
        );
        expect(
          await scheduler.processCheckRun(checkRunEvent),
          const ProcessCheckRunResult.success(),
        );
        verify(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).called(1);
        expect(pubsub.messages.length, 1);
      });

      test('rerequested does not fail on empty pull request list', () async {
        when(
          mockGithubChecksUtil.createCheckRun(any, any, any, any),
        ).thenAnswer((_) async {
          return CheckRun.fromJson(const <String, dynamic>{
            'id': 1,
            'started_at': '2020-05-10T02:49:31Z',
            'check_suite': <String, dynamic>{'id': 2},
          });
        });
        when(callbacks.findPullRequestForSha(any, any)).thenAnswer((inv) async {
          return null;
        });
        final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunWithEmptyPullRequests) as Map<String, dynamic>,
        );

        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          luciBuildService: FakeLuciBuildService(config: config),
          fusionTester: fakeFusion,
          findPullRequestForSha: callbacks.findPullRequestForSha,
          ciYamlFetcher: ciYamlFetcher,
        );
        expect(
          await scheduler.processCheckRun(checkRunEvent),
          isA<UserErrorResult>().having(
            (e) => e.message,
            'message',
            contains('Asked to reschedule presubmits for unknown sha/PR'),
          ),
        );
        verifyNever(mockGithubChecksUtil.createCheckRun(any, any, any, any));
      });

      group('completed action', () {
        test('works for non fusion cases', () async {
          fakeFusion.isFusion = (_, _) => false;
          expect(
            await scheduler.processCheckRun(
              cocoon_checks.CheckRunEvent.fromJson(
                json.decode(checkRunEventFor()) as Map<String, Object?>,
              ),
            ),
            const ProcessCheckRunResult.success(),
          );
        });

        group('in fusion', () {
          setUp(() {
            fakeFusion.isFusion = (_, _) => true;
          });

          test(
            'ignores default check runs that have no side effects',
            () async {
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
                return const StagingConclusion(
                  result: StagingConclusionResult.missing,
                  remaining: 1,
                  checkRunGuard: '{}',
                  failed: 0,
                  summary: 'Field missing',
                  details: 'Some details',
                );
              });

              for (final ignored in Scheduler.kCheckRunsToIgnore) {
                expect(
                  await scheduler.processCheckRunCompletion(
                    cocoon_checks.CheckRunEvent.fromJson(
                      json.decode(checkRunEventFor(test: ignored))
                          as Map<String, Object?>,
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
            },
          );

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
              return const StagingConclusion(
                result: StagingConclusionResult.internalError,
                remaining: 1,
                checkRunGuard: '{}',
                failed: 0,
                summary: 'Internal error',
                details: 'Some details',
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar'))
                      as Map<String, Object?>,
                ),
              ),
              isFalse,
            );
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                sha: '1234',
                stage: argThat(
                  equals(CiStage.fusionEngineBuild),
                  named: 'stage',
                ),
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
              return const StagingConclusion(
                result: StagingConclusionResult.ok,
                remaining: 1,
                checkRunGuard: '{}',
                failed: 0,
                summary: 'OK',
                details: 'Some details',
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar'))
                      as Map<String, Object?>,
                ),
              ),
              isFalse,
            );
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                sha: '1234',
                stage: argThat(
                  equals(CiStage.fusionEngineBuild),
                  named: 'stage',
                ),
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

          // The merge guard is not closed until both engine build and tests
          // complete and are successful.
          // This behavior is explained here:
          // https://github.com/flutter/flutter/issues/159898#issuecomment-2597209435
          test(
            'failed tests neither unlock merge queue guard nor schedule test stage',
            () async {
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
                  result: StagingConclusionResult.ok,
                  remaining: 0,
                  checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                  failed: 1,
                  summary: 'OK',
                  details: 'Some details',
                );
              });

              expect(
                await scheduler.processCheckRunCompletion(
                  cocoon_checks.CheckRunEvent.fromJson(
                    json.decode(checkRunEventFor(test: 'Bar bar'))
                        as Map<String, Object?>,
                  ),
                ),
                isTrue,
              );
              verify(
                callbacks.markCheckRunConclusion(
                  firestoreService: argThat(
                    isNotNull,
                    named: 'firestoreService',
                  ),
                  slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                  sha: '1234',
                  stage: argThat(
                    equals(CiStage.fusionEngineBuild),
                    named: 'stage',
                  ),
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
            },
          );

          test('schedules tests after engine stage', () async {
            final githubService = config.githubService = MockGithubService();
            final githubClient = MockGitHub();
            when(githubService.github).thenReturn(githubClient);
            when(
              githubService.searchIssuesAndPRs(
                any,
                any,
                sort: anyNamed('sort'),
                pages: anyNamed('pages'),
              ),
            ).thenAnswer((_) async => [generateIssue(42)]);

            final pullRequest = generatePullRequest();
            when(
              githubService.getPullRequest(any, any),
            ).thenAnswer((_) async => pullRequest);
            getFilesChanged.cannedFiles = ['abc/def'];
            when(
              mockGithubChecksUtil.listCheckSuitesForRef(
                any,
                any,
                ref: anyNamed('ref'),
              ),
            ).thenAnswer(
              (_) async => [
                // From check_run.check_suite.id in [checkRunString].
                generateCheckSuite(668083231),
              ],
            );

            ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);
            final luci = MockLuciBuildService();
            when(
              luci.scheduleTryBuilds(
                targets: anyNamed('targets'),
                pullRequest: anyNamed('pullRequest'),
                engineArtifacts: anyNamed('engineArtifacts'),
              ),
            ).thenAnswer((inv) async {
              return [];
            });

            final gitHubChecksService = MockGithubChecksService();
            when(
              gitHubChecksService.githubChecksUtil,
            ).thenReturn(mockGithubChecksUtil);
            when(
              gitHubChecksService.findMatchingPullRequest(any, any, any),
            ).thenAnswer((inv) async {
              return pullRequest;
            });

            // Cocoon creates a Firestore document to track the tasks in the
            // test stage.
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
              config: config,
              datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
              buildStatusProvider: (_) => buildStatusService,
              getFilesChanged: getFilesChanged,
              githubChecksService: gitHubChecksService,
              ciYamlFetcher: ciYamlFetcher,
              luciBuildService: luci,
              fusionTester: fakeFusion,
              markCheckRunConclusion: callbacks.markCheckRunConclusion,
              initializeCiStagingDocument: callbacks.initializeDocument,
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
                result: StagingConclusionResult.ok,
                remaining: 0,
                checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                failed: 0,
                summary: 'OK',
                details: 'Some details',
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar', sha: 'testSha'))
                      as Map<String, Object?>,
                ),
              ),
              isTrue,
            );

            verify(
              gitHubChecksService.findMatchingPullRequest(
                Config.flutterSlug,
                'testSha',
                668083231,
              ),
            ).called(1);

            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                sha: 'testSha',
                stage: argThat(
                  equals(CiStage.fusionEngineBuild),
                  named: 'stage',
                ),
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

            final result = verify(
              luci.scheduleTryBuilds(
                targets: captureAnyNamed('targets'),
                pullRequest: captureAnyNamed('pullRequest'),
                engineArtifacts: anyNamed('engineArtifacts'),
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

          test('tracks test check runs in firestore', () async {
            final githubService = config.githubService = MockGithubService();
            final githubClient = MockGitHub();
            final luci = MockLuciBuildService();
            final gitHubChecksService = MockGithubChecksService();

            when(githubService.github).thenReturn(githubClient);
            when(
              gitHubChecksService.githubChecksUtil,
            ).thenReturn(mockGithubChecksUtil);

            scheduler = Scheduler(
              cache: cache,
              config: config,
              datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
              buildStatusProvider: (_) => buildStatusService,
              getFilesChanged: getFilesChanged,
              githubChecksService: gitHubChecksService,
              ciYamlFetcher: ciYamlFetcher,
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
              final stage = inv.namedArguments[#stage] as CiStage;
              return StagingConclusion(
                result: switch (stage) {
                  CiStage.fusionEngineBuild => StagingConclusionResult.missing,
                  CiStage.fusionTests => StagingConclusionResult.ok,
                },
                remaining: 0,
                checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                failed: 0,
                summary: 'Field missing or OK',
                details: 'Some details',
              );
            });

            expect(
              await scheduler.processCheckRunCompletion(
                cocoon_checks.CheckRunEvent.fromJson(
                  json.decode(checkRunEventFor(test: 'Bar bar', sha: 'testSha'))
                      as Map<String, Object?>,
                ),
              ),
              isTrue,
            );

            // The first invocation looks in the fusionEngineBuild stage, which
            // returns "missing" result.
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                sha: 'testSha',
                stage: argThat(
                  equals(CiStage.fusionEngineBuild),
                  named: 'stage',
                ),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            // The second invocation looks in the fusionTests stage, which returns
            // "ok" result.
            verify(
              callbacks.markCheckRunConclusion(
                firestoreService: argThat(isNotNull, named: 'firestoreService'),
                slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                sha: 'testSha',
                stage: argThat(equals(CiStage.fusionTests), named: 'stage'),
                checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                conclusion: argThat(equals('success'), named: 'conclusion'),
              ),
            ).called(1);

            // Because tests completed, and completed successfully, the guard is
            // unlocked, allowing the PR to land.
            verify(
              mockGithubChecksUtil.updateCheckRun(
                any,
                argThat(equals(RepositorySlug('flutter', 'flutter'))),
                argThat(
                  predicate<CheckRun>((arg) {
                    expect(arg.name, 'GUARD TEST');
                    return true;
                  }),
                ),
                status: argThat(
                  equals(CheckRunStatus.completed),
                  named: 'status',
                ),
                conclusion: argThat(
                  equals(CheckRunConclusion.success),
                  named: 'conclusion',
                ),
                output: anyNamed('output'),
              ),
            ).called(1);
          });

          test(
            'writes failure comment if moving to next phase fails',
            () async {
              final githubService = config.githubService = MockGithubService();
              final githubClient = MockGitHub();
              final luci = MockLuciBuildService();
              final gitHubChecksService = MockGithubChecksService();

              when(githubService.github).thenReturn(githubClient);
              when(
                gitHubChecksService.githubChecksUtil,
              ).thenReturn(mockGithubChecksUtil);

              scheduler = Scheduler(
                cache: cache,
                config: config,
                datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
                buildStatusProvider: (_) => buildStatusService,
                getFilesChanged: getFilesChanged,
                githubChecksService: gitHubChecksService,
                ciYamlFetcher: ciYamlFetcher,
                luciBuildService: luci,
                fusionTester: fakeFusion,
                markCheckRunConclusion: callbacks.markCheckRunConclusion,
              );

              when(
                gitHubChecksService.findMatchingPullRequest(any, any, any),
              ).thenAnswer((inv) async {
                return pullRequest;
              });

              final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
                jsonDecode(checkRunString) as Map<String, dynamic>,
              );

              final mockGithubService = MockGithubService();
              config.githubService = mockGithubService;

              when(
                mockGithubService.createComment(
                  any,
                  issueNumber: anyNamed('issueNumber'),
                  body: anyNamed('body'),
                ),
              ).thenAnswer((_) async => null);

              await scheduler.proceedToCiTestingStage(
                checkRun: checkRunEvent.checkRun!,
                slug: RepositorySlug('flutter', 'flutter'),
                sha: 'abc1234',
                mergeQueueGuard: checkRunFor(name: 'merge queue guard'),
                logCrumb: 'test',
              );

              verify(
                mockGithubService.createComment(
                  RepositorySlug('flutter', 'flutter'),
                  issueNumber: argThat(
                    equals(pullRequest.number),
                    named: 'issueNumber',
                  ),
                  body: argThat(
                    contains('CI had a failure that stopped further tests'),
                    named: 'body',
                  ),
                ),
              );
            },
          );

          // Regression test for https://github.com/flutter/flutter/issues/164031.
          test('uses the built-from-source engine artifacts', () async {
            ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);

            final githubService = config.githubService = MockGithubService();
            final githubClient = MockGitHub();
            final luci = MockLuciBuildService();
            final gitHubChecksService = MockGithubChecksService();

            when(githubService.github).thenReturn(githubClient);
            when(
              gitHubChecksService.githubChecksUtil,
            ).thenReturn(mockGithubChecksUtil);

            scheduler = Scheduler(
              cache: cache,
              config: config,
              datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
              buildStatusProvider: (_) => buildStatusService,
              getFilesChanged: getFilesChanged,
              githubChecksService: gitHubChecksService,
              ciYamlFetcher: ciYamlFetcher,
              luciBuildService: luci,
              fusionTester: fakeFusion,
              markCheckRunConclusion: callbacks.markCheckRunConclusion,
            );

            when(
              gitHubChecksService.findMatchingPullRequest(any, any, any),
            ).thenAnswer((inv) async {
              return pullRequest;
            });

            final checkRuns = <CheckRun>[];
            when(
              mockGithubChecksUtil.createCheckRun(
                any,
                any,
                any,
                any,
                output: anyNamed('output'),
                conclusion: anyNamed('conclusion'),
              ),
            ).thenAnswer((inv) async {
              final slug = inv.positionalArguments[1] as RepositorySlug;
              final sha = inv.positionalArguments[2] as String;
              final name = inv.positionalArguments[3] as String?;
              checkRuns.add(
                createCheckRun(
                  id: 1,
                  owner: slug.owner,
                  repo: slug.name,
                  sha: sha,
                  name: name,
                ),
              );
              return checkRuns.last;
            });

            when(mockFirestoreService.documentResource()).thenAnswer((_) async {
              final resource = MockProjectsDatabasesDocumentsResource();
              when(
                resource.createDocument(
                  any,
                  any,
                  any,
                  documentId: argThat(anything, named: 'documentId'),
                  mask_fieldPaths: argThat(anything, named: 'mask_fieldPaths'),
                  $fields: argThat(anything, named: r'$fields'),
                ),
              ).thenAnswer((_) async {
                return Document();
              });
              return resource;
            });

            EngineArtifacts? engineArtifacts;
            when(
              luci.scheduleTryBuilds(
                targets: anyNamed('targets'),
                pullRequest: anyNamed('pullRequest'),
                engineArtifacts: anyNamed('engineArtifacts'),
              ),
            ).thenAnswer((Invocation i) async {
              engineArtifacts =
                  i.namedArguments[#engineArtifacts] as EngineArtifacts?;
              return [];
            });

            final checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
              jsonDecode(checkRunString) as Map<String, dynamic>,
            );

            await scheduler.proceedToCiTestingStage(
              checkRun: checkRunEvent.checkRun!,
              slug: RepositorySlug('flutter', 'flutter'),
              sha: 'abc1234',
              mergeQueueGuard: checkRunFor(name: 'merge queue guard'),
              logCrumb: 'test',
            );

            // Ensure that we used the HEAD SHA as as FLUTTER_PREBUILT_ENGINE_VERSION,
            // since the engine was built from source.
            //
            // See https://github.com/flutter/flutter/issues/164031.
            expect(
              engineArtifacts,
              EngineArtifacts.builtFromSource(
                commitSha: pullRequest.head!.sha!,
              ),
              reason:
                  'Should be set to HEAD (i.e. the current SHA), since the engine was built from source.',
            );
          });

          test(
            'does not fail the merge queue guard when a test check run fails',
            () async {
              final githubService = config.githubService = MockGithubService();
              final githubClient = MockGitHub();
              final luci = MockLuciBuildService();
              final gitHubChecksService = MockGithubChecksService();

              when(githubService.github).thenReturn(githubClient);
              when(
                gitHubChecksService.githubChecksUtil,
              ).thenReturn(mockGithubChecksUtil);

              scheduler = Scheduler(
                cache: cache,
                config: config,
                datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
                buildStatusProvider: (_) => buildStatusService,
                getFilesChanged: getFilesChanged,
                githubChecksService: gitHubChecksService,
                ciYamlFetcher: ciYamlFetcher,
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
                final stage = inv.namedArguments[#stage] as CiStage;
                return StagingConclusion(
                  result: switch (stage) {
                    CiStage.fusionEngineBuild =>
                      StagingConclusionResult.missing,
                    CiStage.fusionTests => StagingConclusionResult.ok,
                  },
                  remaining: 0,
                  checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                  failed: switch (stage) {
                    CiStage.fusionEngineBuild => 0,
                    CiStage.fusionTests => 1,
                  },
                  summary: 'Field missing or OK',
                  details: 'Some details',
                );
              });

              expect(
                await scheduler.processCheckRunCompletion(
                  cocoon_checks.CheckRunEvent.fromJson(
                    json.decode(
                          checkRunEventFor(test: 'Bar bar', sha: 'testSha'),
                        )
                        as Map<String, Object?>,
                  ),
                ),
                isTrue,
              );

              // The first invocation looks in the fusionEngineBuild stage, which
              // returns "missing" result.
              verify(
                callbacks.markCheckRunConclusion(
                  firestoreService: argThat(
                    isNotNull,
                    named: 'firestoreService',
                  ),
                  slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                  sha: 'testSha',
                  stage: argThat(
                    equals(CiStage.fusionEngineBuild),
                    named: 'stage',
                  ),
                  checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                  conclusion: argThat(equals('success'), named: 'conclusion'),
                ),
              ).called(1);

              // The second invocation looks in the fusionTests stage, which returns
              // "ok" result.
              verify(
                callbacks.markCheckRunConclusion(
                  firestoreService: argThat(
                    isNotNull,
                    named: 'firestoreService',
                  ),
                  slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                  sha: 'testSha',
                  stage: argThat(equals(CiStage.fusionTests), named: 'stage'),
                  checkRun: argThat(equals('Bar bar'), named: 'checkRun'),
                  conclusion: argThat(equals('success'), named: 'conclusion'),
                ),
              ).called(1);

              // The test stage completed, but with failures. The merge queue
              // guard should stay open to prevent the pull request from landing.
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
            },
          );

          test(
            'schedules tests after engine stage - with pr caching',
            () async {
              final githubService = config.githubService = MockGithubService();
              final githubClient = MockGitHub();
              when(githubService.github).thenReturn(githubClient);
              when(
                githubService.searchIssuesAndPRs(
                  any,
                  any,
                  sort: anyNamed('sort'),
                  pages: anyNamed('pages'),
                ),
              ).thenAnswer((_) async => [generateIssue(42)]);

              final pullRequest = generatePullRequest();
              when(
                githubService.getPullRequest(any, any),
              ).thenAnswer((_) async => pullRequest);
              getFilesChanged.cannedFiles = ['abc/def'];
              when(
                mockGithubChecksUtil.listCheckSuitesForRef(
                  any,
                  any,
                  ref: anyNamed('ref'),
                ),
              ).thenAnswer(
                (_) async => [
                  // From check_run.check_suite.id in [checkRunString].
                  generateCheckSuite(668083231),
                ],
              );

              when(callbacks.findPullRequestFor(any, any, any)).thenAnswer((
                inv,
              ) async {
                return pullRequest;
              });

              ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);
              final luci = MockLuciBuildService();
              when(
                luci.scheduleTryBuilds(
                  targets: anyNamed('targets'),
                  pullRequest: anyNamed('pullRequest'),
                  engineArtifacts: anyNamed('engineArtifacts'),
                ),
              ).thenAnswer((inv) async {
                return [];
              });

              final gitHubChecksService = MockGithubChecksService();
              when(
                gitHubChecksService.githubChecksUtil,
              ).thenReturn(mockGithubChecksUtil);

              // Cocoon creates a Firestore document to track the tasks in the
              // test stage.
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
                config: config,
                datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
                buildStatusProvider: (_) => buildStatusService,
                githubChecksService: gitHubChecksService,
                getFilesChanged: getFilesChanged,
                ciYamlFetcher: ciYamlFetcher,
                luciBuildService: luci,
                fusionTester: fakeFusion,
                markCheckRunConclusion: callbacks.markCheckRunConclusion,
                findPullRequestFor: callbacks.findPullRequestFor,
                initializeCiStagingDocument: callbacks.initializeDocument,
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
                  result: StagingConclusionResult.ok,
                  remaining: 0,
                  checkRunGuard: checkRunFor(name: 'GUARD TEST'),
                  failed: 0,
                  summary: 'OK',
                  details: 'Some details',
                );
              });

              expect(
                await scheduler.processCheckRunCompletion(
                  cocoon_checks.CheckRunEvent.fromJson(
                    json.decode(checkRunEventFor(test: 'Bar bar'))
                        as Map<String, Object?>,
                  ),
                ),
                isTrue,
              );

              verify(
                callbacks.findPullRequestFor(
                  mockFirestoreService,
                  1,
                  'Bar bar',
                ),
              ).called(1);
              verifyNever(
                gitHubChecksService.findMatchingPullRequest(any, any, any),
              );

              verify(
                callbacks.markCheckRunConclusion(
                  firestoreService: argThat(
                    isNotNull,
                    named: 'firestoreService',
                  ),
                  slug: argThat(equals(Config.flutterSlug), named: 'slug'),
                  sha: '1234',
                  stage: argThat(
                    equals(CiStage.fusionEngineBuild),
                    named: 'stage',
                  ),
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

              final result = verify(
                luci.scheduleTryBuilds(
                  targets: captureAnyNamed('targets'),
                  pullRequest: captureAnyNamed('pullRequest'),
                  engineArtifacts: anyNamed('engineArtifacts'),
                ),
              );
              expect(result.callCount, 1);
              final captured = result.captured;
              expect(captured[0], hasLength(2));
              // see the blend of fusionCiYaml and singleCiYaml
              expect(captured[0][0].getTestName, 'A');
              expect(captured[0][1].getTestName, 'Z');
              expect(captured[1], pullRequest);
            },
          );
          // end of group
        });
      });
    });

    group('presubmit', () {
      test('gets only enabled .ci.yaml builds', () async {
        ciYamlFetcher.setCiYamlFrom(r'''
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
          ''');
        final presubmitTargets = await scheduler.getPresubmitTargets(
          pullRequest,
        );
        expect(
          presubmitTargets.map((Target target) => target.value.name).toList(),
          containsAll(<String>['Linux A', 'Linux C']),
        );
      });

      group('treats postsubmit as presubmit if a label is present', () {
        final runAllTests = IssueLabel(name: 'test: all');
        setUp(() async {
          ciYamlFetcher.setCiYamlFrom(r'''
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
          ''');
        });

        test('with a specific label in the flutter/engine repo', () async {
          final enginePr = generatePullRequest(
            branch: Config.defaultBranch(Config.flutterSlug),
            labels: <IssueLabel>[runAllTests],
            repo: Config.flutterSlug.name,
          );
          final presubmitTargets = await scheduler.getPresubmitTargets(
            enginePr,
          );
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
          final presubmitTargets = await scheduler.getPresubmitTargets(
            frameworkPr,
          );
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
            branch: Config.defaultBranch(Config.flutterSlug),
            labels: <IssueLabel>[],
            repo: Config.flutterSlug.name,
          );

          // Assume a file that is not runIf'd was changed.
          getFilesChanged.cannedFiles = ['README.md'];
          final presubmitTargets = await scheduler.getPresubmitTargets(
            enginePr,
          );
          expect(
            presubmitTargets.map((Target target) => target.value.name).toList(),
            <String>[
              // Always runs.
              'Linux Presubmit',
            ],
          );
        });
      });

      test('checks for release branches', () async {
        const branch = 'flutter-1.24-candidate.1';
        ciYamlFetcher.setCiYamlFrom(r'''
enabled_branches:
  - master
targets:
  - name: Linux A
    presubmit: true
    scheduler: luci
          ''');
        expect(
          scheduler.getPresubmitTargets(generatePullRequest(branch: branch)),
          throwsA(
            predicate(
              (Exception e) => e.toString().contains('$branch is not enabled'),
            ),
          ),
        );
      });

      test('checks for release branch regex', () async {
        const branch = 'flutter-1.24-candidate.1';
        ciYamlFetcher.setCiYamlFrom('''
enabled_branches:
  - main
  - master
  - flutter-\\d+.\\d+-candidate.\\d+
targets:
  - name: Linux A
    scheduler: luci
          ''');
        final targets = await scheduler.getPresubmitTargets(
          generatePullRequest(branch: branch),
        );
        expect(targets.single.value.name, 'Linux A');
      });

      test('triggers expected presubmit build checks', () async {
        getFilesChanged.cannedFiles = ['README.md'];
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(
            mockGithubChecksUtil.createCheckRun(
              any,
              any,
              any,
              captureAny,
              output: captureAnyNamed('output'),
            ),
          ).captured,
          <Object?>[
            Config.kMergeQueueLockName,
            const CheckRunOutput(
              title: Config.kMergeQueueLockName,
              summary: Scheduler.kMergeQueueLockDescription,
            ),
            Config.kCiYamlCheckName,
            const CheckRunOutput(
              title: Config.kCiYamlCheckName,
              summary:
                  'If this check is stuck pending, push an empty commit to retrigger the checks',
            ),
            'Linux A',
            null,
            // Linux runIf is not run as this is for tip of tree and the files weren't affected
          ],
        );
      });

      test('Do not schedule other targets on revert request.', () async {
        final releasePullRequest = generatePullRequest(
          labels: [IssueLabel(name: 'revert of')],
        );

        releasePullRequest.user = User(login: 'auto-submit[bot]');

        await scheduler.triggerPresubmitTargets(
          pullRequest: releasePullRequest,
        );
        expect(
          verify(
            mockGithubChecksUtil.createCheckRun(
              any,
              any,
              any,
              captureAny,
              output: captureAnyNamed('output'),
            ),
          ).captured,
          <Object?>[
            Config.kMergeQueueLockName,
            const CheckRunOutput(
              title: Config.kMergeQueueLockName,
              summary: Scheduler.kMergeQueueLockDescription,
            ),
            Config.kCiYamlCheckName,
            // No other targets should be created.
            const CheckRunOutput(
              title: Config.kCiYamlCheckName,
              summary:
                  'If this check is stuck pending, push an empty commit to retrigger the checks',
            ),
          ],
        );
      });

      test('Unlocks merge group on revert request.', () async {
        fakeFusion.isFusion = (_, _) => true;

        final releasePullRequest = generatePullRequest(
          labels: [IssueLabel(name: 'revert of')],
        );

        releasePullRequest.user = User(login: 'auto-submit[bot]');

        await scheduler.triggerPresubmitTargets(
          pullRequest: releasePullRequest,
        );
        expect(
          verify(
            mockGithubChecksUtil.updateCheckRun(
              any,
              any,
              any,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              output: captureAnyNamed('output'),
            ),
          ).captured,
          <Object?>[
            CheckRunStatus.completed,
            CheckRunConclusion.success,
            null,
            CheckRunStatus.completed,
            CheckRunConclusion.success,
            null,
          ],
        );
      });

      test(
        'filters out presubmit targets that do not exist in main and do not filter targets not in main',
        () async {
          ciYamlFetcher.setCiYamlFrom(r'''
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
''');
          scheduler = Scheduler(
            cache: cache,
            config: config,
            datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
            buildStatusProvider: (_) => buildStatusService,
            githubChecksService: GithubChecksService(
              config,
              githubChecksUtil: mockGithubChecksUtil,
            ),
            getFilesChanged: getFilesChanged,
            ciYamlFetcher: ciYamlFetcher,
            luciBuildService: FakeLuciBuildService(
              config: config,
              githubChecksUtil: mockGithubChecksUtil,
              gerritService: FakeGerritService(
                branchesValue: <String>['master', 'main'],
              ),
            ),
            fusionTester: fakeFusion,
          );
          final pr = generatePullRequest(
            repo: Config.flutterSlug.name,
            branch: 'flutter-3.10-candidate.1',
          );
          final targets = await scheduler.getPresubmitTargets(pr);
          expect(
            targets.map((Target target) => target.value.name).toList(),
            containsAll(<String>['Linux A', 'Linux B']),
          );
        },
      );

      test(
        'triggers all presubmit build checks when diff cannot be found',
        () async {
          final mockGithubService = MockGithubService();
          getFilesChanged.cannedFiles = null;
          buildStatusService = FakeBuildStatusService(
            commitTasksStatuses: [
              CommitTasksStatus(generateFirestoreCommit(1), []),
            ],
          );
          scheduler = Scheduler(
            cache: cache,
            config: FakeConfig(
              // tabledataResource: tabledataResource,
              dbValue: db,
              githubService: mockGithubService,
              githubClient: MockGitHub(),
              firestoreService: mockFirestoreService,
            ),
            buildStatusProvider: (_) => buildStatusService,
            datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
            githubChecksService: GithubChecksService(
              config,
              githubChecksUtil: mockGithubChecksUtil,
            ),
            getFilesChanged: getFilesChanged,
            ciYamlFetcher: ciYamlFetcher,
            luciBuildService: FakeLuciBuildService(
              config: config,
              githubChecksUtil: mockGithubChecksUtil,
              gerritService: FakeGerritService(
                branchesValue: <String>['master'],
              ),
            ),
            fusionTester: fakeFusion,
          );
          await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
          expect(
            verify(
              mockGithubChecksUtil.createCheckRun(
                any,
                any,
                any,
                captureAny,
                output: captureAnyNamed('output'),
              ),
            ).captured,
            <Object?>[
              Config.kMergeQueueLockName,
              const CheckRunOutput(
                title: Config.kMergeQueueLockName,
                summary: Scheduler.kMergeQueueLockDescription,
              ),
              Config.kCiYamlCheckName,
              const CheckRunOutput(
                title: Config.kCiYamlCheckName,
                summary:
                    'If this check is stuck pending, push an empty commit to retrigger the checks',
              ),
              'Linux A',
              null,
              // runIf requires a diff in dev, so an error will cause it to be triggered
              'Linux runIf',
              null,
            ],
          );
        },
      );

      test(
        'triggers all presubmit targets on release branch pull request',
        () async {
          final releasePullRequest = generatePullRequest(
            branch: 'flutter-1.24-candidate.1',
          );
          await scheduler.triggerPresubmitTargets(
            pullRequest: releasePullRequest,
          );
          expect(
            verify(
              mockGithubChecksUtil.createCheckRun(
                any,
                any,
                any,
                captureAny,
                output: captureAnyNamed('output'),
              ),
            ).captured,
            <Object?>[
              Config.kMergeQueueLockName,
              const CheckRunOutput(
                title: Config.kMergeQueueLockName,
                summary: Scheduler.kMergeQueueLockDescription,
              ),
              Config.kCiYamlCheckName,
              const CheckRunOutput(
                title: Config.kCiYamlCheckName,
                summary:
                    'If this check is stuck pending, push an empty commit to retrigger the checks',
              ),
              'Linux A',
              null,
              'Linux runIf',
              null,
            ],
          );
        },
      );

      test('ci.yaml validation passes with default config', () async {
        when(
          mockGithubChecksUtil.getCheckRun(any, any, any),
        ).thenAnswer((Invocation invocation) async => createCheckRun(id: 0));
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

      test('ci.yaml validation failure', () async {
        ciYamlFetcher.failCiYamlValidation = true;

        final capturedUpdates =
            <(String, CheckRunStatus, CheckRunConclusion)>[];

        when(
          mockGithubChecksUtil.updateCheckRun(
            any,
            any,
            any,
            status: anyNamed('status'),
            conclusion: anyNamed('conclusion'),
            output: anyNamed('output'),
          ),
        ).thenAnswer((inv) async {
          final checkRun = inv.positionalArguments[2] as CheckRun;
          capturedUpdates.add((
            checkRun.name!,
            inv.namedArguments[#status],
            inv.namedArguments[#conclusion],
          ));
        });

        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);

        expect(capturedUpdates, <(String, CheckRunStatus, CheckRunConclusion)>[
          (
            'ci.yaml validation',
            CheckRunStatus.completed,
            CheckRunConclusion.failure,
          ),
          (
            'Merge Queue Guard',
            CheckRunStatus.completed,
            CheckRunConclusion.success,
          ),
        ]);
      });

      test('ci.yaml validation fails on not enabled branch', () async {
        final pullRequest = generatePullRequest(branch: 'not-valid');
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
            CheckRunConclusion.success,
          ],
        );
      });

      test('triggers only specificed targets', () async {
        final presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final presubmitTriggerTargets = scheduler.filterTargets(
          presubmitTargets,
          <String>['Linux 1'],
        );
        expect(presubmitTriggerTargets.length, 1);
      });

      test(
        'triggers all presubmit targets when trigger list is null',
        () async {
          final presubmitTargets = <Target>[
            generateTarget(1),
            generateTarget(2),
          ];
          final presubmitTriggerTargets = scheduler.filterTargets(
            presubmitTargets,
            null,
          );
          expect(presubmitTriggerTargets.length, 2);
        },
      );

      test(
        'triggers all presubmit targets when trigger list is empty',
        () async {
          final presubmitTargets = <Target>[
            generateTarget(1),
            generateTarget(2),
          ];
          final presubmitTriggerTargets = scheduler.filterTargets(
            presubmitTargets,
            <String>[],
          );
          expect(presubmitTriggerTargets.length, 2);
        },
      );

      test(
        'triggers only targets that are contained in the trigger list',
        () async {
          final presubmitTargets = <Target>[
            generateTarget(1),
            generateTarget(2),
          ];
          final presubmitTriggerTargets = scheduler.filterTargets(
            presubmitTargets,
            <String>['Linux 1', 'Linux 3'],
          );
          expect(presubmitTriggerTargets.length, 1);
          expect(presubmitTargets[0].value.name, 'Linux 1');
        },
      );

      test('in fusion gathers creates engine builds', () async {
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);
        final luci = MockLuciBuildService();
        when(
          luci.scheduleTryBuilds(
            targets: anyNamed('targets'),
            pullRequest: anyNamed('pullRequest'),
            engineArtifacts: anyNamed('engineArtifacts'),
          ),
        ).thenAnswer((inv) async {
          return [];
        });
        final mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
          ),
        ).thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2] as String;
          final name = inv.positionalArguments[3] as String?;
          checkRuns.add(
            createCheckRun(
              id: 1,
              owner: slug.owner,
              repo: slug.name,
              sha: sha,
              name: name,
            ),
          );
          return checkRuns.last;
        });

        getFilesChanged.cannedFiles = ['abc/def', 'engine/src/flutter/FILE'];

        fakeFusion.isFusion = (_, _) => true;

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
            maxFilesChangedForSkippingEnginePhaseValue: 0,
          ),
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
          luciBuildService: luci,
          fusionTester: fakeFusion,
          initializeCiStagingDocument: callbacks.initializeDocument,
        );
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        final results =
            verify(
              mockGithubChecksUtil.createCheckRun(
                any,
                any,
                any,
                captureAny,
                output: captureAnyNamed('output'),
              ),
            ).captured;
        stdout.writeAll(results);

        final result = verify(
          luci.scheduleTryBuilds(
            targets: captureAnyNamed('targets'),
            pullRequest: anyNamed('pullRequest'),
            engineArtifacts: anyNamed('engineArtifacts'),
          ),
        );
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
            conclusion: argThat(
              equals(CheckRunConclusion.success),
              named: 'conclusion',
            ),
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
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionDualCiYaml);
        final luci = MockLuciBuildService();
        when(
          luci.getAvailableBuilderSet(
            project: anyNamed('project'),
            bucket: anyNamed('bucket'),
          ),
        ).thenAnswer((inv) async {
          return {'Mac engine_build', 'Linux engine_build'};
        });
        when(
          luci.scheduleTryBuilds(
            targets: anyNamed('targets'),
            pullRequest: anyNamed('pullRequest'),
            engineArtifacts: anyNamed('engineArtifacts'),
          ),
        ).thenAnswer((inv) async {
          return [];
        });
        final mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
          ),
        ).thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2] as String;
          final name = inv.positionalArguments[3] as String?;
          checkRuns.add(
            createCheckRun(
              id: 1,
              owner: slug.owner,
              repo: slug.name,
              sha: sha,
              name: name,
            ),
          );
          return checkRuns.last;
        });
        getFilesChanged.cannedFiles = ['abc/def'];

        fakeFusion.isFusion = (_, _) => true;

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
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
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
              )
              as Map<String, Object?>,
        );

        await scheduler.triggerMergeGroupTargets(
          mergeGroupEvent: mergeGroupEvent,
        );
        verify(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: argThat(
              equals('c9affbbb12aa40cb3afbe94b9ea6b119a256bebf'),
              named: 'sha',
            ),
            stage: anyNamed('stage'),
            tasks: argThat(
              equals(['Linux engine_build', 'Mac engine_build']),
              named: 'tasks',
            ),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).called(1);
        verify(
          luci.getAvailableBuilderSet(
            project: argThat(equals('flutter'), named: 'project'),
            bucket: argThat(equals('prod'), named: 'bucket'),
          ),
        ).called(1);

        verify(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            captureAny,
            output: captureAnyNamed('output'),
          ),
        ).called(1);
        final result = verify(
          luci.scheduleMergeGroupBuilds(
            targets: captureAnyNamed('targets'),
            commit: anyNamed('commit'),
          ),
        );
        expect(result.callCount, 1);
        expect(
          result.captured.cast<List<Target>>()[0].map(
            (target) => target.value.name,
          ),
          ['Linux engine_build', 'Mac engine_build'],
        );

        expect(checkRuns, hasLength(1));
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
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionDualCiYaml);
        final luci = MockLuciBuildService();
        when(
          luci.getAvailableBuilderSet(
            project: anyNamed('project'),
            bucket: anyNamed('bucket'),
          ),
        ).thenAnswer((inv) async {
          return {'Mac engine_build'};
        });
        when(
          luci.scheduleTryBuilds(
            targets: anyNamed('targets'),
            pullRequest: anyNamed('pullRequest'),
            engineArtifacts: anyNamed('engineArtifacts'),
          ),
        ).thenAnswer((inv) async {
          return [];
        });
        final mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
          ),
        ).thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2] as String;
          final name = inv.positionalArguments[3] as String?;
          checkRuns.add(
            createCheckRun(
              id: 1,
              owner: slug.owner,
              repo: slug.name,
              sha: sha,
              name: name,
            ),
          );
          return checkRuns.last;
        });
        getFilesChanged.cannedFiles = ['abc/def'];

        fakeFusion.isFusion = (_, _) => true;
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
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
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
              )
              as Map<String, Object?>,
        );

        await scheduler.triggerMergeGroupTargets(
          mergeGroupEvent: mergeGroupEvent,
        );
        verify(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: argThat(
              equals('c9affbbb12aa40cb3afbe94b9ea6b119a256bebf'),
              named: 'sha',
            ),
            stage: anyNamed('stage'),
            tasks: argThat(equals(['Mac engine_build']), named: 'tasks'),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).called(1);
        verify(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            captureAny,
            output: captureAnyNamed('output'),
          ),
        ).called(1);
        final result = verify(
          luci.scheduleMergeGroupBuilds(
            targets: captureAnyNamed('targets'),
            commit: anyNamed('commit'),
          ),
        );
        expect(result.callCount, 1);
        expect(
          result.captured.cast<List<Target>>()[0].map(
            (target) => target.value.name,
          ),
          ['Mac engine_build'],
        );

        expect(checkRuns, hasLength(1));
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

      test('fails the merge queue guard if fails to schedule checks', () async {
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionDualCiYaml);
        final luci = MockLuciBuildService();
        when(
          luci.getAvailableBuilderSet(
            project: anyNamed('project'),
            bucket: anyNamed('bucket'),
          ),
        ).thenAnswer((inv) async {
          return {'Mac engine_build', 'Linux engine_build'};
        });
        when(
          luci.scheduleMergeGroupBuilds(
            targets: anyNamed('targets'),
            commit: anyNamed('commit'),
          ),
        ).thenThrow('Emulating failure');

        final mockGithubService = MockGithubService();
        final checkRuns = <CheckRun>[];
        when(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            any,
            output: anyNamed('output'),
          ),
        ).thenAnswer((inv) async {
          final slug = inv.positionalArguments[1] as RepositorySlug;
          final sha = inv.positionalArguments[2] as String;
          final name = inv.positionalArguments[3] as String?;
          checkRuns.add(
            createCheckRun(
              id: 1,
              owner: slug.owner,
              repo: slug.name,
              sha: sha,
              name: name,
            ),
          );
          return checkRuns.last;
        });
        getFilesChanged.cannedFiles = ['abc/def'];

        fakeFusion.isFusion = (_, _) => true;

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
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
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
              )
              as Map<String, Object?>,
        );

        await scheduler.triggerMergeGroupTargets(
          mergeGroupEvent: mergeGroupEvent,
        );
        verify(
          callbacks.initializeDocument(
            firestoreService: anyNamed('firestoreService'),
            slug: anyNamed('slug'),
            sha: argThat(
              equals('c9affbbb12aa40cb3afbe94b9ea6b119a256bebf'),
              named: 'sha',
            ),
            stage: anyNamed('stage'),
            tasks: argThat(
              equals(['Linux engine_build', 'Mac engine_build']),
              named: 'tasks',
            ),
            checkRunGuard: anyNamed('checkRunGuard'),
          ),
        ).called(1);
        verify(
          luci.getAvailableBuilderSet(
            project: argThat(equals('flutter'), named: 'project'),
            bucket: argThat(equals('prod'), named: 'bucket'),
          ),
        ).called(1);

        verify(
          mockGithubChecksUtil.createCheckRun(
            any,
            any,
            any,
            captureAny,
            output: captureAnyNamed('output'),
          ),
        ).called(1);
        final result = verify(
          luci.scheduleMergeGroupBuilds(
            targets: captureAnyNamed('targets'),
            commit: anyNamed('commit'),
          ),
        );
        expect(result.callCount, 1);
        expect(
          result.captured.cast<List<Target>>()[0].map(
            (target) => target.value.name,
          ),
          ['Linux engine_build', 'Mac engine_build'],
        );

        expect(checkRuns, hasLength(1));

        // Expect the merge queue guard to be completed with failure.
        final mergeQueueGuard = checkRuns.single;
        expect(mergeQueueGuard.name, 'Merge Queue Guard');
        expect(
          verify(
            await mockGithubChecksUtil.updateCheckRun(
              any,
              Config.flutterSlug,
              mergeQueueGuard,
              status: captureAnyNamed('status'),
              conclusion: captureAnyNamed('conclusion'),
              output: anyNamed('output'),
            ),
          ).captured,
          [CheckRunStatus.completed, CheckRunConclusion.failure],
        );
      });
    });

    group('framework-only PR optimization', () {
      // TODO(matanlurey): Inject this.
      const allowListedUser = 'matanlurey';

      late MockGithubService mockGithubService;
      late _CapturingFakeLuciBuildService fakeLuciBuildService;

      setUp(() {
        mockGithubService = MockGithubService();
        fakeLuciBuildService = _CapturingFakeLuciBuildService();
        ciYamlFetcher.setCiYamlFrom(singleCiYaml, engine: fusionCiYaml);

        // ignore: discarded_futures
        when(mockFirestoreService.documentResource()).thenAnswer((_) async {
          final resource = MockProjectsDatabasesDocumentsResource();
          when(
            resource.createDocument(
              any,
              any,
              any,
              documentId: argThat(anything, named: 'documentId'),
              mask_fieldPaths: argThat(anything, named: 'mask_fieldPaths'),
              $fields: argThat(anything, named: r'$fields'),
            ),
          ).thenAnswer((_) async {
            return Document();
          });
          return resource;
        });

        scheduler = Scheduler(
          cache: cache,
          config: FakeConfig(
            dbValue: db,
            githubService: mockGithubService,
            githubClient: MockGitHub(),
            firestoreService: mockFirestoreService,
            maxFilesChangedForSkippingEnginePhaseValue: 29,
          ),
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(
            config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
          getFilesChanged: getFilesChanged,
          ciYamlFetcher: ciYamlFetcher,
          luciBuildService: fakeLuciBuildService,
          fusionTester: fakeFusion,
        );
      });

      test(
        'does not run if running outside of Fusion (legacy releases)',
        () async {
          fakeFusion.isFusion = (_, _) => false;
          getFilesChanged.cannedFiles = ['packages/flutter/lib/material.dart'];
          final pullRequest = generatePullRequest(authorLogin: allowListedUser);

          await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);

          // Verify we don't try writing anything to Firestore (Fusion workflow).
          verifyZeroInteractions(mockFirestoreService);
          expect(
            fakeLuciBuildService.scheduledTryBuilds.map((t) => t.value.name),
            ['Linux A'],
            reason: 'Should ignore the Fusion configuration and engine phases',
          );
        },
      );

      test('still runs engine builds (DEPS)', () async {
        fakeFusion.isFusion = (_, _) => true;
        getFilesChanged.cannedFiles = [
          'DEPS',
          'packages/flutter/lib/material.dart',
        ];
        final pullRequest = generatePullRequest(authorLogin: 'joe-flutter');

        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          fakeLuciBuildService.scheduledTryBuilds.map((t) => t.value.name),
          ['Linux engine_build'],
          reason: 'Should still run engine phase',
        );
      });

      test('still runs engine builds (engine/**)', () async {
        fakeFusion.isFusion = (_, _) => true;
        getFilesChanged.cannedFiles = [
          'engine/src/flutter/BUILD.gn',
          'packages/flutter/lib/material.dart',
        ];
        final pullRequest = generatePullRequest(authorLogin: 'joe-flutter');

        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          fakeLuciBuildService.scheduledTryBuilds.map((t) => t.value.name),
          ['Linux engine_build'],
          reason: 'Should still run engine phase',
        );
      });

      test(
        'still runs engine builds (>=X files in changedFilesCount)',
        () async {
          fakeFusion.isFusion = (_, _) => true;
          getFilesChanged.cannedFiles = [
            // Irrelevant, never called.
          ];
          config.maxFilesChangedForSkippingEnginePhaseValue = 1000;

          final pullRequest = generatePullRequest(
            authorLogin: 'joe-flutter',
            changedFilesCount: config.maxFilesChangedForSkippingEnginePhase,
          );

          await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
          expect(
            fakeLuciBuildService.scheduledTryBuilds.map((t) => t.value.name),
            ['Linux engine_build'],
            reason: 'Should still run engine phase',
          );
        },
      );

      test('skips engine builds', () async {
        fakeFusion.isFusion = (_, _) => true;
        getFilesChanged.cannedFiles = ['packages/flutter/lib/material.dart'];
        final pullRequest = generatePullRequest(authorLogin: allowListedUser);

        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          fakeLuciBuildService.engineArtifacts,
          EngineArtifacts.usingExistingEngine(
            commitSha: pullRequest.base!.sha!,
          ),
          reason: 'Should use the base ref for the engine artifacts',
        );
        expect(
          fakeLuciBuildService.scheduledTryBuilds.map((t) => t.value.name),
          ['Linux A'],
          reason: 'Should skip Linux engine_build',
        );
        // TODO(matanlurey): Refactoring should allow us to verify the first stage
        // (the engine build) phase was written to Firestore, but as an emtpy tasks
        // list.
      });

      // Regression test for https://github.com/flutter/flutter/issues/162403.
      test('engine builds still run for flutter-3.29-candidate.0', () async {
        fakeFusion.isFusion = (_, _) => true;
        getFilesChanged.cannedFiles = ['packages/flutter/lib/material.dart'];
        final pullRequest = generatePullRequest(
          branch: 'flutter-3.29-candidate.0',
        );

        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          fakeLuciBuildService.engineArtifacts,
          EngineArtifacts.usingExistingEngine(
            commitSha: pullRequest.head!.sha!,
          ),
          reason: 'Release candidates use an "existing" dart-internal build',
        );
        expect(
          fakeLuciBuildService.scheduledTryBuilds.map((t) => t.value.name),
          ['Linux engine_build'],
          reason: 'Should run the engine_build',
        );
      });
    });
  });
}

final class _CapturingFakeLuciBuildService extends Fake
    implements LuciBuildService {
  List<Target> scheduledTryBuilds = [];
  EngineArtifacts? engineArtifacts;

  @override
  Future<List<Target>> scheduleTryBuilds({
    required List<Target> targets,
    required PullRequest pullRequest,
    CheckSuiteEvent? checkSuiteEvent,
    EngineArtifacts? engineArtifacts,
  }) async {
    scheduledTryBuilds = targets;
    this.engineArtifacts = engineArtifacts;
    return targets;
  }

  @override
  Future<void> cancelBuilds({
    required PullRequest pullRequest,
    required String reason,
  }) async {}
}

CheckRun createCheckRun({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flutter',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final checkRunJson = checkRunFor(
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

String checkRunFor({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flutter',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final externalId = id * 2;
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
  String repo = 'flutter',
}) => '''{
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
