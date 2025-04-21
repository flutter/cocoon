// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/commit_task_ref.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to scheduling for a merge group.
///
/// Specifically:
/// - [LuciBuildService.scheduleMergeGroupBuilds]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestoreService;
  late FakePubSub pubSub;
  late FakeGerritService gerritService;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestoreService = FakeFirestoreService();
    pubSub = FakePubSub();
    gerritService = FakeGerritService();
    luci = LuciBuildService(
      config: FakeConfig(firestoreService: firestoreService),
      cache: CacheService(inMemory: true),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      pubsub: pubSub,
      gerritService: gerritService,
    );
  });

  test('schedules a prod build for a commit', () async {
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((realInvocation) async => generateCheckRun(1));

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

    final commit = generateFirestoreCommit(
      1,
      sha: 'abc1234',
      repo: 'flutter',
      branch: 'gh-readonly-queue/master/pr-1234-abcd',
    );
    await luci.scheduleMergeGroupBuilds(
      commit: CommitRef.fromFirestore(commit),
      targets: [
        generateTarget(1, slug: Config.flutterSlug, properties: {'os': 'abc'}),
        generateTarget(2, slug: Config.flutterSlug, properties: {'os': 'abc'}),
      ],
    );

    expect(pubSub.messages, hasLength(1));

    final List<bbv2.ScheduleBuildRequest> scheduledBuilds;
    {
      final batchRequest = bbv2.BatchRequest();
      batchRequest.mergeFromProto3Json(pubSub.messages.first);
      scheduledBuilds = [...batchRequest.requests.map((r) => r.scheduleBuild)];
    }
    expect(scheduledBuilds, [
      _isExpectedScheduleBuild(name: 'Linux 1'),
      _isExpectedScheduleBuild(name: 'Linux 2'),
    ]);
  });

  test('skips builders that are not found', () async {
    when(
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((realInvocation) async => generateCheckRun(1));

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

    final commit = generateFirestoreCommit(
      1,
      sha: 'abc1234',
      repo: 'flutter',
      branch: 'gh-readonly-queue/master/pr-1234-abcd',
    );
    await luci.scheduleMergeGroupBuilds(
      commit: CommitRef.fromFirestore(commit),
      targets: [
        generateTarget(1, slug: Config.flutterSlug, properties: {'os': 'abc'}),
        generateTarget(2, slug: Config.flutterSlug, properties: {'os': 'abc'}),
      ],
    );

    expect(pubSub.messages, hasLength(1));

    final List<bbv2.ScheduleBuildRequest> scheduledBuilds;
    {
      final batchRequest = bbv2.BatchRequest();
      batchRequest.mergeFromProto3Json(pubSub.messages.first);
      scheduledBuilds = [...batchRequest.requests.map((r) => r.scheduleBuild)];
    }
    expect(scheduledBuilds, [_isExpectedScheduleBuild(name: 'Linux 2')]);
  });
}

Matcher _isExpectedScheduleBuild({required String name}) {
  return isA<bbv2.ScheduleBuildRequest>()
      .having((r) => r.builder.bucket, 'builder.bucket', 'prod')
      .having((r) => r.builder.builder, 'builder.builder', name)
      .having(
        (r) => r.notify.pubsubTopic,
        'notify.pubsubTopic',
        p.posix.join(
          'projects',
          'flutter-dashboard',
          'topics',
          'build-bucket-presubmit',
        ),
      )
      .having(
        (r) => r.tags,
        'tags',
        contains(bbv2.StringPair(key: 'in_merge_queue', value: 'true')),
      )
      .having(
        (r) => PresubmitUserData.fromBytes(r.notify.userData),
        'notify.userData',
        PresubmitUserData(
          repoOwner: 'flutter',
          repoName: 'flutter',
          checkRunId: 1,
          commitSha: 'abc1234',
          commitBranch: 'gh-readonly-queue/master/pr-1234-abcd',
        ),
      )
      .having((r) => r.properties.fields, 'properties.fields', {
        'os': bbv2.Value(stringValue: 'abc'),
        'dependencies': bbv2.Value(listValue: bbv2.ListValue()),
        'bringup': bbv2.Value(boolValue: false),
        'git_branch': bbv2.Value(
          stringValue: 'gh-readonly-queue/master/pr-1234-abcd',
        ),
        'exe_cipd_version': bbv2.Value(stringValue: 'refs/heads/master'),
        'recipe': bbv2.Value(stringValue: 'devicelab/devicelab'),
        'is_fusion': bbv2.Value(stringValue: 'true'),
        'git_repo': bbv2.Value(stringValue: 'flutter'),
        'in_merge_queue': bbv2.Value(boolValue: true),
      })
      .having((r) => r.dimensions, 'dimensions', [
        isA<bbv2.RequestedDimension>()
            .having((d) => d.key, 'key', 'os')
            .having((d) => d.value, 'value', 'abc'),
      ]);
}
