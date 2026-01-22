// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_guard.dart';

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('PresubmitGuardId', () {
    test('generates correct documentId', () {
      final id = PresubmitGuardId(
        slug: RepositorySlug('flutter', 'flutter'),
        pullRequestId: 123,
        checkRunId: 456,
        stage: CiStage.fusionEngineBuild,
      );
      expect(id.documentId, 'flutter_flutter_123_456_engine');
    });
  });

  group('PresubmitGuard', () {
    final slug = RepositorySlug('flutter', 'flutter');
    final checkRun = CheckRun.fromJson({
      'id': 456,
      'name': 'Merge Queue Guard',
      'head_sha': 'abc',
      'started_at': DateTime.now().toIso8601String(),
      'check_suite': {'id': 789},
    });

    test('init creates correct initial state', () {
      final guard = PresubmitGuard.init(
        slug: slug,
        pullRequestId: 123,
        checkRun: checkRun,
        stage: CiStage.fusionEngineBuild,
        commitSha: 'abc',
        creationTime: 1000,
        author: 'author',
        buildCount: 2,
      );

      expect(guard.slug, slug);
      expect(guard.pullRequestId, 123);
      expect(guard.checkRunId, 456);
      expect(guard.stage, CiStage.fusionEngineBuild);
      expect(guard.commitSha, 'abc');
      expect(guard.creationTime, 1000);
      expect(guard.author, 'author');
      expect(guard.remainingBuilds, 2);
      expect(guard.failedBuilds, 0);
      expect(guard.checkRun.id, 456);
    });

    test('fromDocument loads correct state', () {
      final guard = PresubmitGuard.init(
        slug: slug,
        pullRequestId: 123,
        checkRun: checkRun,
        stage: CiStage.fusionEngineBuild,
        commitSha: 'abc',
        creationTime: 1000,
        author: 'author',
        buildCount: 2,
      );
      guard.builds = {'linux': TaskStatus.succeeded};

      final doc = Document(name: guard.name, fields: guard.fields);

      final loadedGuard = PresubmitGuard.fromDocument(doc);

      expect(loadedGuard.slug, slug);
      expect(loadedGuard.pullRequestId, 123);
      expect(loadedGuard.checkRunId, 456);
      expect(loadedGuard.stage, CiStage.fusionEngineBuild);
      expect(loadedGuard.builds, {'linux': TaskStatus.succeeded});
      expect(loadedGuard.remainingBuilds, 2);
    });

    test('updates fields correctly', () {
      final guard = PresubmitGuard.init(
        slug: slug,
        pullRequestId: 123,
        checkRun: checkRun,
        stage: CiStage.fusionEngineBuild,
        commitSha: 'abc',
        creationTime: 1000,
        author: 'author',
        buildCount: 2,
      );

      guard.remainingBuilds = 1;
      guard.failedBuilds = 1;
      guard.builds = {'linux': TaskStatus.failed};

      expect(guard.remainingBuilds, 1);
      expect(guard.failedBuilds, 1);
      expect(guard.builds, {'linux': TaskStatus.failed});
    });

    test('parses properties from document name', () {
      // flutter_flutter_123_456_fusionEngineBuild
      final guard = PresubmitGuard(
        checkRun: checkRun,
        commitSha: 'abc',
        slug: slug,
        pullRequestId: 123,
        stage: CiStage.fusionEngineBuild,
        creationTime: 1000,
        author: 'author',
        remainingBuilds: 0,
        failedBuilds: 0,
      );

      expect(guard.slug, slug);
      expect(guard.pullRequestId, 123);
      expect(guard.checkRunId, 456);
      expect(guard.stage, CiStage.fusionEngineBuild);
    });
  });
}
