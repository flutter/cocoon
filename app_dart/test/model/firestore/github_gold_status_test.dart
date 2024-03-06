// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/github_gold_status_update.dart';
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group('GithubGoldStatus.fromFirestore', () {
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    test('generates githubGoldStatus correctly', () async {
      final GithubGoldStatus githubGoldStatus = generateFirestoreGithubGoldStatus(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<GithubGoldStatus>.value(
          githubGoldStatus,
        );
      });
      final GithubGoldStatus resultedGithubGoldStatus = await GithubGoldStatus.fromFirestore(
        firestoreService: mockFirestoreService,
        documentName: 'test',
      );
      expect(resultedGithubGoldStatus.name, githubGoldStatus.name);
      expect(resultedGithubGoldStatus.fields, githubGoldStatus.fields);
    });
  });

  test('creates github gold status document correctly from data model', () async {
    final GithubGoldStatusUpdate githubGoldStatusUpdate = GithubGoldStatusUpdate(
      head: 'sha',
      pr: 1,
      status: GithubGoldStatusUpdate.statusCompleted,
      updates: 2,
      description: '',
      repository: 'flutter/flutter',
    );
    final GithubGoldStatus commitDocument = githubGoldStatusToDocument(githubGoldStatusUpdate);
    expect(
      commitDocument.name,
      '$kDatabase/documents/$kGithubGoldStatusCollectionId/${githubGoldStatusUpdate.repository!.replaceAll('/', '_')}_${githubGoldStatusUpdate.pr}',
    );
    expect(commitDocument.fields![kGithubGoldStatusHeadField]!.stringValue, githubGoldStatusUpdate.head);
    expect(commitDocument.fields![kGithubGoldStatusPrNumberField]!.integerValue, githubGoldStatusUpdate.pr.toString());
    expect(commitDocument.fields![kGithubGoldStatusStatusField]!.stringValue, githubGoldStatusUpdate.status);
    expect(
      commitDocument.fields![kGithubGoldStatusUpdatesField]!.integerValue,
      githubGoldStatusUpdate.updates.toString(),
    );
    expect(commitDocument.fields![kGithubGoldStatusDescriptionField]!.stringValue, githubGoldStatusUpdate.description);
    expect(commitDocument.fields![kGithubGoldStatusRepositoryField]!.stringValue, githubGoldStatusUpdate.repository);
  });
}
