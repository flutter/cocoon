// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  group('Commit.composeKey', () {
    test('creates valid key', () {
      final FakeDatastoreDB db = FakeDatastoreDB();
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
      const String gitBranch = 'main';
      const String sha = 'abc';
      final key = Commit.createKey(db: db, slug: slug, gitBranch: gitBranch, sha: sha);
      expect(key.id, equals('flutter/flutter/main/abc'));
    });
  });

  group('Commit.fromDatastore', () {
    late FakeConfig config;
    late Commit expectedCommit;

    setUp(() {
      config = FakeConfig();
      expectedCommit = generateCommit(1);
      config.db.values[expectedCommit.key] = expectedCommit;
    });

    test('look up by id', () async {
      final Commit commit = await Commit.fromDatastore(
        datastore: DatastoreService(config.db, 5),
        key: expectedCommit.key,
      );
      expect(commit, expectedCommit);
    });

    test('look up by id fails if cannot be found', () async {
      final datastore = DatastoreService(config.db, 5);
      expect(
        Commit.fromDatastore(
          datastore: datastore,
          key: Commit.createKey(
            db: datastore.db,
            slug: RepositorySlug('abc', 'test'),
            gitBranch: 'main',
            sha: 'def',
          ),
        ),
        throwsA(isA<KeyNotFoundException>()),
      );
    });
  });

  group('Commit.from', () {
    test('runs successfully', () {
      final key = Commit.createKey(
          db: FakeDatastoreDB(), slug: RepositorySlug('flutter', 'flutter'), gitBranch: 'main', sha: 'abc');

      final Commit commit = Commit(
          key: key,
          author: "Sally",
          authorAvatarUrl: "www.sally.com/url",
          message: "This commit fixes prod",
          repository: "flutter",
          branch: "merging-branch");
      final Commit clonedCommit = Commit.from(commit);

      expect(commit.toString(), clonedCommit.toString());
    });
  });
}
