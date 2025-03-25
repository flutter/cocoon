// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
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
}
