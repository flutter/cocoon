// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore_commit;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push_message;
import 'package:cocoon_service/src/service/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/datastore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/push_message.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late CacheService cache;
  late FakeConfig config;
  FakeGithubService githubService;
  late MockBuildBucketClient mockBuildBucketClient;
  late MockBuildBucketV2Client mockBuildBucketV2Client;
  late LuciBuildService service;
  late RepositorySlug slug;
  late MockGithubChecksUtil mockGithubChecksUtil = MockGithubChecksUtil();
  late FakePubSub pubsub;

  final List<Target> targets = <Target>[
    generateTarget(1, properties: <String, String>{'os': 'abc'}),
  ];
  final PullRequest pullRequest = generatePullRequest(id: 1, repo: 'cocoon');

  group('getBuilds', () {
    final Build macBuild = generateBuild(999, name: 'Mac', status: Status.started);
    final Build linuxBuild = generateBuild(998, name: 'Linux', bucket: 'try', status: Status.started);

    setUp(() {
      cache = CacheService(inMemory: true);
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      mockBuildBucketV2Client = MockBuildBucketV2Client();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        gerritService: FakeGerritService(),
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

    test('Existing try build by pull request', () async {
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
      final Iterable<Build> builds = await service.getTryBuildsByPullRequest(
        PullRequest(id: 998, base: PullRequestHead(repo: Repository(fullName: 'flutter/cocoon'))),
      );
      expect(builds.first, linuxBuild);
    });
  });

  group('getBuilders', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        gerritService: FakeGerritService(),
        pubsub: pubsub,
      );
      slug = RepositorySlug('flutter', 'flutter');
    });

    test('with one rpc call', () async {
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return const ListBuildersResponse(
          builders: [
            BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'test1')),
            BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'test2')),
          ],
        );
      });
      final Set<String> builders = await service.getAvailableBuilderSet();
      expect(builders.length, 2);
      expect(builders.contains('test1'), isTrue);
    });

    test('with more than one rpc calls', () async {
      int retries = -1;
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        retries++;
        if (retries == 0) {
          return const ListBuildersResponse(
            builders: [
              BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'test1')),
              BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'test2')),
            ],
            nextPageToken: 'token',
          );
        } else if (retries == 1) {
          return const ListBuildersResponse(
            builders: [
              BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'test3')),
              BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'test4')),
            ],
          );
        } else {
          return const ListBuildersResponse(builders: []);
        }
      });
      final Set<String> builders = await service.getAvailableBuilderSet();
      expect(builders.length, 4);
      expect(builders, <String>{'test1', 'test2', 'test3', 'test4'});
    });
  });

  group('buildsForRepositoryAndPr', () {
    final Build macBuild = generateBuild(999, name: 'Mac', status: Status.started);
    final Build linuxBuild = generateBuild(998, name: 'Linux', status: Status.started);

    setUp(() {
      cache = CacheService(inMemory: true);
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
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
      final Iterable<Build> builds = await service.getTryBuilds(
        RepositorySlug.full(pullRequest.base!.repo!.fullName),
        pullRequest.head!.sha!,
        null,
      );
      expect(builds, isEmpty);
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
      final Iterable<Build> builds = await service.getTryBuilds(
        RepositorySlug.full(pullRequest.base!.repo!.fullName),
        pullRequest.head!.sha!,
        null,
      );
      expect(builds, equals(<Build>{macBuild, linuxBuild}));
    });
  });

  group('scheduleBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      mockGithubChecksUtil = MockGithubChecksUtil();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        githubChecksUtil: mockGithubChecksUtil,
        gerritService: FakeGerritService(branchesValue: <String>['master']),
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
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
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
        'builder_name': 'Linux 1',
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
        'exe_cipd_version': 'refs/heads/main',
        'recipe': 'devicelab/devicelab',
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test('schedule try builds with github build labels successfully', () async {
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
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
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
        'builder_name': 'Linux 1',
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
        'exe_cipd_version': 'refs/heads/main',
        'recipe': 'devicelab/devicelab',
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test('Schedule builds no-ops when targets list is empty', () async {
      await service.scheduleTryBuilds(
        pullRequest: pullRequest,
        targets: <Target>[],
      );
      verifyNever(mockGithubChecksUtil.createCheckRun(any, any, any, any));
    });
  });

  group('schedulePostsubmitBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: FakeConfig(),
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });

    test('schedule packages postsubmit builds successfully', () async {
      final Commit commit = generateCommit(0);
      when(mockGithubChecksUtil.createCheckRun(any, Config.packagesSlug, any, 'Linux 1'))
          .thenAnswer((_) async => generateCheckRun(1));
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return const ListBuildersResponse(
          builders: [
            BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'Linux 1')),
          ],
        );
      });
      final Tuple<Target, Task, int> toBeScheduled = Tuple<Target, Task, int>(
        generateTarget(
          1,
          properties: <String, String>{
            'recipe': 'devicelab/devicelab',
            'os': 'debian-10.12',
          },
          slug: Config.packagesSlug,
        ),
        generateTask(1),
        LuciBuildService.kDefaultPriority,
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <Tuple<Target, Task, int>>[
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
        'check_run_id': 1,
        'commit_sha': '0',
        'commit_branch': 'master',
        'builder_name': 'Linux 1',
        'repo_owner': 'flutter',
        'repo_name': 'packages',
        'firestore_commit_document_name': '0',
        'firestore_task_document_name': '0_task1_1',
      });
      final Map<String, dynamic> properties = scheduleBuild.properties!;
      expect(properties, <String, dynamic>{
        'dependencies': <dynamic>[],
        'bringup': false,
        'git_branch': 'master',
        'exe_cipd_version': 'refs/heads/master',
        'os': 'debian-10.12',
        'recipe': 'devicelab/devicelab',
      });
      expect(scheduleBuild.exe, <String, String>{
        'cipdVersion': 'refs/heads/master',
      });
      expect(scheduleBuild.dimensions, isNotEmpty);
      expect(
        scheduleBuild.dimensions!.singleWhere((RequestedDimension dimension) => dimension.key == 'os').value,
        'debian-10.12',
      );
    });

    test('schedule postsubmit builds with correct userData for checkRuns', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final Commit commit = generateCommit(0, repo: 'packages');
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return const ListBuildersResponse(
          builders: [
            BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'Linux 1')),
          ],
        );
      });
      final Tuple<Target, Task, int> toBeScheduled = Tuple<Target, Task, int>(
        generateTarget(
          1,
          properties: <String, String>{
            'os': 'debian-10.12',
          },
          slug: RepositorySlug('flutter', 'packages'),
        ),
        generateTask(1),
        LuciBuildService.kDefaultPriority,
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <Tuple<Target, Task, int>>[
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
        'check_run_id': 1,
        'commit_sha': '0',
        'commit_branch': 'master',
        'builder_name': 'Linux 1',
        'repo_owner': 'flutter',
        'repo_name': 'packages',
        'firestore_commit_document_name': '0',
        'firestore_task_document_name': '0_task1_1',
      });
    });

    test('return the orignal list when hitting buildbucket exception', () async {
      final Commit commit = generateCommit(0, repo: 'packages');
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        throw const BuildBucketException(1, 'error');
      });
      final Tuple<Target, Task, int> toBeScheduled = Tuple<Target, Task, int>(
        generateTarget(
          1,
          properties: <String, String>{
            'os': 'debian-10.12',
          },
          slug: RepositorySlug('flutter', 'packages'),
        ),
        generateTask(1),
        LuciBuildService.kDefaultPriority,
      );
      final List<Tuple<Target, Task, int>> results = await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <Tuple<Target, Task, int>>[
          toBeScheduled,
        ],
      );
      expect(results, <Tuple<Target, Task, int>>[
        toBeScheduled,
      ]);
    });

    test('reschedule using checkrun event fails gracefully', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

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

      final pushMessage = generateCheckRunEvent(action: 'created', numberOfPullRequests: 1);
      final Map<String, dynamic> jsonMap = json.decode(pushMessage.data!);
      final Map<String, dynamic> jsonSubMap = json.decode(jsonMap['2']);
      final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(jsonSubMap);

      expect(
        () async => service.reschedulePostsubmitBuildUsingCheckRunEvent(
          checkRunEvent,
          commit: generateCommit(0),
          task: generateTask(0),
          target: generateTarget(0),
        ),
        throwsA(const TypeMatcher<NoBuildFoundException>()),
      );
    });

    test('do not create postsubmit checkrun for bringup: true target', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final Commit commit = generateCommit(0, repo: Config.packagesSlug.name);
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return const ListBuildersResponse(
          builders: [
            BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'Linux 1')),
          ],
        );
      });
      final Tuple<Target, Task, int> toBeScheduled = Tuple<Target, Task, int>(
        generateTarget(
          1,
          properties: <String, String>{
            'os': 'debian-10.12',
          },
          bringup: true,
          slug: Config.packagesSlug,
        ),
        generateTask(1, parent: commit),
        LuciBuildService.kDefaultPriority,
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <Tuple<Target, Task, int>>[
          toBeScheduled,
        ],
      );
      // Only one batch request should be published
      expect(pubsub.messages.length, 1);
      final BatchRequest request = pubsub.messages.first as BatchRequest;
      expect(request.requests?.single.scheduleBuild, isNotNull);
      final ScheduleBuildRequest scheduleBuild = request.requests!.single.scheduleBuild!;
      expect(scheduleBuild.builderId.bucket, 'staging');
      expect(scheduleBuild.builderId.builder, 'Linux 1');
      expect(scheduleBuild.notify?.pubsubTopic, 'projects/flutter-dashboard/topics/luci-builds-prod');
      final Map<String, dynamic> userData =
          jsonDecode(String.fromCharCodes(base64Decode(scheduleBuild.notify!.userData!))) as Map<String, dynamic>;
      // No check run related data.
      expect(userData, <String, dynamic>{
        'commit_key': 'flutter/packages/master/0',
        'task_key': '1',
        'firestore_commit_document_name': '0',
        'firestore_task_document_name': '0_task1_1',
      });
    });

    test('Skip non-existing builder', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final Commit commit = generateCommit(0);
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 2'));
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return const ListBuildersResponse(
          builders: [
            BuilderItem(id: BuilderId(bucket: 'prod', project: 'flutter', builder: 'Linux 2')),
          ],
        );
      });
      final Tuple<Target, Task, int> toBeScheduled1 = Tuple<Target, Task, int>(
        generateTarget(
          1,
          properties: <String, String>{
            'os': 'debian-10.12',
          },
        ),
        generateTask(1),
        LuciBuildService.kDefaultPriority,
      );
      final Tuple<Target, Task, int> toBeScheduled2 = Tuple<Target, Task, int>(
        generateTarget(
          2,
          properties: <String, String>{
            'os': 'debian-10.12',
          },
        ),
        generateTask(1),
        LuciBuildService.kDefaultPriority,
      );
      await service.schedulePostsubmitBuilds(
        commit: commit,
        toBeScheduled: <Tuple<Target, Task, int>>[
          toBeScheduled1,
          toBeScheduled2,
        ],
      );
      expect(pubsub.messages.length, 1);
      final BatchRequest request = pubsub.messages.first as BatchRequest;
      // Only existing builder: `Linux 2` is scheduled.
      expect(request.requests?.length, 1);
      expect(request.requests?.single.scheduleBuild, isNotNull);
      final ScheduleBuildRequest scheduleBuild = request.requests!.single.scheduleBuild!;
      expect(scheduleBuild.builderId.bucket, 'prod');
      expect(scheduleBuild.builderId.builder, 'Linux 2');
    });
  });

  group('schedulePresubmitBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: FakeConfig(),
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });
    test('reschedule using checkrun event', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(
                    1,
                    name: 'Linux',
                    status: Status.ended,
                    tags: {
                      'buildset': <String>['pr/git/123'],
                      'cipd_version': <String>['refs/heads/main'],
                      'github_link': <String>['https://github.com/flutter/flutter/pull/1'],
                    },
                    input: const Input(properties: {'test': 'abc'}),
                  ),
                ],
              ),
            ),
          ],
        );
      });
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1));

      final pushMessage = generateCheckRunEvent(action: 'created', numberOfPullRequests: 1);
      final Map<String, dynamic> jsonMap = json.decode(pushMessage.data!);
      final Map<String, dynamic> jsonSubMap = json.decode(jsonMap['2']);
      final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(jsonSubMap);

      await service.reschedulePresubmitBuildUsingCheckRunEvent(
        checkRunEvent,
      );
      final List<dynamic> captured = verify(
        mockBuildBucketClient.scheduleBuild(
          captureAny,
        ),
      ).captured;
      expect(captured.length, 1);
      final ScheduleBuildRequest scheduleBuildRequest = captured[0] as ScheduleBuildRequest;
      final Map<String, dynamic> userData =
          jsonDecode(String.fromCharCodes(base64Decode(scheduleBuildRequest.notify!.userData!)))
              as Map<String, dynamic>;
      expect(userData, <String, dynamic>{
        'check_run_id': 1,
        'commit_branch': 'master',
        'commit_sha': 'ec26c3e57ca3a959ca5aad62de7213c562f8c821',
        'repo_owner': 'flutter',
        'repo_name': 'flutter',
        'user_agent': 'flutter-cocoon',
      });
      final Map<String, Object>? properties = scheduleBuildRequest.properties;
      expect(properties!['overrides'], ['override: test']);
    });
  });

  group('cancelBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
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
      // This is okay, it is getting called twice when it runs cancel builds
      // because the call is no longer being short-circuited. It calls batch in
      // tryBuildsForPullRequest and it calls in the top level cancelBuilds
      // function.
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
            ),
          ],
        );
      });
      await service.cancelBuilds(pullRequest, 'new builds');
      expect(
        verify(mockBuildBucketClient.batch(captureAny)).captured[1].requests[0].cancelBuild.toJson(),
        json.decode('{"id": "998", "summaryMarkdown": "new builds"}'),
      );
    });
  });

  group('failedBuilds', () {
    setUp(() {
      cache = CacheService(inMemory: true);
      githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService);
      mockBuildBucketClient = MockBuildBucketClient();
      mockBuildBucketV2Client = MockBuildBucketV2Client();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
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
            ),
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
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      mockBuildBucketV2Client = MockBuildBucketV2Client();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        pubsub: pubsub,
      );
      final Map<String, dynamic> json = jsonDecode(
        buildPushMessageString(
          'COMPLETED',
          result: 'FAILURE',
          builderName: 'Linux Host Engine',
          userData: '{}',
        ),
      ) as Map<String, dynamic>;
      buildPushMessage = push_message.BuildPushMessage.fromJson(json);
    });

    test('Reschedule an existing build', () async {
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBuild(1));
      final build = await service.rescheduleBuild(
        builderName: 'mybuild',
        buildPushMessage: buildPushMessage,
        rescheduleAttempt: 2,
      );
      expect(build.id, '1');
      expect(build.status, Status.success);
      final List<dynamic> captured = verify(mockBuildBucketClient.scheduleBuild(captureAny)).captured;
      expect(captured.length, 1);
      final ScheduleBuildRequest scheduleBuildRequest = captured[0] as ScheduleBuildRequest;
      // This is to validate `scheduleBuildRequest` can be json.encoded correctly.
      // It complains when some non-String typed data exists.
      expect(json.encode(scheduleBuildRequest), isNotNull);
      expect(scheduleBuildRequest.tags!.containsKey('current_attempt'), true);
      expect(scheduleBuildRequest.tags!['current_attempt'], <String>['2']);
    });
  });

  group('checkRerunBuilder', () {
    late Commit commit;
    late Commit totCommit;
    late DatastoreService datastore;
    late MockGithubChecksUtil mockGithubChecksUtil;
    late MockFirestoreService mockFirestoreService;
    firestore.Task? firestoreTask;
    firestore_commit.Commit? firestoreCommit;
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      firestoreTask = null;
      firestoreCommit = null;
      mockBuildBucketClient = MockBuildBucketClient();
      mockGithubChecksUtil = MockGithubChecksUtil();
      mockFirestoreService = MockFirestoreService();
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output')))
          .thenAnswer((realInvocation) async => generateCheckRun(1));
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<firestore_commit.Commit>.value(
          firestoreCommit,
        );
      });
      when(
        mockFirestoreService.queryRecentCommits(
          limit: captureAnyNamed('limit'),
          slug: captureAnyNamed('slug'),
          branch: captureAnyNamed('branch'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<firestore_commit.Commit>>.value(
          <firestore_commit.Commit>[firestoreCommit!],
        );
      });
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        buildBucketV2Client: mockBuildBucketV2Client,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
      datastore = DatastoreService(config.db, 5);
    });

    test('Pass repo and properties correctly', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1, status: firestore.Task.statusFailed);
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1, repo: 'engine', branch: 'main');
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusFailed,
        parent: totCommit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      expect(task.attempts, 1);
      expect(task.status, Task.statusFailed);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(pubsub.messages.length, 1);
      final ScheduleBuildRequest scheduleBuildRequest =
          (pubsub.messages.single as BatchRequest).requests!.single.scheduleBuild!;
      final Map<String, dynamic> properties = scheduleBuildRequest.properties!;
      for (String key in Config.defaultProperties.keys) {
        expect(properties.containsKey(key), true);
      }
      expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);
      expect(scheduleBuildRequest.gitilesCommit?.project, 'mirrors/engine');
      expect(scheduleBuildRequest.tags?['trigger_type'], <String>['auto_retry']);
      expect(rerunFlag, isTrue);
      expect(task.attempts, 2);
      expect(task.status, Task.statusInProgress);
    });

    test('Rerun a test failed builder', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1, status: firestore.Task.statusFailed);
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusFailed,
        parent: totCommit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);
    });

    test('Rerun an infra failed builder', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1, status: firestore.Task.statusInfraFailure);
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: totCommit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);
    });

    test('Skip rerun a failed test when task status update hit exception', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1, status: firestore.Task.statusInfraFailure);
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        throw InternalError();
      });
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusFailed,
        parent: totCommit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
      expect(pubsub.messages.length, 0);
    });

    test('Do not rerun a successful builder', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusSucceeded,
        parent: totCommit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
    });

    test('Do not rerun a builder exceeding retry limit', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: totCommit,
        buildNumber: 1,
        attempts: 2,
      );
      final Target target = generateTarget(1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
    });

    test('Do not rerun a builder when not tip of tree', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1);
      totCommit = generateCommit(2, sha: 'def');
      commit = generateCommit(1, sha: 'abc');
      config.db.values[totCommit.key] = totCommit;
      config.db.values[commit.key] = commit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: commit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: commit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isFalse);
    });

    test('insert retried task document to firestore', () async {
      firestoreTask = generateFirestoreTask(1, attempts: 1, status: firestore.Task.statusInfraFailure);
      firestoreCommit = generateFirestoreCommit(1);
      totCommit = generateCommit(1);
      config.db.values[totCommit.key] = totCommit;
      config.maxLuciTaskRetriesValue = 1;
      final Task task = generateTask(
        1,
        status: Task.statusInfraFailure,
        parent: totCommit,
        buildNumber: 1,
      );
      final Target target = generateTarget(1);
      expect(firestoreTask!.attempts, 1);
      final bool rerunFlag = await service.checkRerunBuilder(
        commit: totCommit,
        task: task,
        target: target,
        datastore: datastore,
        firestoreService: mockFirestoreService,
        taskDocument: firestoreTask!,
      );
      expect(rerunFlag, isTrue);

      expect(firestoreTask!.attempts, 2);
      final List<dynamic> captured = verify(mockFirestoreService.batchWriteDocuments(captureAny, captureAny)).captured;
      expect(captured.length, 2);
      final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
      expect(batchWriteRequest.writes!.length, 1);
      final Document insertedTaskDocument = batchWriteRequest.writes![0].update!;
      expect(insertedTaskDocument, firestoreTask);
      expect(firestoreTask!.status, firestore.Task.statusInProgress);
    });
  });
}
