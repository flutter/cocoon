// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/appengine/github_build_status_update.dart';
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group('GithubBuildStatus.fromFirestore', () {
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    test('generates githubBuildStatus correctly', () async {
      final githubBuildStatus = generateFirestoreGithubBuildStatus(1);
      when(mockFirestoreService.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<GithubBuildStatus>.value(githubBuildStatus);
      });
      final resultedGithubBuildStatus = await GithubBuildStatus.fromFirestore(
        firestoreService: mockFirestoreService,
        documentName: 'test',
      );
      expect(resultedGithubBuildStatus.name, githubBuildStatus.name);
      expect(resultedGithubBuildStatus.fields, githubBuildStatus.fields);
    });
  });

  group('Creates github gold status document', () {
    test('from data model', () async {
      final githubBuildStatusUpdate = GithubBuildStatusUpdate(
        head: 'sha',
        pr: 1,
        status: GithubBuildStatusUpdate.statusSuccess,
        updates: 2,
        repository: '',
      );
      final githubBuildStatusDocument = githubBuildStatusToDocument(
        githubBuildStatusUpdate,
      );
      expect(
        githubBuildStatusDocument.name,
        '$kDatabase/documents/$kGithubBuildStatusCollectionId/${githubBuildStatusUpdate.head}_${githubBuildStatusUpdate.pr}',
      );
      expect(
        githubBuildStatusDocument
            .fields![kGithubBuildStatusHeadField]!
            .stringValue,
        githubBuildStatusUpdate.head,
      );
      expect(
        githubBuildStatusDocument
            .fields![kGithubBuildStatusPrNumberField]!
            .integerValue,
        githubBuildStatusUpdate.pr.toString(),
      );
      expect(
        githubBuildStatusDocument
            .fields![kGithubBuildStatusStatusField]!
            .stringValue,
        githubBuildStatusUpdate.status,
      );
      expect(
        githubBuildStatusDocument
            .fields![kGithubBuildStatusUpdatesField]!
            .integerValue,
        githubBuildStatusUpdate.updates.toString(),
      );
      expect(
        githubBuildStatusDocument
            .fields![kGithubBuildStatusRepositoryField]!
            .stringValue,
        '',
      );
    });
  });
}
