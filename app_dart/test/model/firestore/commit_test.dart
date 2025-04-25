// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:test/test.dart';

import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';

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
    expect(resultedCommit.documentName, storedCommit.documentName);
    expect(resultedCommit.fields, storedCommit.fields);
  });
}
