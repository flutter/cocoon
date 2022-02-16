// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push_message;
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/logging.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:github/github.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';

void main() {
  late FakeConfig config;
  FakeGithubService githubService;
  late MockBuildBucketClient mockBuildBucketClient;
  late LuciBuildService service;
  RepositorySlug? slug;
  final MockGithubChecksUtil mockGithubChecksUtil = MockGithubChecksUtil();
  final MockGerritService mockGerritService = MockGerritService();
  late FakePubSub pubsub;

  final List<Target> targets = <Target>[
    generateTarget(1, properties: <String, String>{'os': 'abc'}),
  ];
  final PullRequest pullRequest = generatePullRequest(id: 1, repo: 'cocoon');

  group('getBuilds', () {
    final Build macBuild = generateBuild(999, name: 'Mac', status: Status.started);
    final Build linuxBuild = generateBuild(998, name: 'Linux', bucket: 'try', status: Status.started);

    setUp(() {
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        gerritService: mockGerritService,
        pubsub: pubsub,
      );
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Null build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[macBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<Build> builds = await service.getTryBuilds(
        Config.flutterSlug,
        'shasha',
        'abcd',
      );
      expect(builds.first, macBuild);
    });
    test('Existing prod build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[],
              ),
            ),
          ],
        );
      });
      final Iterable<Build> builds = await service.getProdBuilds(
        slug,
        'commit123',
        'abcd',
        'flutter',
      );
      expect(builds, isEmpty);
    });
    test('Existing try build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<Build> builds = await service.getTryBuilds(
        Config.flutterSlug,
        'shasha',
        'abcd',
      );
      expect(builds.first, linuxBuild);
    });
  });
  group('buildsForRepositoryAndPr', () {
    final Build macBuild = generateBuild(999, name: 'Mac', status: Status.started);
    final Build linuxBuild = generateBuild(998, name: 'Linux', status: Status.started);

    setUp(() {
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        pubsub: pubsub,
      );
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Empty responses are handled correctly', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[],
              ),
            ),
          ],
        );
      });
      final Map<String?, Build?> builds = await service.tryBuildsForPullRequest(pullRequest);
      expect(builds.keys, isEmpty);
    });

    test('Response returning a couple of builds', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[macBuild],
              ),
            ),
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Map<String?, Build?> builds = await service.tryBuildsForPullRequest(pullRequest);
      expect(builds, equals(<String, Build>{'Mac': macBuild, 'Linux': linuxBuild}));
    });
  });
  group('scheduleBuilds', () {
    setUp(() {
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        gerritService: mockGerritService,
        pubsub: pubsub,
      );
      slug = RepositorySlug('flutter', 'cocoon');
    });

    test('schedule try builds successfully', () async {
      final PullRequest pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              scheduleBuild: generateBuild(1),
            ),
          ],
        );
      });
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async => generateCheckRun(1));
      when(mockGerritService.branches(any, any, any)).thenAnswer((_) async => <String>['master']);
      final List<Target> scheduledTargets = await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
      );
      final Iterable<String> scheduledTargetNames = scheduledTargets.map((Target target) => target.value.name);
      expect(scheduledTargetNames, <String>['Linux 1']);
      final BatchRequest batchRequest = pubsub.messages.single as BatchRequest;
      expect(batchRequest.requests!.single.scheduleBuild, isNotNull);
      final ScheduleBuildRequest scheduleBuild = batchRequest.requests!.single.scheduleBuild!;
      expect(scheduleBuild.builderId.bucket, 'try');
      expect(scheduleBuild.builderId.builder, 'Linux 1');
      expect(scheduleBuild.notify?.pubsubTopic, 'projects/flutter-dashboard/topics/luci-builds');
      final Map<String, dynamic> userData =
          jsonDecode(String.fromCharCodes(base64Decode(scheduleBuild.notify!.userData!))) as Map<String, dynamic>;
      expect(userData, <String, dynamic>{
        'repo_owner': 'flutter',
        'repo_name': 'flutter',
        'user_agent': 'flutter-cocoon',
        'check_run_id': 1,
        'commit_sha': 'abc',
        'commit_branch': 'master',
        'builder_name': 'Linux 1'
      });
      final Map<String, dynamic> properties = scheduleBuild.properties!;
      final List<RequestedDimension> dimensions = scheduleBuild.dimensions!;
      expect(properties, <String, dynamic>{
        'os': 'abc',
        'dependencies': <dynamic>[],
        'bringup': false,
        'git_branch': 'master',
        'git_url': 'https://github.com/flutter/flutter',
        'git_ref': 'refs/pull/123/head',
        'exe_cipd_version': 'refs/heads/main'
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test('try to schedule builds already started', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux 1', status: Status.started),
                ],
              ),
            ),
          ],
        );
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
      );
      expect(
          records.where((LogRecord record) =>
              record.message.contains('Linux 1 has already been scheduled for this pull request')),
          hasLength(1));
    });

    test('try to schedule builds already passed', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux 1', status: Status.success),
                ],
              ),
            ),
          ],
        );
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
      );
      expect(
          records.where((LogRecord record) =>
              record.message.contains('Linux 1 has already been scheduled for this pull request')),
          hasLength(1));
    });
    test('try to schedule builds already scheduled', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux 1', status: Status.scheduled),
                ],
              ),
            ),
          ],
        );
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: targets,
      );
      expect(records[0].message, 'Linux 1 has already been scheduled for this pull request');
    });
    test('Schedule builds throws when current list of targets is empty', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any)).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2}
        });
      });
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      await expectLater(
          service.scheduleTryBuilds(
            pullRequest: pullRequest,
            targets: <Target>[],
          ),
          throwsA(isA<InternalServerError>()));
    });
    test('Try to schedule build on a unsupported repo', () async {
      expect(
          () async => await service.scheduleTryBuilds(
                targets: targets,
                pullRequest: generatePullRequest(repo: 'nonsupported'),
              ),
          throwsA(const TypeMatcher<BadRequestException>()));
    });
  });

  group('schedulePostsubmitBuilds', () {
    setUp(() {
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        FakeConfig(),
        mockBuildBucketClient,
        pubsub: pubsub,
      );
    });

    test('schedule postsubmit builds successfully', () async {
      final Commit commit = generateCommit(0);
      final Pair<Target, Task> toBeScheduled = Pair<Target, Task>(
        generateTarget(1),
        generateTask(1),
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <Pair<Target, Task>>[
          toBeScheduled,
        ],
      );
      // Only one batch request should be published
      expect(pubsub.messages.length, 1);
      final BatchRequest request = pubsub.messages.first as BatchRequest;
      expect(request.requests?.single.scheduleBuild, isNotNull);
      final ScheduleBuildRequest scheduleBuild = request.requests!.single.scheduleBuild!;
      expect(scheduleBuild.builderId.bucket, 'prod');
      expect(scheduleBuild.builderId.builder, 'Linux 1');
      expect(scheduleBuild.notify?.pubsubTopic, 'projects/flutter-dashboard/topics/luci-builds-prod');
      final Map<String, dynamic> userData =
          jsonDecode(String.fromCharCodes(base64Decode(scheduleBuild.notify!.userData!))) as Map<String, dynamic>;
      expect(userData, <String, dynamic>{
        'commit_key': 'flutter/flutter/master/1',
        'task_key': '1',
      });
      final Map<String, dynamic> properties = scheduleBuild.properties!;
      expect(properties, <String, dynamic>{
        'dependencies': <dynamic>[],
        'bringup': false,
        'git_branch': 'master',
        'exe_cipd_version': 'refs/heads/master'
      });
    });
  });

  group('cancelBuilds', () {
    setUp(() {
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        pubsub: pubsub,
      );
      slug = RepositorySlug('flutter', 'cocoon');
    });
    test('Cancel builds when build list is empty', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      await service.cancelBuilds(pullRequest, 'new builds');
      verify(mockBuildBucketClient.batch(any)).called(1);
    });
    test('Cancel builds that are scheduled', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux', status: Status.started),
                ],
              ),
            )
          ],
        );
      });
      await service.cancelBuilds(pullRequest, 'new builds');
      expect(verify(mockBuildBucketClient.batch(captureAny)).captured[1].requests[0].cancelBuild.toJson(),
          json.decode('{"id": "998", "summaryMarkdown": "new builds"}'));
    });
    test('Cancel builds from unsuported repo', () async {
      expect(
          () async => await service.cancelBuilds(
                generatePullRequest(repo: 'notsupported'),
                'new builds',
              ),
          throwsA(const TypeMatcher<BadRequestException>()));
    });
  });

  group('failedBuilds', () {
    setUp(() {
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        pubsub: pubsub,
      );
      slug = RepositorySlug('flutter', 'flutter');
    });
    test('Failed builds from an empty list', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return const BatchResponse(
          responses: <Response>[],
        );
      });
      final List<Build?> result = await service.failedBuilds(pullRequest, <Target>[]);
      expect(result, isEmpty);
    });
    test('Failed builds from a list of builds with failures', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux 1', status: Status.failure),
                ],
              ),
            )
          ],
        );
      });
      final List<Build?> result = await service.failedBuilds(pullRequest, <Target>[generateTarget(1)]);
      expect(result, hasLength(1));
    });
  });
  group('rescheduleBuild', () {
    late push_message.BuildPushMessage buildPushMessage;

    setUp(() {
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        pubsub: pubsub,
      );
      final Map<String, dynamic> json = jsonDecode(buildPushMessageString(
        'COMPLETED',
        result: 'FAILURE',
        builderName: 'Linux Host Engine',
        userData: '{}',
      )) as Map<String, dynamic>;
      buildPushMessage = push_message.BuildPushMessage.fromJson(json);
    });

    test('Reschedule an existing build', () async {
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1));
      final bool rescheduled = await service.rescheduleBuild(
        commitSha: 'abc',
        builderName: 'mybuild',
        buildPushMessage: buildPushMessage,
      );
      expect(rescheduled, isTrue);
      verify(mockBuildBucketClient.scheduleBuild(any)).called(1);
    });
  });
  group('reschedulePostsubmitBuild', () {
    setUp(() {
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        pubsub: pubsub,
      );
    });
    test('Reschedule an existing build', () async {
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1));
      await service.reschedulePostsubmitBuild(
        commitSha: 'abc',
        builderName: 'mybuild',
        branch: 'master',
        repo: 'flutter',
      );
      verify(mockBuildBucketClient.scheduleBuild(any)).called(1);
    });
  });

  group('checkRerunBuilder', () {
    late Commit commit;
    late Commit totCommit;
    late DatastoreService datastore;
    String repo;
    String branch;
    setUp(() {
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config,
        mockBuildBucketClient,
        pubsub: pubsub,
      );
      datastore = DatastoreService(config.db, 5);
    });

    test('Pass repo and properties correctly', () async {
      repo = 'engine';
      branch = 'main';
      totCommit = generateCommit(1, sha: 'def', repo: repo, branch: branch);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/$branch',
          status: Task.statusFailed,
          buildNumber: 1,
          builderName: 'Mac abc',
          summaryMarkdown: 'summary');
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1, name: 'Mac abc'));
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: repo,
        datastore: datastore,
      );
      final ScheduleBuildRequest scheduleBuildRequest =
          verify(mockBuildBucketClient.scheduleBuild(captureAny)).captured.single as ScheduleBuildRequest;
      final Map<String, dynamic> properties = scheduleBuildRequest.properties!;
      for (String key in Config.engineDefaultProperties.keys) {
        expect(properties.containsKey(key), true);
      }
      expect(scheduleBuildRequest.gitilesCommit?.project, 'external/github.com/flutter/$repo');
      expect(rerunFlag, true);
    });

    test('Rerun a test failed flutter builder', () async {
      repo = 'flutter';
      branch = 'master';
      totCommit = generateCommit(1, sha: 'def', repo: repo, branch: branch);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/$branch',
          status: Task.statusFailed,
          buildNumber: 1,
          builderName: 'Mac abc',
          summaryMarkdown: 'summary');
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1, name: 'Mac abc'));
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: repo,
        datastore: datastore,
      );
      expect(rerunFlag, true);
    });

    test('Rerun an infra failed flutter builder', () async {
      repo = 'flutter';
      branch = 'master';
      totCommit = generateCommit(1, sha: 'def', repo: repo, branch: branch);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/$branch',
          status: Task.statusInfraFailure,
          buildNumber: 1,
          builderName: 'Mac abc',
          summaryMarkdown: 'summary');
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1, name: 'Mac abc'));
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: repo,
        datastore: datastore,
      );
      expect(rerunFlag, true);
    });

    test('Do not rerun a successful flutter builder', () async {
      repo = 'flutter';
      branch = 'master';
      totCommit = generateCommit(1, sha: 'def', repo: repo, branch: branch);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/$branch',
          status: Task.statusSucceeded,
          buildNumber: 1,
          builderName: 'Mac abc');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 0,
        repo: repo,
        datastore: datastore,
      );
      expect(rerunFlag, false);
    });

    test('Do not rerun a flutter builder exceeding retry limit', () async {
      repo = 'flutter';
      branch = 'master';
      totCommit = generateCommit(1, sha: 'def', repo: repo, branch: branch);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final LuciTask luciTask = LuciTask(
          commitSha: 'def',
          ref: 'refs/heads/$branch',
          status: Task.statusInfraFailure,
          buildNumber: 1,
          builderName: 'Mac abc');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        luciTask: luciTask,
        retries: 1,
        repo: repo,
        datastore: datastore,
      );
      expect(rerunFlag, false);
    });

    test('Do not rerun a flutter builder when not blocking the tree', () async {
      repo = 'flutter';
      branch = 'master';
      totCommit = generateCommit(1, sha: 'def', repo: repo, branch: branch);
      commit = generateCommit(1, sha: 'abc', repo: repo, branch: branch);
      config.db.values[totCommit.key] = totCommit;
      config.db.values[commit.key] = commit;
      config.maxLuciTaskRetriesValue = 1;
      final LuciTask luciTask = LuciTask(
          commitSha: 'abc',
          ref: 'refs/heads/$branch',
          status: Task.statusInfraFailure,
          buildNumber: 1,
          builderName: 'Mac abc');
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: commit,
        luciTask: luciTask,
        retries: 0,
        repo: repo,
        datastore: datastore,
      );
      expect(rerunFlag, false);
    });
  });
}
