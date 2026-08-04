// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  test('generates commit correctly', () async {
    final storedCommit = generateFirestoreCommit(1);
    firestoreService.putDocument(storedCommit);

    final resultedCommit = await Commit.fromFirestoreBySha(
      firestoreService,
      sha: storedCommit.sha,
    );
    expect(resultedCommit.name, storedCommit.name);
    expect(resultedCommit.fields, storedCommit.fields);
  });

  test(
    'tryFromFirestoreBySha returns commit when exists, null otherwise',
    () async {
      final storedCommit = generateFirestoreCommit(1);
      firestoreService.putDocument(storedCommit);

      final found = await Commit.tryFromFirestoreBySha(
        firestoreService,
        sha: storedCommit.sha,
      );
      expect(found, isNotNull);
      expect(found!.sha, storedCommit.sha);

      final notFound = await Commit.tryFromFirestoreBySha(
        firestoreService,
        sha: 'nonexistent_sha',
      );
      expect(notFound, isNull);
    },
  );
}
