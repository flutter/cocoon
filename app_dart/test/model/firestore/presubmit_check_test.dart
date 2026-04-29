// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_job.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('PresubmitJobId', () {
    final slug = RepositorySlug('flutter', 'flutter');

    test('validates checkRunId', () {
      expect(
        () => PresubmitJobId(
          slug: slug,
          checkRunId: 0,
          jobName: 'linux',
          attemptNumber: 1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('validates attemptNumber', () {
      expect(
        () => PresubmitJobId(
          slug: slug,
          checkRunId: 1,
          jobName: 'linux',
          attemptNumber: 0,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('generates correct documentId', () {
      final id = PresubmitJobId(
        slug: slug,
        checkRunId: 123,
        jobName: 'linux_test',
        attemptNumber: 2,
      );
      expect(id.documentId, 'flutter_flutter_123_linux_test_2');
    });

    test('parses valid documentName', () {
      final id = PresubmitJobId.parse('flutter_flutter_123_linux_test_2');
      expect(id.slug, slug);
      expect(id.checkRunId, 123);
      expect(id.jobName, 'linux_test');
      expect(id.attemptNumber, 2);
    });

    test('tryParse returns null for invalid format', () {
      expect(PresubmitJobId.tryParse('invalid'), isNull);
      expect(PresubmitJobId.tryParse('flutter_flutter_123_linux'), isNull);
    });

    test('generates correct documentId with different slug', () {
      final cocoonSlug = RepositorySlug('flutter', 'cocoon');
      final id = PresubmitJobId(
        slug: cocoonSlug,
        checkRunId: 123,
        jobName: 'linux_test',
        attemptNumber: 2,
      );
      expect(id.documentId, 'flutter_cocoon_123_linux_test_2');
    });
  });

  group('PresubmitJob', () {
    late FakeFirestoreService firestoreService;
    final slug = RepositorySlug('flutter', 'flutter');

    setUp(() {
      firestoreService = FakeFirestoreService();
    });

    test('init creates correct initial state', () {
      final check = PresubmitJob.init(
        slug: slug,
        jobName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      expect(check.slug, slug);
      expect(check.jobName, 'linux');
      expect(check.checkRunId, 123);
      expect(check.creationTime, 1000);
      expect(check.attemptNumber, 1);
      expect(check.status, TaskStatus.waitingForBackfill);
      expect(check.buildNumber, isNull);
      expect(check.buildId, isNull);
      expect(check.startTime, isNull);
      expect(check.endTime, isNull);
      expect(check.summary, isNull);
    });

    test('constructor stores slug in fields', () {
      final check = PresubmitJob(
        slug: slug,
        checkRunId: 123,
        jobName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 1000,
      );

      expect(check.slug, slug);
      expect(
        check.fields[PresubmitJob.fieldSlug]!.stringValue,
        'flutter/flutter',
      );
    });

    test('fromFirestore loads document correctly', () async {
      final check = PresubmitJob(
        slug: slug,
        checkRunId: 123,
        jobName: 'linux',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: 1000,
        buildNumber: 456,
        buildId: 789,
        startTime: 2000,
        endTime: 3000,
        summary: 'Success',
      );

      // Use the helper to get the correct document name
      final docName = PresubmitJob.documentNameFor(
        slug: slug,
        checkRunId: 123,
        jobName: 'linux',
        attemptNumber: 1,
      );

      // Manually ensuring the name is set for the fake service, usually done by `putDocument`
      // but we should verify the `PresubmitJob` object has it right via the factory or init.
      // Actually `PresubmitJob` constructor sets name.
      firestoreService.putDocument(
        Document(name: docName, fields: check.fields),
      );

      final loadedCheck = await PresubmitJob.fromFirestore(
        firestoreService,
        PresubmitJobId(
          slug: slug,
          checkRunId: 123,
          jobName: 'linux',
          attemptNumber: 1,
        ),
      );

      expect(loadedCheck.slug, slug);
      expect(loadedCheck.checkRunId, 123);
      expect(loadedCheck.jobName, 'linux');
      expect(loadedCheck.status, TaskStatus.succeeded);
      expect(loadedCheck.attemptNumber, 1);
      expect(loadedCheck.creationTime, 1000);
      expect(loadedCheck.buildNumber, 456);
      expect(loadedCheck.buildId, 789);
      expect(loadedCheck.startTime, 2000);
      expect(loadedCheck.endTime, 3000);
      expect(loadedCheck.summary, 'Success');
    });

    test('updateFromBuild updates fields', () {
      final check = PresubmitJob.init(
        slug: slug,
        jobName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      final build = bbv2.Build(
        id: Int64(789),
        number: 456,
        createTime: bbv2.Timestamp(seconds: Int64(2000)),
        startTime: bbv2.Timestamp(seconds: Int64(2100)),
        endTime: bbv2.Timestamp(seconds: Int64(2200)),
        status: bbv2.Status.SUCCESS,
      );

      check.updateFromBuild(build);

      expect(check.buildNumber, 456);
      expect(check.buildId, 789);
      expect(check.creationTime, 2000000); // seconds to millis
      expect(check.startTime, 2100000);
      expect(check.endTime, 2200000);
      expect(check.status, TaskStatus.succeeded);
    });

    test('updateFromBuild does not update status if already complete', () {
      final check = PresubmitJob.init(
        slug: slug,
        jobName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );
      check.status = TaskStatus.succeeded;

      final build = bbv2.Build(
        number: 456,
        createTime: bbv2.Timestamp(seconds: Int64(2000)),
        status: bbv2.Status.STARTED,
      );

      check.updateFromBuild(build);

      expect(check.status, TaskStatus.succeeded);
    });

    test('buildNumber setter updates fields', () {
      final check = PresubmitJob.init(
        slug: slug,
        jobName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      check.buildNumber = 789;
      expect(check.buildNumber, 789);

      check.buildNumber = null;
      expect(check.buildNumber, isNull);
    });

    test('buildId setter updates fields', () {
      final check = PresubmitJob.init(
        slug: slug,
        jobName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      check.buildId = 789;
      expect(check.buildId, 789);

      check.buildId = null;
      expect(check.buildId, isNull);
    });
  });
}
