// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../model/github/checks_test_data.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_buildbucket.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_luci_build_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

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
      - dev/**
  - name: Google Internal Roll
    postsubmit: true
    presubmit: false
    scheduler: google_internal
''';

void main() {
  late CacheService cache;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late FakeBuildStatusService buildStatusService;
  late MockClient httpClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late Scheduler scheduler;

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
      scheduler = Scheduler(
        cache: cache,
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
        buildStatusProvider: (_) => buildStatusService,
        githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
        httpClientProvider: () => httpClient,
        luciBuildService: FakeLuciBuildService(
          config: config,
          githubChecksUtil: mockGithubChecksUtil,
          gerritService: FakeGerritService(
            branchesValue: <String>['master', 'main'],
          ),
        ),
      );

      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2},
        });
      });
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
        config.supportedBranchesValue = <String>['master'];

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
        // The 2 new commits are scheduled 3 tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 3);
        // Check commits were added, but 3 was not
        expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
        expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
      });

      test('skips commits for which task transaction fails', () async {
        config.supportedBranchesValue = <String>['master'];

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
        // The 2 new commits are scheduled 3 tasks, existing commit has none.
        expect(db.values.values.whereType<Task>().length, 2 * 3);
        // Check commits were added, but 3 was not
        expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
        expect(db.values.values.whereType<Commit>().map<String>(toSha), isNot(contains('3')));
      });

      test('schedules cocoon based targets', () async {
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
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luciBuildService,
        );

        await scheduler.addCommits(createCommitList(<String>['1'], repo: 'engine', branch: 'main'));
        final List<dynamic> captured = verify(
          luciBuildService.schedulePostsubmitBuilds(
            commit: anyNamed('commit'),
            toBeScheduled: captureAnyNamed('toBeScheduled'),
          ),
        ).captured;
        final List<dynamic> toBeScheduled = captured.first as List<dynamic>;
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
        final MockBuildBucketClient mockBuildBucketClient = MockBuildBucketClient();
        final FakeLuciBuildService luciBuildService = FakeLuciBuildService(
          config: config,
          buildbucket: mockBuildBucketClient,
          gerritService: FakeGerritService(),
          githubChecksUtil: mockGithubChecksUtil,
          pubsub: pubsub,
        );
        when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
            .thenAnswer((_) async => generateCheckRun(1, name: 'Linux A'));
        when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
          return const ListBuildersResponse(
            builders: [
              BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'Linux A')),
              BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'Linux runIf')),
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
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: luciBuildService,
        );

        await scheduler.addCommits(createCommitList(<String>['1'], repo: 'engine', branch: 'main'));
        expect(pubsub.messages.length, 2);
      });
    });

    group('add pull request', () {
      test('creates expected commit', () async {
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
      });

      test('schedules tasks against merged PRs', () async {
        final PullRequest mergedPr = generatePullRequest();
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 3);
      });

      test('guarantees scheduling of tasks against merged release branch PR', () async {
        final PullRequest mergedPr = generatePullRequest(branch: 'flutter-3.2-candidate.5');
        await scheduler.addPullRequest(mergedPr);

        expect(db.values.values.whereType<Commit>().length, 1);
        expect(db.values.values.whereType<Task>().length, 3);
        // Ensure all tasks have been marked in progress
        expect(db.values.values.whereType<Task>().where((Task task) => task.status == Task.statusNew), isEmpty);
      });

      test('guarantees scheduling of tasks against merged engine PR', () async {
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
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            gerritService: FakeGerritService(
              branchesValue: <String>['master', 'main'],
            ),
          ),
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
        );
        scheduler = Scheduler(
          cache: cache,
          config: config,
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
          ),
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
          final ScheduleBuildRequest scheduleBuildRequest = realInvocation.positionalArguments[0];
          // Ensure this is an attempt to schedule a presubmit build by
          // verifying that bucket == 'try'.
          expect(scheduleBuildRequest.builderId.bucket, equals('try'));
          return const Build(builderId: BuilderId(), id: '');
        });

        scheduler = Scheduler(
          cache: cache,
          config: config,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildbucket: mockBuildbucket,
          ),
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
        config = FakeConfig(dbValue: db, postsubmitSupportedReposValue: {RepositorySlug('abc', 'cocoon')});
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
          final ScheduleBuildRequest scheduleBuildRequest = realInvocation.positionalArguments[0];
          // Ensure this is an attempt to schedule a postsubmit build by
          // verifying that bucket == 'prod'.
          expect(scheduleBuildRequest.builderId.bucket, equals('prod'));
          return const Build(builderId: BuilderId(), id: '');
        });

        scheduler = Scheduler(
          cache: cache,
          config: config,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildbucket: mockBuildbucket,
            gerritService: FakeGerritService(
              branchesValue: <String>['master', 'main'],
            ),
          ),
        );
        final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(
          jsonDecode(checkRunString) as Map<String, dynamic>,
        );
        expect(await scheduler.processCheckRun(checkRunEvent), true);
        verify(mockBuildbucket.scheduleBuild(any, buildBucketUri: anyNamed('buildBucketUri'))).called(1);
        verify(mockGithubChecksUtil.createCheckRun(any, any, any, any)).called(1);
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
    - master
  targets:
    - name: Linux Presubmit
      presubmit: true
      scheduler: luci
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

        test('with a specific label', () async {
          final enginePr = generatePullRequest(
            labels: <IssueLabel>[runAllTests],
          );
          final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(enginePr);
          expect(
            presubmitTargets.map((Target target) => target.value.name).toList(),
            <String>['Linux Presubmit', 'Linux Postsubmit'],
          );
        });

        test('without a specific label', () async {
          final enginePr = generatePullRequest(
            labels: <IssueLabel>[],
          );
          final List<Target> presubmitTargets = await scheduler.getPresubmitTargets(enginePr);
          expect(
            presubmitTargets.map((Target target) => target.value.name).toList(),
            (<String>['Linux Presubmit']),
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
          <dynamic>[
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
          <dynamic>[
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
          buildStatusProvider: (_) => buildStatusService,
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            gerritService: FakeGerritService(
              branchesValue: <String>['master', 'main'],
            ),
          ),
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
          ),
          buildStatusProvider: (_) => buildStatusService,
          datastoreProvider: (DatastoreDB db) => DatastoreService(db, 2),
          githubChecksService: GithubChecksService(config, githubChecksUtil: mockGithubChecksUtil),
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            gerritService: FakeGerritService(branchesValue: <String>['master']),
          ),
        );
        await scheduler.triggerPresubmitTargets(pullRequest: pullRequest);
        expect(
          verify(mockGithubChecksUtil.createCheckRun(any, any, any, captureAny, output: captureAnyNamed('output')))
              .captured,
          <dynamic>[
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
          <dynamic>[
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
          <dynamic>[CheckRunStatus.completed, CheckRunConclusion.success],
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
          <dynamic>[CheckRunStatus.completed, CheckRunConclusion.failure],
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
          <dynamic>[CheckRunStatus.completed, CheckRunConclusion.failure],
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
          buildStatusProvider: (_) => buildStatusService,
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildbucket: mockBuildbucket,
            gerritService: FakeGerritService(branchesValue: <String>['master']),
            pubsub: pubsub,
          ),
        );
        when(mockBuildbucket.batch(any)).thenAnswer(
          (_) async => BatchResponse(
            responses: <Response>[
              Response(
                searchBuilds: SearchBuildsResponse(
                  builds: <Build>[
                    generateBuild(1000, name: 'Linux', bucket: 'try'),
                    generateBuild(2000, name: 'Linux Coverage', bucket: 'try'),
                    generateBuild(3000, name: 'Mac', bucket: 'try', status: Status.scheduled),
                    generateBuild(4000, name: 'Windows', bucket: 'try', status: Status.started),
                    generateBuild(5000, name: 'Linux A', bucket: 'try', status: Status.failure),
                  ],
                ),
              ),
            ],
          ),
        );
        when(mockBuildbucket.scheduleBuild(any))
            .thenAnswer((_) async => generateBuild(5001, name: 'Linux A', bucket: 'try', status: Status.scheduled));
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
        final BatchRequest batchRequest = pubsub.messages.single as BatchRequest;
        expect(batchRequest.requests!.length, 1);
        // Schedule build should have been sent
        expect(batchRequest.requests!.single.scheduleBuild, isNotNull);
        final ScheduleBuildRequest scheduleBuildRequest = batchRequest.requests!.single.scheduleBuild!;
        // Verify expected parameters to schedule build
        expect(scheduleBuildRequest.builderId.builder, 'Linux A');
        expect(scheduleBuildRequest.properties!['custom'], 'abc');
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
          buildStatusProvider: (_) => buildStatusService,
          httpClientProvider: () => httpClient,
          luciBuildService: FakeLuciBuildService(
            config: config,
            githubChecksUtil: mockGithubChecksUtil,
            buildbucket: mockBuildbucket,
            gerritService: FakeGerritService(branchesValue: <String>['master']),
            pubsub: pubsub,
          ),
        );
        when(mockBuildbucket.batch(any)).thenAnswer(
          (_) async => BatchResponse(
            responses: <Response>[
              Response(
                searchBuilds: SearchBuildsResponse(
                  builds: <Build>[
                    generateBuild(1000, name: 'Linux', bucket: 'try'),
                    generateBuild(2000, name: 'Linux Coverage', bucket: 'try'),
                    generateBuild(3000, name: 'Mac', bucket: 'try', status: Status.scheduled),
                    generateBuild(4000, name: 'Windows', bucket: 'try', status: Status.started),
                    generateBuild(5000, name: 'Linux A', bucket: 'try', status: Status.failure),
                  ],
                ),
              ),
            ],
          ),
        );
        when(mockBuildbucket.scheduleBuild(any))
            .thenAnswer((_) async => generateBuild(5001, name: 'Linux A', bucket: 'try', status: Status.scheduled));
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
        final BatchRequest batchRequest = pubsub.messages.single as BatchRequest;
        expect(batchRequest.requests!.length, 1);
        // Schedule build should have been sent
        expect(batchRequest.requests!.single.scheduleBuild, isNotNull);
        final ScheduleBuildRequest scheduleBuildRequest = batchRequest.requests!.single.scheduleBuild!;
        // Verify expected parameters to schedule build
        expect(scheduleBuildRequest.builderId.builder, 'Linux A');
        expect(scheduleBuildRequest.properties!['custom'], 'abc');
      });

      test('triggers only specificed targets', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets = scheduler.getTriggerList(presubmitTargets, <String>['Linux 1']);
        expect(presubmitTriggerTargets.length, 1);
      });

      test('triggers all presubmit targets when trigger list is null', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets = scheduler.getTriggerList(presubmitTargets, null);
        expect(presubmitTriggerTargets.length, 2);
      });

      test('triggers all presubmit targets when trigger list is empty', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets = scheduler.getTriggerList(presubmitTargets, <String>[]);
        expect(presubmitTriggerTargets.length, 2);
      });

      test('triggers only targets that are contained in the trigger list', () async {
        final List<Target> presubmitTargets = <Target>[generateTarget(1), generateTarget(2)];
        final List<Target> presubmitTriggerTargets =
            scheduler.getTriggerList(presubmitTargets, <String>['Linux 1', 'Linux 3']);
        expect(presubmitTriggerTargets.length, 1);
        expect(presubmitTargets[0].value.name, 'Linux 1');
      });
    });
  });
}

CheckRun createCheckRun({String? name, required int id, CheckRunStatus status = CheckRunStatus.completed}) {
  final int externalId = id * 2;
  final String checkRunJson =
      '{"name": "$name", "id": $id, "external_id": "{$externalId}", "status": "$status", "started_at": "2020-05-10T02:49:31Z", "head_sha": "the_sha", "check_suite": {"id": 456}}';
  return CheckRun.fromJson(jsonDecode(checkRunJson) as Map<String, dynamic>);
}

String toSha(Commit commit) => commit.sha!;

int toTimestamp(Commit commit) => commit.timestamp!;
