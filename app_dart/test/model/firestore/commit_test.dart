// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart' as datastore;
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group('Commit.fromFirestore', () {
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
    });

    test('generates commit correctly', () async {
      final Commit commit = generateFirestoreCommit(1);
      when(
        mockFirestoreService.getDocument(
          captureAny,
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<Commit>.value(
          commit,
        );
      });
      final Commit resultedCommit = await Commit.fromFirestore(
        firestoreService: mockFirestoreService,
        documentName: 'test',
      );
      expect(resultedCommit.name, commit.name);
      expect(resultedCommit.fields, commit.fields);
    });
  });

  test('creates commit document correctly from commit data model', () async {
    final datastore.Commit commit = generateCommit(1);
    final Commit commitDocument = commitToCommitDocument(commit);
    expect(commitDocument.name, '$kDatabase/documents/$kCommitCollectionId/${commit.sha}');
    expect(commitDocument.fields![kCommitAvatarField]!.stringValue, commit.authorAvatarUrl);
    expect(commitDocument.fields![kCommitBranchField]!.stringValue, commit.branch);
    expect(commitDocument.fields![kCommitCreateTimestampField]!.integerValue, commit.timestamp.toString());
    expect(commitDocument.fields![kCommitAuthorField]!.stringValue, commit.author);
    expect(commitDocument.fields![kCommitMessageField]!.stringValue, commit.message);
    expect(commitDocument.fields![kCommitRepositoryPathField]!.stringValue, commit.repository);
    expect(commitDocument.fields![kCommitShaField]!.stringValue, commit.sha);
  });

  test('creates a new Commit document', () {
    final Commit initialCommit = generateFirestoreCommit(1);
    final Commit resultedCommit = Commit.newCommit(
      author: initialCommit.author!,
      avatar: initialCommit.avatar!,
      branch: initialCommit.branch!,
      message: initialCommit.message!,
      repositoryPath: initialCommit.repositoryPath!,
      sha: initialCommit.sha!,
      createTimestamp: initialCommit.createTimestamp!,
    );
    expect(initialCommit.name, resultedCommit.name);
    expect(initialCommit.author, resultedCommit.author);
    expect(initialCommit.avatar, resultedCommit.avatar);
    expect(initialCommit.branch, resultedCommit.branch);
    expect(initialCommit.message, resultedCommit.message);
    expect(initialCommit.repositoryPath, resultedCommit.repositoryPath);
    expect(initialCommit.sha, resultedCommit.sha);
    expect(initialCommit.createTimestamp, resultedCommit.createTimestamp);
  });
}
