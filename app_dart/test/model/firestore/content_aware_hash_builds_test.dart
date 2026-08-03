// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/content_aware_hash_builds.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  test(
    'getByContentHash returns document when exists, null otherwise',
    () async {
      final build = ContentAwareHashBuilds(
        createdOn: DateTime.utc(2024, 1, 1),
        contentHash: 'hash123',
        commitSha: 'sha123',
        buildStatus: BuildStatus.success,
        waitingShas: ['sha456'],
      );
      firestoreService.putDocument(build);

      final found = await ContentAwareHashBuilds.getByContentHash(
        firestoreService,
        contentHash: 'hash123',
      );
      expect(found, isNotNull);
      expect(found!.contentHash, 'hash123');
      expect(found.commitSha, 'sha123');
      expect(found.status, BuildStatus.success);

      final notFound = await ContentAwareHashBuilds.getByContentHash(
        firestoreService,
        contentHash: 'missing_hash',
      );
      expect(notFound, isNull);
    },
  );
}
