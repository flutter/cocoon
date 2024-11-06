// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore_commit;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:cocoon_service/src/service/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/datastore.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/build_bucket_messages.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late CacheService cache;
  late FakeConfig config;
  FakeGithubService githubService;
  late MockBuildBucketClient mockBuildBucketClient;
  late LuciBuildService service;
  late MockGithubChecksUtil mockGithubChecksUtil = MockGithubChecksUtil();
  late FakePubSub pubsub;

  final List<Target> targets = <Target>[
    generateTarget(1, properties: <String, String>{'os': 'abc'}),
  ];
  final PullRequest pullRequest = generatePullRequest(id: 1, repo: 'cocoon');

  group('getBuilds', () {
    final bbv2.Build macBuild = generateBbv2Build(Int64(998), name: 'Mac', status: bbv2.Status.STARTED);
    final bbv2.Build linuxBuild = generateBbv2Build(
      Int64(998),
      name: 'Linux',
      bucket: 'try',
      status: bbv2.Status.STARTED,
    );

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
        gerritService: FakeGerritService(),
        pubsub: pubsub,
      );
    });

    test('Null build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[macBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<bbv2.Build> builds = await service.getTryBuilds(
        sha: 'shasha',
        builderName: 'abcd',
      );
      expect(builds.first, macBuild);
    });

    test('Existing prod build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[],
              ),
            ),
          ],
        );
      });
      final Iterable<bbv2.Build> builds = await service.getProdBuilds(
        builderName: 'abcd',
      );
      expect(builds, isEmpty);
    });

    test('Existing try build', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<bbv2.Build> builds = await service.getTryBuilds(
        sha: 'shasha',
        builderName: 'abcd',
      );
      expect(builds.first, linuxBuild);
    });

    test('Existing try build by pull request', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<bbv2.Build> builds = await service.getTryBuildsByPullRequest(
        pullRequest: PullRequest(
          id: 998,
          base: PullRequestHead(repo: Repository(fullName: 'flutter/cocoon')),
        ),
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
        gerritService: FakeGerritService(),
        pubsub: pubsub,
      );
    });

    test('with one rpc call', () async {
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'test1',
              ),
            ),
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'test2',
              ),
            ),
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
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test1',
                ),
              ),
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test2',
                ),
              ),
            ],
            nextPageToken: 'token',
          );
        } else if (retries == 1) {
          return bbv2.ListBuildersResponse(
            builders: [
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test3',
                ),
              ),
              bbv2.BuilderItem(
                id: bbv2.BuilderID(
                  bucket: 'prod',
                  project: 'flutter',
                  builder: 'test4',
                ),
              ),
            ],
          );
        } else {
          return bbv2.ListBuildersResponse(builders: []);
        }
      });
      final Set<String> builders = await service.getAvailableBuilderSet();
      expect(builders.length, 4);
      expect(builders, <String>{'test1', 'test2', 'test3', 'test4'});
    });
  });

  group('buildsForRepositoryAndPr', () {
    final bbv2.Build macBuild = generateBbv2Build(Int64(999), name: 'Mac', status: bbv2.Status.STARTED);
    final bbv2.Build linuxBuild = generateBbv2Build(
      Int64(998),
      name: 'Linux',
      status: bbv2.Status.STARTED,
    );

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
        pubsub: pubsub,
      );
    });

    test('Empty responses are handled correctly', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[],
              ),
            ),
          ],
        );
      });
      final Iterable<bbv2.Build> builds = await service.getTryBuilds(
        sha: pullRequest.head!.sha!,
        builderName: null,
      );
      expect(builds, isEmpty);
    });

    test('Response returning a couple of builds', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[macBuild],
              ),
            ),
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[linuxBuild],
              ),
            ),
          ],
        );
      });
      final Iterable<bbv2.Build> builds = await service.getTryBuilds(
        sha: pullRequest.head!.sha!,
        builderName: null,
      );
      expect(builds, equals(<bbv2.Build>{macBuild, linuxBuild}));
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
        githubChecksUtil: mockGithubChecksUtil,
        gerritService: FakeGerritService(branchesValue: <String>['master']),
        pubsub: pubsub,
      );
    });

    test('schedule try builds successfully', () async {
      final PullRequest pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              scheduleBuild: generateBbv2Build(Int64(1)),
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

      final bbv2.BatchRequest batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final bbv2.ScheduleBuildRequest scheduleBuild = batchRequest.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'try');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-presubmit',
      );

      final Map<String, dynamic> userDataMap = UserData.decodeUserDataBytes(scheduleBuild.notify.userData);

      expect(userDataMap, <String, dynamic>{
        'repo_owner': 'flutter',
        'repo_name': 'flutter',
        'user_agent': 'flutter-cocoon',
        'check_run_id': 1,
        'commit_sha': 'abc',
        'commit_branch': 'master',
        'builder_name': 'Linux 1',
      });

      final Map<String, bbv2.Value> properties = scheduleBuild.properties.fields;
      final List<bbv2.RequestedDimension> dimensions = scheduleBuild.dimensions;
      expect(properties, <String, bbv2.Value>{
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'git_url': bbv2.Value(stringValue: 'https://github.com/flutter/flutter'),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
      });
      expect(dimensions.length, 1);
      expect(dimensions[0].key, 'os');
      expect(dimensions[0].value, 'abc');
    });

    test('schedule try builds with github build labels successfully', () async {
      final PullRequest pullRequest = generatePullRequest();
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              scheduleBuild: generateBbv2Build(Int64(1)),
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

      final bbv2.BatchRequest batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubsub.messages.single);
      expect(batchRequest.requests.single.scheduleBuild, isNotNull);

      final bbv2.ScheduleBuildRequest scheduleBuild = batchRequest.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'try');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-presubmit',
      );

      final Map<String, dynamic> userDataMap = UserData.decodeUserDataBytes(scheduleBuild.notify.userData);

      expect(userDataMap, <String, dynamic>{
        'repo_owner': 'flutter',
        'repo_name': 'flutter',
        'user_agent': 'flutter-cocoon',
        'check_run_id': 1,
        'commit_sha': 'abc',
        'commit_branch': 'master',
        'builder_name': 'Linux 1',
      });

      final Map<String, bbv2.Value> properties = scheduleBuild.properties.fields;
      final List<bbv2.RequestedDimension> dimensions = scheduleBuild.dimensions;
      expect(properties, <String, bbv2.Value>{
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'git_url': bbv2.Value(stringValue: 'https://github.com/flutter/flutter'),
        'git_ref': bbv2.Value(stringValue: 'refs/pull/123/head'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/main'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
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
    late DatastoreService datastore;
    late MockFirestoreService mockFirestoreService;
    setUp(() {
      config = FakeConfig();
      datastore = DatastoreService(config.db, 5);
      mockFirestoreService = MockFirestoreService();
      cache = CacheService(inMemory: true);
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });

    test('schedule packages postsubmit builds successfully', () async {
      final Commit commit = generateCommit(0);
      when(
        mockGithubChecksUtil.createCheckRun(
          any,
          Config.packagesSlug,
          any,
          'Linux 1',
        ),
      ).thenAnswer((_) async => generateCheckRun(1));
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 1',
              ),
            ),
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

      final bbv2.BatchRequest request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      expect(request.requests.single.scheduleBuild, isNotNull);

      final bbv2.ScheduleBuildRequest scheduleBuild = request.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'prod');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-postsubmit',
      );

      final Map<String, dynamic> userDataMap = UserData.decodeUserDataBytes(scheduleBuild.notify.userData);

      expect(userDataMap, <String, dynamic>{
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

      final Map<String, bbv2.Value> properties = scheduleBuild.properties.fields;
      expect(properties, <String, bbv2.Value>{
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(stringValue: 'master'),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/master'),
        'os': bbv2.Value(stringValue: 'debian-10.12'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
      });

      expect(
        scheduleBuild.exe,
        bbv2.Executable(cipdVersion: 'refs/heads/master'),
      );
      expect(scheduleBuild.dimensions, isNotEmpty);
      expect(
        scheduleBuild.dimensions
            .singleWhere(
              (bbv2.RequestedDimension dimension) => dimension.key == 'os',
            )
            .value,
        'debian-10.12',
      );
    });

    test('schedule postsubmit builds with correct userData for checkRuns', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final Commit commit = generateCommit(0, repo: 'packages');
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 1',
              ),
            ),
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

      final bbv2.BatchRequest request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      expect(request.requests.single.scheduleBuild, isNotNull);

      final bbv2.ScheduleBuildRequest scheduleBuild = request.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'prod');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-postsubmit',
      );

      final Map<String, dynamic> userData = UserData.decodeUserDataBytes(scheduleBuild.notify.userData);

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
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[],
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
          taskDocument: generateFirestoreTask(0),
          datastore: datastore,
          firestoreService: mockFirestoreService,
        ),
        throwsA(const TypeMatcher<NoBuildFoundException>()),
      );
    });

    test('reschedule using checkrun event successfully', () async {
      when(
        mockFirestoreService.batchWriteDocuments(
          captureAny,
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(999),
                    name: 'Linux 1',
                    status: bbv2.Status.ENDED_MASK,
                    input: bbv2.Build_Input(properties: bbv2.Struct(fields: {})),
                    tags: <bbv2.StringPair>[],
                  ),
                ],
              ),
            ),
          ],
        );
      });

      final pushMessage = generateCheckRunEvent(action: 'created', numberOfPullRequests: 1);
      final Map<String, dynamic> jsonMap = json.decode(pushMessage.data!);
      final Map<String, dynamic> jsonSubMap = json.decode(jsonMap['2']);
      final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(jsonSubMap);

      final firestore.Task taskDocument = generateFirestoreTask(0);
      final Task task = generateTask(0);
      expect(taskDocument.attempts, 1);
      expect(task.attempts, 1);
      await service.reschedulePostsubmitBuildUsingCheckRunEvent(
        checkRunEvent,
        commit: generateCommit(0),
        task: task,
        target: generateTarget(0),
        taskDocument: taskDocument,
        datastore: datastore,
        firestoreService: mockFirestoreService,
      );
      expect(taskDocument.attempts, 2);
      expect(task.attempts, 2);
      expect(pubsub.messages.length, 1);
    });

    test('do not create postsubmit checkrun for bringup: true target', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));
      final Commit commit = generateCommit(0, repo: Config.packagesSlug.name);
      when(mockBuildBucketClient.listBuilders(any)).thenAnswer((_) async {
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 1',
              ),
            ),
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

      final bbv2.BatchRequest request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      expect(request.requests.single.scheduleBuild, isNotNull);

      final bbv2.ScheduleBuildRequest scheduleBuild = request.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'staging');
      expect(scheduleBuild.builder.builder, 'Linux 1');
      expect(
        scheduleBuild.notify.pubsubTopic,
        'projects/flutter-dashboard/topics/build-bucket-postsubmit',
      );
      final Map<String, dynamic> userData = UserData.decodeUserDataBytes(scheduleBuild.notify.userData);
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
        return bbv2.ListBuildersResponse(
          builders: [
            bbv2.BuilderItem(
              id: bbv2.BuilderID(
                bucket: 'prod',
                project: 'flutter',
                builder: 'Linux 2',
              ),
            ),
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
      final bbv2.BatchRequest request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      // Only existing builder: `Linux 2` is scheduled.
      expect(request.requests.length, 1);
      expect(request.requests.single.scheduleBuild, isNotNull);
      final bbv2.ScheduleBuildRequest scheduleBuild = request.requests.single.scheduleBuild;
      expect(scheduleBuild.builder.bucket, 'prod');
      expect(scheduleBuild.builder.builder, 'Linux 2');
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
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
    });

    test('reschedule using checkrun event', () async {
      when(mockGithubChecksUtil.createCheckRun(any, any, any, any))
          .thenAnswer((_) async => generateCheckRun(1, name: 'Linux 1'));

      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(1),
                    name: 'Linux',
                    status: bbv2.Status.ENDED_MASK,
                    tags: <bbv2.StringPair>[
                      bbv2.StringPair(key: 'buildset', value: 'pr/git/123'),
                      bbv2.StringPair(
                        key: 'cipd_version',
                        value: 'refs/heads/main',
                      ),
                      bbv2.StringPair(
                        key: 'github_link',
                        value: 'https://github.com/flutter/flutter/pull/1',
                      ),
                    ],
                    input: bbv2.Build_Input(
                      properties: bbv2.Struct(
                        fields: {'test': bbv2.Value(stringValue: 'abc')},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      });
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBbv2Build(Int64(1)));

      final pushMessage = generateCheckRunEvent(action: 'created', numberOfPullRequests: 1);
      final Map<String, dynamic> jsonMap = json.decode(pushMessage.data!);
      final Map<String, dynamic> jsonSubMap = json.decode(jsonMap['2']);
      final cocoon_checks.CheckRunEvent checkRunEvent = cocoon_checks.CheckRunEvent.fromJson(jsonSubMap);

      await service.reschedulePresubmitBuildUsingCheckRunEvent(
        checkRunEvent: checkRunEvent,
      );

      final List<dynamic> captured = verify(
        mockBuildBucketClient.scheduleBuild(
          captureAny,
        ),
      ).captured;
      expect(captured.length, 1);

      final bbv2.ScheduleBuildRequest scheduleBuildRequest = captured[0] as bbv2.ScheduleBuildRequest;

      final Map<String, dynamic> userData = UserData.decodeUserDataBytes(scheduleBuildRequest.notify.userData);

      expect(userData, <String, dynamic>{
        'check_run_id': 1,
        'commit_branch': 'master',
        'commit_sha': 'ec26c3e57ca3a959ca5aad62de7213c562f8c821',
        'repo_owner': 'flutter',
        'repo_name': 'flutter',
        'user_agent': 'flutter-cocoon',
      });

      final Map<String, dynamic> expectedProperties = {};
      expectedProperties['overrides'] = ['override: test'];
      final bbv2.Struct propertiesStruct = bbv2.Struct().createEmptyInstance();
      propertiesStruct.mergeFromProto3Json(expectedProperties);

      final Map<String, bbv2.Value> properties = scheduleBuildRequest.properties.fields;
      expect(properties['overrides'], propertiesStruct.fields['overrides']);
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
        pubsub: pubsub,
      );
    });

    test('Cancel builds when build list is empty', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[],
        );
      });
      await service.cancelBuilds(
        pullRequest: pullRequest,
        reason: 'new builds',
      );
      // This is okay, it is getting called twice when it runs cancel builds
      // because the call is no longer being short-circuited. It calls batch in
      // tryBuildsForPullRequest and it calls in the top level cancelBuilds
      // function.
      verify(mockBuildBucketClient.batch(any)).called(1);
    });

    test('Cancel builds that are scheduled', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(998),
                    name: 'Linux',
                    status: bbv2.Status.STARTED,
                  ),
                ],
              ),
            ),
          ],
        );
      });
      await service.cancelBuilds(
        pullRequest: pullRequest,
        reason: 'new builds',
      );

      final List<dynamic> captured = verify(
        mockBuildBucketClient.batch(
          captureAny,
        ),
      ).captured;

      final List<bbv2.BatchRequest_Request> capturedBatchRequests = [];
      for (dynamic cap in captured) {
        capturedBatchRequests.add((cap as bbv2.BatchRequest).requests.first);
      }

      final bbv2.SearchBuildsRequest searchBuildRequest =
          capturedBatchRequests.firstWhere((req) => req.hasSearchBuilds()).searchBuilds;
      final bbv2.CancelBuildRequest cancelBuildRequest =
          capturedBatchRequests.firstWhere((req) => req.hasCancelBuild()).cancelBuild;
      expect(searchBuildRequest, isNotNull);
      expect(cancelBuildRequest, isNotNull);

      expect(cancelBuildRequest.id, Int64(998));
      expect(cancelBuildRequest.summaryMarkdown, 'new builds');
    });
  });

  group('failedBuilds', () {
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
        pubsub: pubsub,
      );
    });

    test('Failed builds from an empty list', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[],
        );
      });
      final List<bbv2.Build?> result = await service.failedBuilds(pullRequest: pullRequest, targets: <Target>[]);
      expect(result, isEmpty);
    });

    test('Failed builds from a list of builds with failures', () async {
      when(mockBuildBucketClient.batch(any)).thenAnswer((_) async {
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  generateBbv2Build(
                    Int64(998),
                    name: 'Linux 1',
                    status: bbv2.Status.FAILURE,
                  ),
                ],
              ),
            ),
          ],
        );
      });
      final List<bbv2.Build?> result = await service.failedBuilds(
        pullRequest: pullRequest,
        targets: <Target>[generateTarget(1)],
      );
      expect(result, hasLength(1));
    });
  });

  group('rescheduleBuild', () {
    late bbv2.BuildsV2PubSub rescheduleBuild;

    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      mockBuildBucketClient = MockBuildBucketClient();
      pubsub = FakePubSub();
      service = LuciBuildService(
        config: config,
        cache: cache,
        buildBucketClient: mockBuildBucketClient,
        pubsub: pubsub,
      );
      rescheduleBuild = createBuild(
        Int64(1),
        status: bbv2.Status.FAILURE,
        builder: 'Linux Host Engine',
      );
    });

    test('Reschedule an existing build', () async {
      when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((_) async => generateBbv2Build(Int64(1)));
      final build = await service.rescheduleBuild(
        builderName: 'mybuild',
        build: rescheduleBuild.build,
        rescheduleAttempt: 2,
        userDataMap: {},
      );
      expect(build.id, Int64(1));
      expect(build.status, bbv2.Status.SUCCESS);
      final List<dynamic> captured = verify(mockBuildBucketClient.scheduleBuild(captureAny)).captured;
      expect(captured.length, 1);

      final bbv2.ScheduleBuildRequest scheduleBuildRequest = captured[0];
      expect(scheduleBuildRequest, isNotNull);
      final List<bbv2.StringPair> tags = scheduleBuildRequest.tags;
      final bbv2.StringPair attemptPair = tags.firstWhere((element) => element.key == 'current_attempt');
      expect(attemptPair.value, '2');
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
      mockGithubChecksUtil = MockGithubChecksUtil();
      mockFirestoreService = MockFirestoreService();
      mockBuildBucketClient = MockBuildBucketClient();
      when(
        mockGithubChecksUtil.createCheckRun(
          any,
          any,
          any,
          any,
          output: anyNamed('output'),
        ),
      ).thenAnswer((realInvocation) async => generateCheckRun(1));
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
        githubChecksUtil: mockGithubChecksUtil,
        pubsub: pubsub,
      );
      datastore = DatastoreService(config.db, 5);
    });

    test('Pass repo and properties correctly', () async {
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusFailed,
      );
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

      final bbv2.BatchRequest request = bbv2.BatchRequest().createEmptyInstance();
      request.mergeFromProto3Json(pubsub.messages.single);
      expect(request, isNotNull);
      final bbv2.ScheduleBuildRequest scheduleBuildRequest = request.requests.first.scheduleBuild;

      final Map<String, bbv2.Value> properties = scheduleBuildRequest.properties.fields;
      for (String key in Config.defaultProperties.keys) {
        expect(properties.containsKey(key), true);
      }
      expect(scheduleBuildRequest.priority, LuciBuildService.kRerunPriority);
      expect(scheduleBuildRequest.gitilesCommit.project, 'mirrors/engine');
      expect(
        scheduleBuildRequest.tags.firstWhere((tag) => tag.key == 'trigger_type').value,
        'auto_retry',
      );
      expect(rerunFlag, isTrue);
      expect(task.attempts, 2);
      expect(task.status, Task.statusInProgress);
    });

    test('Rerun a test failed builder', () async {
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusFailed,
      );
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
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusInfraFailure,
      );
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
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusInfraFailure,
      );
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
      firestoreTask = generateFirestoreTask(
        1,
        attempts: 1,
        status: firestore.Task.statusInfraFailure,
      );
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
      final List<dynamic> captured = verify(
        mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
      ).captured;
      expect(captured.length, 2);
      final BatchWriteRequest batchWriteRequest = captured[0] as BatchWriteRequest;
      expect(batchWriteRequest.writes!.length, 1);
      final Document insertedTaskDocument = batchWriteRequest.writes![0].update!;
      expect(insertedTaskDocument, firestoreTask);
      expect(firestoreTask!.status, firestore.Task.statusInProgress);
    });
  });
}
