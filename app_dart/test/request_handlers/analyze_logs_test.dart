// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handlers/analyze_logs.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/log_analyzer.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/request_handling/api_request_handler_tester.dart';

class MockLuciBuildService extends Mock implements LuciBuildService {
  @override
  Future<bbv2.Build> getBuildById(Int64? id, {bbv2.BuildMask? buildMask}) =>
      super.noSuchMethod(
            Invocation.method(#getBuildById, [id], {#buildMask: buildMask}),
            returnValue: Future.value(bbv2.Build()),
            returnValueForMissingStub: Future.value(bbv2.Build()),
          )
          as Future<bbv2.Build>;
}

void main() {
  useTestLoggerPerTest();

  late AnalyzeLogs handler;
  late FakeConfig config;
  late MockLuciBuildService mockLuciBuildService;
  late FakeFirestoreService firestore;
  late ApiRequestHandlerTester tester;
  late String analysisResult;

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
    analysisResult = 'Analysis result';

    handler = AnalyzeLogs(
      config: config,
      authenticationProvider: FakeDashboardAuthentication(
        clientContext: clientContext,
      ),
      luciBuildService: mockLuciBuildService,
      firestore: firestore,
      logAnalyzer: FakeLogAnalyzer(analysisResult),
    );
  });

  test('Analyze logs successfully', () async {
    final checkRun = generateCheckRun(1, name: 'Linux A');
    final guard = generatePresubmitGuard(
      checkRun: checkRun,
      jobs: {'Linux A': TaskStatus.failed},
      remainingJobs: 0,
    );
    firestore.putDocument(guard);

    final pullRequest = generatePullRequest(headSha: guard.commitSha);
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
      buildId: 123,
    );
    firestore.putDocument(failedCheck);

    final build = bbv2.Build.create()
      ..id = Int64(123)
      ..steps.addAll([
        bbv2.Step.create()
          ..name = 'step1'
          ..status = bbv2.Status.FAILURE
          ..logs.addAll([
            bbv2.Log.create()
              ..name = 'stdout'
              ..url = 'http://logs/stdout',
          ]),
      ])
      ..tags.addAll([
        bbv2.StringPair.create()
          ..key = 'github_link'
          ..value = 'http://github/pr/1',
      ]);

    when(
      mockLuciBuildService.getBuildById(
        Int64(123),
        buildMask: anyNamed('buildMask'),
      ),
    ).thenAnswer((_) async => build);

    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': pullRequest.number!,
      'build_id': 123,
    };

    final response = await tester.post(handler);
    expect(response.statusCode, HttpStatus.ok);

    final updatedCheck = PresubmitJob.fromDocument(
      await firestore.getDocument(failedCheck.name!),
    );
    expect(updatedCheck.logAnalysis, 'Analysis result');
  });

  test('Fails for missing guard', () async {
    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': 123,
      'build_id': 123,
    };

    await expectLater(tester.post(handler), throwsA(isA<NotFoundException>()));
  });

  test('Fails for job not belonging to guard', () async {
    final checkRun = generateCheckRun(1, name: 'Linux A');
    final guard = generatePresubmitGuard(
      checkRun: checkRun,
      jobs: {'Linux A': TaskStatus.failed},
      remainingJobs: 0,
    );
    firestore.putDocument(guard);

    final pullRequest = generatePullRequest(headSha: guard.commitSha);
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
      buildId: 456, // Different build ID
    );
    firestore.putDocument(failedCheck);

    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': pullRequest.number!,
      'build_id': 123, // Requested build ID
    };

    await expectLater(
      tester.post(handler),
      throwsA(isA<BadRequestException>()),
    );
  });

  test('Fails for missing logs', () async {
    final checkRun = generateCheckRun(1, name: 'Linux A');
    final guard = generatePresubmitGuard(
      checkRun: checkRun,
      jobs: {'Linux A': TaskStatus.failed},
      remainingJobs: 0,
    );
    firestore.putDocument(guard);

    final pullRequest = generatePullRequest(headSha: guard.commitSha);
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
      buildId: 123,
    );
    firestore.putDocument(failedCheck);

    final build = bbv2.Build.create()
      ..id = Int64(123)
      ..steps.addAll([
        bbv2.Step.create()
          ..name = 'step1'
          ..status = bbv2.Status.FAILURE,
      ]);

    when(
      mockLuciBuildService.getBuildById(
        Int64(123),
        buildMask: anyNamed('buildMask'),
      ),
    ).thenAnswer((_) async => build);

    tester.requestData = {
      'owner': 'flutter',
      'repo': 'flutter',
      'pr': pullRequest.number!,
      'build_id': 123,
    };

    await expectLater(tester.post(handler), throwsA(isA<NotFoundException>()));
  });
}
