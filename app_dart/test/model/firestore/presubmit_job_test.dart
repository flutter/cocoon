// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_job.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('PresubmitJobId', () {
    test('validates checkRunId', () {
      expect(
        () =>
            PresubmitJobId(checkRunId: 0, buildName: 'linux', attemptNumber: 1),
        throwsA(isA<RangeError>()),
      );
    });

    test('validates attemptNumber', () {
      expect(
        () =>
            PresubmitJobId(checkRunId: 1, buildName: 'linux', attemptNumber: 0),
        throwsA(isA<RangeError>()),
      );
    });

    test('generates correct documentId', () {
      final id = PresubmitJobId(
        checkRunId: 123,
        buildName: 'linux_test',
        attemptNumber: 2,
      );
      expect(id.documentId, '123_linux_test_2');
    });

    test('parses valid documentName', () {
      final id = PresubmitJobId.parse('123_linux_test_2');
      expect(id.checkRunId, 123);
      expect(id.buildName, 'linux_test');
      expect(id.attemptNumber, 2);
    });

    test('tryParse returns null for invalid format', () {
      expect(PresubmitJobId.tryParse('invalid'), isNull);
      expect(PresubmitJobId.tryParse('123_linux'), isNull);
    });
  });

  group('PresubmitJob', () {
    late FakeFirestoreService firestoreService;

    setUp(() {
      firestoreService = FakeFirestoreService();
    });

    test('init creates correct initial state', () {
      final job = PresubmitJob.init(
        buildName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      expect(job.buildName, 'linux');
      expect(job.checkRunId, 123);
      expect(job.creationTime, 1000);
      expect(job.attemptNumber, 1);
      expect(job.status, TaskStatus.waitingForBackfill);
      expect(job.buildNumber, isNull);
      expect(job.startTime, isNull);
      expect(job.endTime, isNull);
      expect(job.summary, isNull);
    });

    test('fromFirestore loads document correctly', () async {
      final job = PresubmitJob(
        checkRunId: 123,
        buildName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 1000,
        buildNumber: 456,
        startTime: 2000,
        endTime: 3000,
        summary: 'Success',
      );

      // Use the helper to get the correct document name
      final docName = PresubmitJob.documentNameFor(
        checkRunId: 123,
        buildName: 'linux',
        attemptNumber: 1,
      );

      // Manually ensuring the name is set for the fake service, usually done by `putDocument`
      // but we should verify the `PresubmitJob` object has it right via the factory or init.
      // Actually `PresubmitJob` constructor sets name.
      firestoreService.putDocument(Document(name: docName, fields: job.fields));

      final loadedJob = await PresubmitJob.fromFirestore(
        firestoreService,
        PresubmitJobId(checkRunId: 123, buildName: 'linux', attemptNumber: 1),
      );

      expect(loadedJob.checkRunId, 123);
      expect(loadedJob.buildName, 'linux');
      expect(loadedJob.status, TaskStatus.succeeded);
      expect(loadedJob.attemptNumber, 1);
      expect(loadedJob.creationTime, 1000);
      expect(loadedJob.buildNumber, 456);
      expect(loadedJob.startTime, 2000);
      expect(loadedJob.endTime, 3000);
      expect(loadedJob.summary, 'Success');
    });

    test('updateFromBuild updates fields', () {
      final job = PresubmitJob.init(
        buildName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      final build = bbv2.Build(
        number: 456,
        createTime: bbv2.Timestamp(seconds: Int64(2000)),
        startTime: bbv2.Timestamp(seconds: Int64(2100)),
        endTime: bbv2.Timestamp(seconds: Int64(2200)),
        status: bbv2.Status.SUCCESS,
      );

      job.updateFromBuild(build);

      expect(job.buildNumber, 456);
      expect(job.creationTime, 2000000); // seconds to millis
      expect(job.startTime, 2100000);
      expect(job.endTime, 2200000);
      expect(job.status, TaskStatus.succeeded);
    });

    test('updateFromBuild does not update status if already complete', () {
      final job = PresubmitJob.init(
        buildName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );
      job.status = TaskStatus.succeeded;

      final build = bbv2.Build(
        number: 456,
        createTime: bbv2.Timestamp(seconds: Int64(2000)),
        status: bbv2.Status.STARTED,
      );

      job.updateFromBuild(build);

      expect(job.status, TaskStatus.succeeded);
    });

    test('buildNumber setter updates fields', () {
      final job = PresubmitJob.init(
        buildName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      job.buildNumber = 789;
      expect(job.buildNumber, 789);

      job.buildNumber = null;
      expect(job.buildNumber, isNull);
    });
  });
}
