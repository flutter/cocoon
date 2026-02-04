// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/firestore/presubmit_guard.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';

void main() {
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

    firestoreService.putDocuments([
      guard1,
      guard2,
      otherGuard,
    ]);

    final results = await firestoreService.queryPresubmitGuards(
      slug: slug,
      commitSha: commitSha,
    );

    expect(results.length, 2);
    expect(results.any((g) => g.stage == CiStage.fusionTests), isTrue);
    expect(results.any((g) => g.stage == CiStage.fusionEngineBuild), isTrue);
  });
}
