// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/service/luci_build_service/commit_task_ref.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/fake_pubsub.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.mocks.dart';

/// Tests [LuciBuildService] public API related to rerunning TOT test failures.
///
/// Specifically:
/// - [LuciBuildService.rerunBuilder]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late FakeFirestoreService firestore;
  late FakePubSub pubSub;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    firestore = FakeFirestoreService();
    pubSub = FakePubSub();

    luci = LuciBuildService(
      cache: CacheService(inMemory: true),
      config: FakeConfig(maxLuciTaskRetriesValue: 2),
      gerritService: FakeGerritService(),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      pubsub: pubSub,
      firestore: firestore,
    );
  });

  test('can rerun a test failed builder', () async {
    final fsCommit = generateFirestoreCommit(1);

    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux foo',
      commitSha: fsCommit.sha,
      status: fs.Task.statusFailed,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    await expectLater(
      luci.rerunBuilder(
        commit: CommitRef.fromFirestore(fsCommit),
        task: fsTask,
        target: generateTarget(1, name: 'Linux foo'),
        tags: [],
      ),
      completion(isTrue),
    );

    expect(pubSub.messages, hasLength(1));

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(scheduleBuild.priority, LuciBuildService.kRerunPriority);
    expect(
      scheduleBuild.properties.fields.keys,
      containsAll(Config.defaultProperties.keys),
    );
    expect(scheduleBuild.gitilesCommit.project, 'mirrors/flutter');

    expect(
      scheduleBuild.tags,
      allOf(
        contains(bbv2.StringPair(key: 'current_attempt', value: '2')),
        contains(bbv2.StringPair(key: 'trigger_type', value: 'auto_retry')),
      ),
    );

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasCurrentAttempt(1).hasStatus(fs.Task.statusFailed),
        isTask.hasCurrentAttempt(2).hasStatus(fs.Task.statusInProgress),
      ]),
    );
  });

  test('can rerun an infra failed builder', () async {
    final fsCommit = generateFirestoreCommit(1);

    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux foo',
      commitSha: fsCommit.sha,
      status: fs.Task.statusInfraFailure,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    await expectLater(
      luci.rerunBuilder(
        commit: CommitRef.fromFirestore(fsCommit),
        task: fsTask,
        target: generateTarget(1, name: 'Linux foo'),
        tags: [],
      ),
      completion(isTrue),
    );

    expect(pubSub.messages, hasLength(1));

    final bbv2.ScheduleBuildRequest scheduleBuild;
    {
      final batchRequest = bbv2.BatchRequest().createEmptyInstance();
      batchRequest.mergeFromProto3Json(pubSub.messages.single);

      expect(batchRequest.requests, hasLength(1));
      scheduleBuild = batchRequest.requests.single.scheduleBuild;
    }

    expect(scheduleBuild.priority, LuciBuildService.kRerunPriority);
    expect(
      scheduleBuild.properties.fields.keys,
      containsAll(Config.defaultProperties.keys),
    );
    expect(scheduleBuild.gitilesCommit.project, 'mirrors/flutter');

    expect(
      scheduleBuild.tags,
      allOf(
        contains(bbv2.StringPair(key: 'current_attempt', value: '2')),
        contains(bbv2.StringPair(key: 'trigger_type', value: 'auto_retry')),
      ),
    );

    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasCurrentAttempt(1).hasStatus(fs.Task.statusInfraFailure),
        isTask.hasCurrentAttempt(2).hasStatus(fs.Task.statusInProgress),
      ]),
    );
  });

  test('skips rerunning when an exception occurs', () async {
    final fsCommit = generateFirestoreCommit(1);

    final fsTask = generateFirestoreTask(
      1,
      name: 'Linux foo',
      commitSha: fsCommit.sha,
      status: fs.Task.statusFailed,
    );
    firestore.putDocument(fsCommit);
    firestore.putDocument(fsTask);

    firestore.failOnWriteCollection(fs.Task.metadata.collectionId);

    await expectLater(
      luci.rerunBuilder(
        commit: CommitRef.fromFirestore(fsCommit),
        task: fsTask,
        target: generateTarget(1, name: 'Linux foo'),
        tags: [],
      ),
      completion(isFalse),
    );

    expect(pubSub.messages, isEmpty);
  });
}
