// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:cocoon_service/src/request_handlers/get_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('GetBranches', () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetBranches handler;
    late FakeHttpRequest request;
    late FakeDatastoreDB db;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;

    Future<T?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single as T?;
    }

    setUp(() {
      db = FakeDatastoreDB();
      clientContext = FakeClientContext();
      request = FakeHttpRequest();
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      tester = RequestHandlerTester(request: request);
      config = FakeConfig(
        dbValue: db,
        keyHelperValue: keyHelper,
      );
      handler = GetBranches(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );

      const String id = 'flutter/flutter/branch-created-old';
      final int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(
        key: branchKey,
        lastActivity: lastActivity,
      );
      db.values[currentBranch.key] = currentBranch;
    });

    test('should not retrieve branches older than a week', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      final List<dynamic> result = (await decodeHandlerBody())!;
      expect(result, isEmpty);
    });

    test('should filter out branches not in the interest subset', () async {
      // main
      const String mainId = 'flutter/flutter/main';
      final int lastActivity = DateTime.now().millisecondsSinceEpoch;
      final Key<String> mainBranchKey = db.emptyKey.append<String>(Branch, id: mainId);
      final Branch mainBranch = Branch(
        key: mainBranchKey,
        lastActivity: lastActivity,
      );
      db.values[mainBranch.key] = mainBranch;
      // release candidate branch
      const String releaseId = 'flutter/flutter/flutter-3.10-candidate.1';
      final Key<String> releaseBranchKey = db.emptyKey.append<String>(Branch, id: releaseId);
      final Branch releaseBranch = Branch(
        key: releaseBranchKey,
        lastActivity: lastActivity,
      );
      db.values[releaseBranch.key] = releaseBranch;
      // other
      const String otherId = 'flutter/flutter/other-flutter-3.10-candidate.1';
      final Key<String> otherBranchKey = db.emptyKey.append<String>(Branch, id: otherId);
      final Branch otherBranch = Branch(
        key: otherBranchKey,
        lastActivity: lastActivity,
      );
      db.values[otherBranch.key] = otherBranch;
      final List<dynamic> result = (await decodeHandlerBody())!;
      final List<dynamic> expected = [
        {
          'id': 'flutter/flutter/main',
          'branch': <String, String>{'branch': 'main', 'repository': 'flutter/flutter'}
        },
        {
          'id': 'flutter/flutter/flutter-3.10-candidate.1',
          'branch': <String, String>{'branch': 'flutter-3.10-candidate.1', 'repository': 'flutter/flutter'}
        }
      ];
      expect(result, expected);
    });

    test('does not filter main branch independently of age', () async {
      // main
      const String mainId = 'flutter/flutter/main';
      final int lastActivity = DateTime.now().millisecondsSinceEpoch - const Duration(days: 90).inMilliseconds;
      final Key<String> mainBranchKey = db.emptyKey.append<String>(Branch, id: mainId);
      final Branch mainBranch = Branch(
        key: mainBranchKey,
        lastActivity: lastActivity,
      );
      db.values[mainBranch.key] = mainBranch;
      // release candidate branch
      const String releaseId = 'flutter/flutter/flutter-3.10-candidate.1';
      final Key<String> releaseBranchKey = db.emptyKey.append<String>(Branch, id: releaseId);
      final Branch releaseBranch = Branch(
        key: releaseBranchKey,
        lastActivity: lastActivity,
      );
      db.values[releaseBranch.key] = releaseBranch;
      // other
      const String otherId = 'flutter/engine/master';
      final Key<String> otherBranchKey = db.emptyKey.append<String>(Branch, id: otherId);
      final Branch otherBranch = Branch(
        key: otherBranchKey,
        lastActivity: lastActivity,
      );
      db.values[otherBranch.key] = otherBranch;
      final List<dynamic> result = (await decodeHandlerBody())!;
      final List<dynamic> expected = [
        {
          'id': 'flutter/flutter/main',
          'branch': <String, String>{'branch': 'main', 'repository': 'flutter/flutter'}
        },
        {
          'id': 'flutter/engine/master',
          'branch': {'branch': 'master', 'repository': 'flutter/engine'}
        }
      ];
      expect(result, expected);
    });

    test('should retrieve branches with commit acitivities in the past week', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      const String id = 'flutter/flutter/flutter-branch-created-now';
      final int lastActivity = DateTime.now().millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(
        key: branchKey,
        lastActivity: lastActivity,
      );
      db.values[currentBranch.key] = currentBranch;

      expect(db.values.values.whereType<Branch>().length, 2);

      final List<dynamic> result = (await decodeHandlerBody())!;
      expect((result.single)['branch']['branch'], 'flutter-branch-created-now');
      expect((result.single)['id'].runtimeType, String);
    });
  });
}
