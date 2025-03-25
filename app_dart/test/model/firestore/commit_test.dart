// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group('Commit.fromFirestore', () {
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    test('generates commit correctly', () async {
      final commit = generateFirestoreCommit(1);
      when(mockFirestoreService.getDocument(captureAny)).thenAnswer((
        Invocation invocation,
      ) {
        return Future<Commit>.value(commit);
      });
      final resultedCommit = await Commit.fromFirestoreBySha(
        mockFirestoreService,
        sha: commit.sha!,
      );
      expect(resultedCommit.name, commit.name);
      expect(resultedCommit.fields, commit.fields);
    });
  });
}
