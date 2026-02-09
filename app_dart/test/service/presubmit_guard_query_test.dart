// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/service/firestore/unified_check_run.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  test('queryPresubmitGuards returns matching guards', () async {
    final slug = RepositorySlug('flutter', 'flutter');
    const commitSha = 'abc';

    final guard1 = generatePresubmitGuard(
      slug: slug,
      commitSha: commitSha,
      stage: CiStage.fusionTests,
    );
    final guard2 = generatePresubmitGuard(
      slug: slug,
      commitSha: commitSha,
      stage: CiStage.fusionEngineBuild,
    );
    final otherGuard = generatePresubmitGuard(
      slug: slug,
      pullRequestId: 456,
      commitSha: 'def',
      stage: CiStage.fusionTests,
    );

    firestoreService.putDocuments([guard1, guard2, otherGuard]);

    final results = await UnifiedCheckRun.getPresubmitGuardsForCommitSha(
      firestoreService: firestoreService,
      slug: slug,
      commitSha: commitSha,
    );

    expect(results.length, 2);
    expect(results.any((g) => g.stage == CiStage.fusionTests), isTrue);
    expect(results.any((g) => g.stage == CiStage.fusionEngineBuild), isTrue);
  });

  test(
    'queryPresubmitGuards returns empty list when no guards found',
    () async {
      final slug = RepositorySlug('flutter', 'flutter');
      final results = await UnifiedCheckRun.getPresubmitGuardsForCommitSha(
        firestoreService: firestoreService,
        slug: slug,
        commitSha: 'non-existent',
      );

      expect(results, isEmpty);
    },
  );
}
