// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_check.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../../src/service/fake_firestore_service.dart';

void main() {
  useTestLoggerPerTest();

  group('PresubmitCheckId', () {
    test('validates checkRunId', () {
      expect(
        () => PresubmitCheckId(
          checkRunId: 0,
          buildName: 'linux',
          attemptNumber: 1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('validates attemptNumber', () {
      expect(
        () => PresubmitCheckId(
          checkRunId: 1,
          buildName: 'linux',
          attemptNumber: 0,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('generates correct documentId', () {
      final id = PresubmitCheckId(
        checkRunId: 123,
        buildName: 'linux_test',
        attemptNumber: 2,
      );
      expect(id.documentId, '123_linux_test_2');
    });

    test('parses valid documentName', () {
      final id = PresubmitCheckId.parse('123_linux_test_2');
      expect(id.checkRunId, 123);
      expect(id.buildName, 'linux_test');
      expect(id.attemptNumber, 2);
    });

    test('tryParse returns null for invalid format', () {
      expect(PresubmitCheckId.tryParse('invalid'), isNull);
      expect(PresubmitCheckId.tryParse('123_linux'), isNull);
    });
  });

  group('PresubmitCheck', () {
    late FakeFirestoreService firestoreService;

    setUp(() {
      firestoreService = FakeFirestoreService();
    });

    test('init creates correct initial state', () {
      final check = PresubmitCheck.init(
        buildName: 'linux',
        checkRunId: 123,
        creationTime: 1000,
      );

      expect(check.buildName, 'linux');
      expect(check.checkRunId, 123);
      expect(check.creationTime, 1000);
      expect(check.attemptNumber, 1);
      expect(check.status, TaskStatus.waitingForBackfill);
      expect(check.buildNumber, isNull);
      expect(check.startTime, isNull);
      expect(check.endTime, isNull);
      expect(check.summary, isNull);
    });

    test('fromFirestore loads document correctly', () async {
      final check = PresubmitCheck(
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
      final docName = PresubmitCheck.documentNameFor(
        checkRunId: 123,
        buildName: 'linux',
        attemptNumber: 1,
      );

      // Manually ensuring the name is set for the fake service, usually done by `putDocument`
      // but we should verify the `PresubmitCheck` object has it right via the factory or init.
      // Actually `PresubmitCheck` constructor sets name.
      firestoreService.putDocument(
        Document(name: docName, fields: check.fields),
      );

      final loadedCheck = await PresubmitCheck.fromFirestore(
        firestoreService,
        PresubmitCheckId(checkRunId: 123, buildName: 'linux', attemptNumber: 1),
      );

      expect(loadedCheck.checkRunId, 123);
      expect(loadedCheck.buildName, 'linux');
      expect(loadedCheck.status, TaskStatus.succeeded);
      expect(loadedCheck.attemptNumber, 1);
      expect(loadedCheck.creationTime, 1000);
      expect(loadedCheck.buildNumber, 456);
      expect(loadedCheck.startTime, 2000);
      expect(loadedCheck.endTime, 3000);
      expect(loadedCheck.summary, 'Success');
    });

    test('updateFromBuild updates fields', () {
      final check = PresubmitCheck.init(
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

      check.updateFromBuild(build);

      expect(check.buildNumber, 456);
      expect(check.creationTime, 2000000); // seconds to millis
      expect(check.startTime, 2100000);
      expect(check.endTime, 2200000);
      expect(check.status, TaskStatus.succeeded);
    });

    test('updateFromBuild does not update status if already complete', () {
      final check = PresubmitCheck.init(
        buildName: 'linux',
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
  });
}
