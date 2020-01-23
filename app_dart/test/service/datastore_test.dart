// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../src/datastore/fake_datastore.dart';

void main() {
  DatastoreService datastore;

  final List<Commit> hundredCommits = List<Commit>.generate(
    100,
    (int i) => Commit(
      key: Key.emptyKey(Partition('ns')).append(Commit, id: 'sha$i'),
      sha: 'sha$i',
    ),
  );

  setUp(() {
    final FakeDatastoreDB db = FakeDatastoreDB();
    db.addOnQuery<Commit>((Iterable<Commit> results) => hundredCommits);

    datastore = DatastoreService(db: db);
  });

  test('query recent commits', () async {
    final List<Commit> commits = await datastore.queryRecentCommits().toList();

    expect(commits, hundredCommits);
  });

  test('query recent commits with limit', () async {
    final List<Commit> commits =
        await datastore.queryRecentCommits(limit: 1).toList();

    expect(commits, hundredCommits.first);
  });

// test recent tasks

// test tasks grouped by stage
}
