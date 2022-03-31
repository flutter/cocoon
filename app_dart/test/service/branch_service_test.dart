// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late FakeConfig config;
  late FakeDatastoreDB db;
  late DatastoreService datastoreService;
  late BranchService branchService;

  setUp(() {
    db = FakeDatastoreDB();
    config = FakeConfig(
      dbValue: db,
    );
    datastoreService = DatastoreService(config.db, 5);
  });

  group('branch service test', () {
    test('should add branch to db if db is empty', () async {
      expect(db.values.values.whereType<Branch>().length, 0);
      final String request = generateCreateBranchEvent('flutter-2.12-candidate.4', 'flutter/flutter');
      branchService = BranchService(datastoreService, rawRequest: request);
      await branchService.handleCreateRequest();

      expect(db.values.values.whereType<Branch>().length, 1);
      final Branch branch = db.values.values.whereType<Branch>().single;
      expect(branch.repository, 'flutter/flutter');
      expect(branch.branch, 'flutter-2.12-candidate.4');
    });

    test('should not add duplicate entity if branch already exists in db', () async {
      expect(db.values.values.whereType<Branch>().length, 0);

      const String id = 'flutter/flutter/flutter-2.12-candidate.4';
      int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(key: branchKey, lastActivity: lastActivity);
      db.values[currentBranch.key] = currentBranch;
      expect(db.values.values.whereType<Branch>().length, 1);

      final String request = generateCreateBranchEvent('flutter-2.12-candidate.4', 'flutter/flutter');
      branchService = BranchService(datastoreService, rawRequest: request);
      await branchService.handleCreateRequest();

      expect(db.values.values.whereType<Branch>().length, 1);
      final Branch branch = db.values.values.whereType<Branch>().single;
      expect(branch.repository, 'flutter/flutter');
      expect(branch.branch, 'flutter-2.12-candidate.4');
    });

    test('should add branch if it is different from previously existing branches', () async {
      expect(db.values.values.whereType<Branch>().length, 0);

      const String id = 'flutter/flutter/flutter-2.12-candidate.4';
      int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(key: branchKey, lastActivity: lastActivity);
      db.values[currentBranch.key] = currentBranch;

      expect(db.values.values.whereType<Branch>().length, 1);

      final String request = generateCreateBranchEvent('flutter-2.12-candidate.5', 'flutter/flutter');
      branchService = BranchService(datastoreService, rawRequest: request);
      await branchService.handleCreateRequest();

      expect(db.values.values.whereType<Branch>().length, 2);
      expect(db.values.values.whereType<Branch>().map<String>((Branch b) => b.branch),
          containsAll(<String>['flutter-2.12-candidate.4', 'flutter-2.12-candidate.5']));
    });
  });
}
