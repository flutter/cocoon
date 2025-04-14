// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:test/test.dart';

import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  late FakeFirestoreService firestoreService;

  setUp(() {
    firestoreService = FakeFirestoreService();
  });

  test('generates githubBuildStatus correctly', () async {
    final githubBuildStatus = generateFirestoreGithubBuildStatus(1);
    firestoreService.putDocument(githubBuildStatus);

    final resultedGithubBuildStatus = await GithubBuildStatus.fromFirestore(
      firestoreService: firestoreService,
      documentName: githubBuildStatus.name!,
    );
    expect(resultedGithubBuildStatus.name, githubBuildStatus.name);
    expect(resultedGithubBuildStatus.fields, githubBuildStatus.fields);
  });
}
