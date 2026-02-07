// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

/// Tests [LuciBuildService] public API related to `dart-internal` builds.
///
/// Specifically:
/// - [LuciBuildService.rerunDartInternalReleaseBuilder]
void main() {
  useTestLoggerPerTest();

  // System under test:
  late LuciBuildService luci;

  // Dependencies (mocked/faked if necessary):
  late MockBuildBucketClient mockBuildBucketClient;
  late FakeFirestoreService firestore;

  late fs.Task task;

  setUp(() {
    mockBuildBucketClient = MockBuildBucketClient();

    firestore = FakeFirestoreService();
    task = generateFirestoreTask(
      0,
      name: 'Linux flutter_release_builder',
      status: TaskStatus.failed,
      buildNumber: 123,
    );
    firestore.putDocument(task);

    luci = LuciBuildService(
      cache: CacheService(inMemory: true),
      config: FakeConfig(),
      gerritService: FakeGerritService(),
      buildBucketClient: mockBuildBucketClient,
      githubChecksUtil: MockGithubChecksUtil(),
      pubsub: FakePubSub(),
      firestore: firestore,
    );
  });

  test('must find a build or fails', () async {
    when(mockBuildBucketClient.getBuild(any)).thenAnswer((i) async {
      final [bbv2.GetBuildRequest request] = i.positionalArguments;
      expect(request.buildNumber, 123);
      expect(
        request.builder,
        isA<bbv2.BuilderID>()
            .having((b) => b.project, 'project', 'dart-internal')
            .having((b) => b.bucket, 'bucket', 'flutter')
            .having(
              (b) => b.builder,
              'builder',
              'Linux flutter_release_builder',
            ),
      );
      throw const BuildBucketException(404, 'Not Found');
    });

    await expectLater(
      luci.rerunDartInternalReleaseBuilder(
        commit: CommitRef(
          sha: 'abcdef',
          branch: 'flutter-0.42-candidate.0',
          slug: Config.flutterSlug,
        ),
        task: task,
      ),
      completion(isFalse),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(
          logThat(
            message: contains('No build found for 123'),
            severity: atLeastError,
          ),
        ),
      ),
    );
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(TaskStatus.failed).hasCurrentAttempt(1),
      ]),
    );
  });

  test('on missing associated sub-builds warns+does a full build', () async {
    when(mockBuildBucketClient.getBuild(any)).thenAnswer((_) async {
      return bbv2.Build(
        id: Int64(1001),
        input: bbv2.Build_Input(
          gitilesCommit: bbv2.GitilesCommit(
            project: 'mirrors/flutter',
            host: 'flutter.googlesource.com',
            ref: 'refs/heads/flutter-0.42-candidate.0',
            id: 'abcdef',
          ),
        ),
      );
    });

    when(mockBuildBucketClient.searchBuilds(any)).thenAnswer((i) async {
      final [bbv2.SearchBuildsRequest request] = i.positionalArguments;
      expect(request.predicate.childOf, Int64(1001));
      expect(
        request.mask.inputProperties,
        containsAll([
          bbv2.StructMask(path: const ['build', 'name']),
          bbv2.StructMask(path: const ['config_name']),
        ]),
      );
      return bbv2.SearchBuildsResponse(builds: []);
    });

    when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((i) async {
      final [bbv2.ScheduleBuildRequest request] = i.positionalArguments;
      expect(
        request.builder,
        isA<bbv2.BuilderID>()
            .having((b) => b.project, 'project', 'dart-internal')
            .having((b) => b.bucket, 'bucket', 'flutter')
            .having(
              (b) => b.builder,
              'builder',
              'Linux flutter_release_builder',
            ),
      );
      expect(
        request.hasExe(),
        isFalse,
        reason: 'Release recipes always run from ToT',
      );
      expect(
        request.gitilesCommit,
        bbv2.GitilesCommit(
          project: 'mirrors/flutter',
          host: 'flutter.googlesource.com',
          ref: 'refs/heads/flutter-0.42-candidate.0',
          id: 'abcdef',
        ),
      );
      expect(request.hasNotify(), isFalse);
      expect(request.properties, bbv2.Struct(fields: {}));
      expect(request.priority, LuciBuildService.kRerunPriority);
      return bbv2.Build();
    });

    await expectLater(
      luci.rerunDartInternalReleaseBuilder(
        commit: CommitRef(
          sha: 'abcdef',
          branch: 'flutter-0.42-candidate.0',
          slug: Config.flutterSlug,
        ),
        task: task,
      ),
      completion(isTrue),
    );

    expect(
      log,
      bufferedLoggerOf(
        contains(
          logThat(
            message: stringContainsInOrder([
              'No builds found for',
              'A full rebuild will be triggered',
            ]),
            severity: atMostWarning,
          ),
        ),
      ),
    );
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(TaskStatus.failed).hasCurrentAttempt(1),
        isTask.hasStatus(TaskStatus.inProgress).hasCurrentAttempt(2),
      ]),
    );
  });

  test('reruns failed builds by config_name', () async {
    when(mockBuildBucketClient.getBuild(any)).thenAnswer((_) async {
      return bbv2.Build(
        id: Int64(1001),
        input: bbv2.Build_Input(
          gitilesCommit: bbv2.GitilesCommit(
            project: 'mirrors/flutter',
            host: 'flutter.googlesource.com',
            ref: 'refs/heads/flutter-0.42-candidate.0',
            id: 'abcdef',
          ),
        ),
      );
    });

    when(mockBuildBucketClient.searchBuilds(any)).thenAnswer((i) async {
      return bbv2.SearchBuildsResponse(
        builds: [
          bbv2.Build(
            status: bbv2.Status.SUCCESS,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                fields: {'config_name': bbv2.Value(stringValue: 'engine_1')},
              ),
            ),
          ),
          bbv2.Build(
            status: bbv2.Status.FAILURE,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                fields: {'config_name': bbv2.Value(stringValue: 'engine_2')},
              ),
            ),
          ),
          bbv2.Build(
            status: bbv2.Status.INFRA_FAILURE,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                fields: {'config_name': bbv2.Value(stringValue: 'engine_3')},
              ),
            ),
          ),
          bbv2.Build(
            status: bbv2.Status.CANCELED,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                fields: {'config_name': bbv2.Value(stringValue: 'engine_4')},
              ),
            ),
          ),
        ],
      );
    });

    when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((i) async {
      final [bbv2.ScheduleBuildRequest request] = i.positionalArguments;
      expect(
        request.builder,
        isA<bbv2.BuilderID>()
            .having((b) => b.project, 'project', 'dart-internal')
            .having((b) => b.bucket, 'bucket', 'flutter')
            .having(
              (b) => b.builder,
              'builder',
              'Linux flutter_release_builder',
            ),
      );
      expect(
        request.hasExe(),
        isFalse,
        reason: 'Release recipes always run from ToT',
      );
      expect(
        request.gitilesCommit,
        bbv2.GitilesCommit(
          project: 'mirrors/flutter',
          host: 'flutter.googlesource.com',
          ref: 'refs/heads/flutter-0.42-candidate.0',
          id: 'abcdef',
        ),
      );
      expect(request.hasNotify(), isFalse);
      expect(
        request.properties,
        bbv2.Struct(
          fields: {
            'retry_override_list': bbv2.Value(
              stringValue: 'engine_2 engine_3 engine_4',
            ),
          },
        ),
      );
      expect(request.priority, LuciBuildService.kRerunPriority);
      return bbv2.Build();
    });

    await expectLater(
      luci.rerunDartInternalReleaseBuilder(
        commit: CommitRef(
          sha: 'abcdef',
          branch: 'flutter-0.42-candidate.0',
          slug: Config.flutterSlug,
        ),
        task: task,
      ),
      completion(isTrue),
    );

    expect(log, hasNoErrorsOrHigher);
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(TaskStatus.failed).hasCurrentAttempt(1),
        isTask.hasStatus(TaskStatus.inProgress).hasCurrentAttempt(2),
      ]),
    );
  });

  test('reruns entire build', () async {
    when(mockBuildBucketClient.getBuild(any)).thenAnswer((_) async {
      return bbv2.Build(
        id: Int64(1001),
        input: bbv2.Build_Input(
          gitilesCommit: bbv2.GitilesCommit(
            project: 'mirrors/flutter',
            host: 'flutter.googlesource.com',
            ref: 'refs/heads/flutter-0.42-candidate.0',
            id: 'abcdef',
          ),
        ),
      );
    });

    when(mockBuildBucketClient.searchBuilds(any)).thenAnswer((i) async {
      return bbv2.SearchBuildsResponse(
        builds: [
          bbv2.Build(
            status: bbv2.Status.SUCCESS,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                fields: {'config_name': bbv2.Value(stringValue: 'engine_1')},
              ),
            ),
          ),
        ],
      );
    });

    when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((i) async {
      final [bbv2.ScheduleBuildRequest request] = i.positionalArguments;
      expect(
        request.builder,
        isA<bbv2.BuilderID>()
            .having((b) => b.project, 'project', 'dart-internal')
            .having((b) => b.bucket, 'bucket', 'flutter')
            .having(
              (b) => b.builder,
              'builder',
              'Linux flutter_release_builder',
            ),
      );
      expect(
        request.hasExe(),
        isFalse,
        reason: 'Release recipes always run from ToT',
      );
      expect(
        request.gitilesCommit,
        bbv2.GitilesCommit(
          project: 'mirrors/flutter',
          host: 'flutter.googlesource.com',
          ref: 'refs/heads/flutter-0.42-candidate.0',
          id: 'abcdef',
        ),
      );
      expect(request.hasNotify(), isFalse);
      expect(request.properties, bbv2.Struct(fields: {}));
      expect(request.priority, LuciBuildService.kRerunPriority);
      return bbv2.Build();
    });

    await expectLater(
      luci.rerunDartInternalReleaseBuilder(
        commit: CommitRef(
          sha: 'abcdef',
          branch: 'flutter-0.42-candidate.0',
          slug: Config.flutterSlug,
        ),
        task: task,
      ),
      completion(isTrue),
    );

    expect(log, hasNoErrorsOrHigher);
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(TaskStatus.failed).hasCurrentAttempt(1),
        isTask.hasStatus(TaskStatus.inProgress).hasCurrentAttempt(2),
      ]),
    );
  });

  test('fallsback to re-run all if non-engine build failed', () async {
    when(mockBuildBucketClient.getBuild(any)).thenAnswer((_) async {
      return bbv2.Build(
        id: Int64(1001),
        input: bbv2.Build_Input(
          gitilesCommit: bbv2.GitilesCommit(
            project: 'mirrors/flutter',
            host: 'flutter.googlesource.com',
            ref: 'refs/heads/flutter-0.42-candidate.0',
            id: 'abcdef',
          ),
        ),
      );
    });

    when(mockBuildBucketClient.searchBuilds(any)).thenAnswer((i) async {
      return bbv2.SearchBuildsResponse(
        builds: [
          bbv2.Build(
            status: bbv2.Status.SUCCESS,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                fields: {'config_name': bbv2.Value(stringValue: 'engine_1')},
              ),
            ),
          ),
          bbv2.Build(
            status: bbv2.Status.FAILURE,
            input: bbv2.Build_Input(
              properties: bbv2.Struct(
                // Intentionally no config_name
              ),
            ),
          ),
        ],
      );
    });

    when(mockBuildBucketClient.scheduleBuild(any)).thenAnswer((i) async {
      final [bbv2.ScheduleBuildRequest request] = i.positionalArguments;
      expect(
        request.builder,
        isA<bbv2.BuilderID>()
            .having((b) => b.project, 'project', 'dart-internal')
            .having((b) => b.bucket, 'bucket', 'flutter')
            .having(
              (b) => b.builder,
              'builder',
              'Linux flutter_release_builder',
            ),
      );
      expect(
        request.hasExe(),
        isFalse,
        reason: 'Release recipes always run from ToT',
      );
      expect(
        request.gitilesCommit,
        bbv2.GitilesCommit(
          project: 'mirrors/flutter',
          host: 'flutter.googlesource.com',
          ref: 'refs/heads/flutter-0.42-candidate.0',
          id: 'abcdef',
        ),
      );
      expect(request.hasNotify(), isFalse);
      expect(request.properties, bbv2.Struct(fields: {}));
      expect(request.priority, LuciBuildService.kRerunPriority);
      return bbv2.Build();
    });

    await expectLater(
      luci.rerunDartInternalReleaseBuilder(
        commit: CommitRef(
          sha: 'abcdef',
          branch: 'flutter-0.42-candidate.0',
          slug: Config.flutterSlug,
        ),
        task: task,
      ),
      completion(isTrue),
    );

    expect(log, hasNoErrorsOrHigher);
    expect(
      firestore,
      existsInStorage(fs.Task.metadata, [
        isTask.hasStatus(TaskStatus.failed).hasCurrentAttempt(1),
        isTask.hasStatus(TaskStatus.inProgress).hasCurrentAttempt(2),
      ]),
    );
  });
}
