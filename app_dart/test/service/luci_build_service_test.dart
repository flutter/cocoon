// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart'
    as firestore_commit;
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  late CacheService cache;
  late FakeConfig config;
  late MockBuildBucketClient mockBuildBucketClient;
  late LuciBuildService service;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakePubSub pubsub;

  setUp(() {
    mockGithubChecksUtil = MockGithubChecksUtil();
  });

  group('scheduleMergeGroupBuilds', () {
    late MockFirestoreService mockFirestoreService;
    firestore_commit.Commit? firestoreCommit;
    setUp(() {
      cache = CacheService(inMemory: true);
      config = FakeConfig();
      firestoreCommit = null;
      mockBuildBucketClient = MockBuildBucketClient();
      // ignore: discarded_futures
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

      when(
        // ignore: discarded_futures
        mockGithubChecksUtil.createCheckRun(
          any,
          any,
          any,
          any,
          output: anyNamed('output'),
        ),
      ).thenAnswer((realInvocation) async => generateCheckRun(1));

      mockFirestoreService = MockFirestoreService();
      when(
        // ignore: discarded_futures
        mockFirestoreService.batchWriteDocuments(captureAny, captureAny),
      ).thenAnswer((Invocation invocation) {
        return Future<BatchWriteResponse>.value(BatchWriteResponse());
      });
      // ignore: discarded_futures
      when(mockFirestoreService.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<firestore_commit.Commit>.value(firestoreCommit);
      });
      when(
        // ignore: discarded_futures
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
    });

    test('schedules prod builds for commit', () async {
      final commit = generateCommit(
        100,
        sha: 'abc1234',
        repo: 'flutter',
        branch: 'gh-readonly-queue/master/pr-1234-abcd',
      );
      final targets = <Target>[
        generateTarget(
          1,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
        generateTarget(
          2,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
      ];
      await service.scheduleMergeGroupBuilds(commit: commit, targets: targets);

      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 1',
        ),
      ).called(1);
      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 2',
        ),
      ).called(1);
      expect(pubsub.messages, hasLength(1));
      final batchRequest =
          bbv2.BatchRequest()..mergeFromProto3Json(pubsub.messages.first);
      expect(batchRequest.requests, hasLength(2));

      void validateSchedule(
        bbv2.ScheduleBuildRequest scheduleBuild,
        String builderName,
      ) {
        expect(scheduleBuild.builder.bucket, 'prod');
        expect(scheduleBuild.builder.builder, builderName);
        expect(
          scheduleBuild.notify.pubsubTopic,
          'projects/flutter-dashboard/topics/build-bucket-presubmit',
        );

        expect(
          scheduleBuild.tags,
          contains(bbv2.StringPair(key: 'in_merge_queue', value: 'true')),
        );

        final userData = PresubmitUserData.fromBytes(
          scheduleBuild.notify.userData,
        );
        expect(
          userData,
          PresubmitUserData(
            repoOwner: 'flutter',
            repoName: 'flutter',
            checkRunId: 1,
            commitSha: 'abc1234',
            commitBranch: 'gh-readonly-queue/master/pr-1234-abcd',
          ),
        );

        final properties = scheduleBuild.properties.fields;
        final dimensions = scheduleBuild.dimensions;

        expect(properties, <String, bbv2.Value>{
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
        });
        expect(dimensions.length, 1);
        expect(dimensions[0].key, 'os');
        expect(dimensions[0].value, 'abc');
      }

      validateSchedule(batchRequest.requests[0].scheduleBuild, 'Linux 1');
      validateSchedule(batchRequest.requests[1].scheduleBuild, 'Linux 2');
    });

    test('skips unmatched builders', () async {
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
      final commit = generateCommit(
        100,
        sha: 'abc1234',
        repo: 'flutter',
        branch: 'gh-readonly-queue/master/pr-1234-abcd',
      );
      final targets = <Target>[
        generateTarget(
          1,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
        generateTarget(
          2,
          properties: <String, String>{'os': 'abc'},
          slug: RepositorySlug('flutter', 'flutter'),
        ),
      ];
      await service.scheduleMergeGroupBuilds(commit: commit, targets: targets);

      verify(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 1',
        ),
      ).called(1);
      verifyNever(
        mockGithubChecksUtil.createCheckRun(
          any,
          RepositorySlug('flutter', 'flutter'),
          'abc1234',
          'Linux 2',
        ),
      );
      expect(pubsub.messages, hasLength(1));
      final batchRequest =
          bbv2.BatchRequest()..mergeFromProto3Json(pubsub.messages.first);
      expect(batchRequest.requests, hasLength(1));
    });
  });
}
