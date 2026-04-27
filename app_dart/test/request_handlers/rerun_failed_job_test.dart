// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/request_handlers/rerun_failed_job.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service/engine_artifacts.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/api_request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  late RerunFailedJob handler;
  late FakeConfig config;
  late MockLuciBuildService mockLuciBuildService;
  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late TestScheduler scheduler;

  setUp(() {
    final clientContext = FakeClientContext();
    firestore = FakeFirestoreService();
    config = FakeConfig();
    final authContext = FakeAuthenticatedContext(
      clientContext: clientContext,
      email: 'user@google.com',
    );
    tester = ApiRequestHandlerTester(context: authContext);
    mockLuciBuildService = MockLuciBuildService();
    scheduler = TestScheduler(
      config: config,
      firestore: firestore,
      bigQuery: MockBigQueryService(),
    );
    handler = RerunFailedJob(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(
        clientContext: clientContext,
      ),
      scheduler: scheduler,
      luciBuildService: mockLuciBuildService,
      firestore: firestore,
    );
  });

  test('Re-run successful failed job', () async {
    final checkRun = generateCheckRun(1, name: 'Linux A');
    final guard = generatePresubmitGuard(
      checkRun: checkRun,
      jobs: {'Linux A': TaskStatus.failed},
      remainingJobs: 0,
    );
    firestore.putDocument(guard);

    final pullRequest = generatePullRequest(headSha: guard.commitSha);
    scheduler.pullRequest = pullRequest;
    await PrCheckRuns.initializeDocument(
      firestoreService: firestore,
      pullRequest: pullRequest,
      checks: [
        generateCheckRun(guard.checkRunId, name: Config.kFlutterPresubmitsName),
      ],
    );

    final failedCheck = PresubmitJob(
      slug: Config.flutterSlug,
      checkRunId: 1,
      jobName: 'Linux A',
      status: TaskStatus.failed,
      attemptNumber: 1,
      creationTime: 1,
      buildNumber: 456,
    );
    firestore.putDocument(failedCheck);

    final targetA = generateTarget(1, name: 'Linux A');
    scheduler.targets = [targetA];
    scheduler.engineArtifacts = const EngineArtifacts.noFrameworkTests(
      reason: '',
    );

    when(
      mockLuciBuildService.reScheduleTryBuilds(
        targets: anyNamed('targets'),
        pullRequest: anyNamed('pullRequest'),
        engineArtifacts: anyNamed('engineArtifacts'),
        checkRunGuard: anyNamed('checkRunGuard'),
        stage: anyNamed('stage'),
      ),
    ).thenAnswer((_) async => []);

    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': pullRequest.number!,
      'job_name': 'Linux A',
    };

    final response = await tester.post(handler);
    expect(response.statusCode, HttpStatus.ok);

    verify(
      mockLuciBuildService.reScheduleTryBuilds(
        targets: argThat(containsPair(targetA, 2), named: 'targets'),
        pullRequest: anyNamed('pullRequest'),
        engineArtifacts: anyNamed('engineArtifacts'),
        checkRunGuard: anyNamed('checkRunGuard'),
        stage: anyNamed('stage'),
      ),
    ).called(1);

    final updatedGuard = PresubmitGuard.fromDocument(
      await firestore.getDocument(guard.name!),
    );
    expect(updatedGuard.jobs['Linux A'], TaskStatus.waitingForBackfill);
    expect(updatedGuard.remainingJobs, 1);
  });

  test('Re-run successful failed job with default owner/repo', () async {
    final checkRun = generateCheckRun(1, name: 'Linux A');
    final guard = generatePresubmitGuard(
      checkRun: checkRun,
      jobs: {'Linux A': TaskStatus.failed},
      remainingJobs: 0,
    );
    firestore.putDocument(guard);

    final pullRequest = generatePullRequest(headSha: guard.commitSha);
    scheduler.pullRequest = pullRequest;
    await PrCheckRuns.initializeDocument(
      firestoreService: firestore,
      pullRequest: pullRequest,
      checks: [
        generateCheckRun(guard.checkRunId, name: Config.kFlutterPresubmitsName),
      ],
    );

    final failedCheck = PresubmitJob(
      slug: Config.flutterSlug,
      checkRunId: 1,
      jobName: 'Linux A',
      status: TaskStatus.failed,
      attemptNumber: 1,
      creationTime: 1,
      buildNumber: 456,
    );
    firestore.putDocument(failedCheck);

    final targetA = generateTarget(1, name: 'Linux A');
    scheduler.targets = [targetA];
    scheduler.engineArtifacts = const EngineArtifacts.noFrameworkTests(
      reason: '',
    );

    when(
      mockLuciBuildService.reScheduleTryBuilds(
        targets: anyNamed('targets'),
        pullRequest: anyNamed('pullRequest'),
        engineArtifacts: anyNamed('engineArtifacts'),
        checkRunGuard: anyNamed('checkRunGuard'),
        stage: anyNamed('stage'),
      ),
    ).thenAnswer((_) async => []);

    tester.requestData = {'pr': pullRequest.number!, 'job_name': 'Linux A'};

    final response = await tester.post(handler);
    expect(response.statusCode, HttpStatus.ok);
  });

  test('Re-run fails for missing guard', () async {
    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': 123,
      'job_name': 'Linux A',
    };

    await expectLater(tester.post(handler), throwsA(isA<NotFoundException>()));
  });

  test('Re-run fails for PR mismatch', () async {
    final checkRun = generateCheckRun(1);
    final guard = generatePresubmitGuard(checkRun: checkRun);
    firestore.putDocument(guard);

    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': guard.prNum + 1,
      'job_name': 'Linux A',
    };

    await expectLater(tester.post(handler), throwsA(isA<NotFoundException>()));
  });

  test('Re-run fails for non-failed build', () async {
    final checkRun = generateCheckRun(1, name: 'Linux A');
    final guard = generatePresubmitGuard(checkRun: checkRun);
    firestore.putDocument(guard);

    final pullRequest = generatePullRequest(headSha: guard.commitSha);
    scheduler.pullRequest = pullRequest;
    await PrCheckRuns.initializeDocument(
      firestoreService: firestore,
      pullRequest: pullRequest,
      checks: [
        generateCheckRun(guard.checkRunId, name: Config.kFlutterPresubmitsName),
      ],
    );

    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': guard.prNum,
      'job_name': 'Linux A',
    };

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });
}

class TestScheduler extends FakeScheduler {
  TestScheduler({
    required super.config,
    required super.firestore,
    required super.bigQuery,
  });

  PullRequest? pullRequest;
  @override
  Future<PullRequest?> findPullRequestCached(
    int checkRunId,
    String checkRunName,
    RepositorySlug slug,
    String headSha,
    int checkSuiteId,
  ) async => pullRequest;

  List<Target>? targets;
  EngineArtifacts? engineArtifacts;
  @override
  Future<(List<Target>, EngineArtifacts)> getAllTargetsForPullRequest(
    RepositorySlug slug,
    PullRequest pullRequest,
  ) async => (targets!, engineArtifacts!);
}
