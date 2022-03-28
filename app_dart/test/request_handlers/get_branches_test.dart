// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/request_handlers/get_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  group('GetBranches', () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late GetBranches handler;
    late FakeHttpRequest request;
    late FakeDatastoreDB db;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusService buildStatusService;

    final Commit recentCommit = generateCommit(
      1,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      branch: 'branch-created-old',
    );
    final Commit oldCommit = generateCommit(
      1,
      timestamp: DateTime.now()
          .subtract(const Duration(days: 2 * GetBranches.kActiveBranchActivityPeriod))
          .millisecondsSinceEpoch,
      branch: 'branch-created-old',
    );

    Future<T?> decodeHandlerBody<T>() async {
      final Body body = await tester.get(handler);
      return await utf8.decoder.bind(body.serialize() as Stream<List<int>>).transform(json.decoder).single as T?;
    }

    setUp(() {
      db = FakeDatastoreDB();
      clientContext = FakeClientContext();
      request = FakeHttpRequest(
        queryParametersValue: <String, dynamic>{
          GetBranches.kUpdateBranchParam: 'true',
        },
      );
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      tester = RequestHandlerTester(request: request);
      config = FakeConfig(
        dbValue: db,
        keyHelperValue: keyHelper,
      );
      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[],
      );
      handler = GetBranches(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      const String id = 'flutter/flutter/branch-created-old';
      int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(
        key: branchKey,
        lastActivity: lastActivity,
      );
      db.values[currentBranch.key] = currentBranch;
    });

    test('should not retrieve branches older than a week', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['Branches'], isEmpty);
    });

    test('should retrieve branches with commit acitivities in the past week', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      const String id = 'flutter/flutter/branch-created-now';
      int lastActivity = DateTime.now().millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(
        key: branchKey,
        lastActivity: lastActivity,
      );
      db.values[currentBranch.key] = currentBranch;

      expect(db.values.values.whereType<Branch>().length, 2);

      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect((result['Branches'].single)['branch']['branch'], 'branch-created-now');
      expect((result['Branches'].single)['key'].runtimeType, String);
    });

    test('should retrieve stale branch if after update, stale branch gains recent commit acitivties', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(recentCommit, const <Stage>[]),
        ],
      );
      handler = GetBranches(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect((result['Branches'].single)['branch']['branch'], 'branch-created-old');
    });

    test('should not retrieve branch if updated commit acitivities happened long ago', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(oldCommit, const <Stage>[]),
        ],
      );
      handler = GetBranches(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['Branches'], isEmpty);
    });

    test('should not retrieve stale branch with recent commits, if the `update` parameter was not set in http request',
        () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      request = FakeHttpRequest();
      tester = RequestHandlerTester(request: request);

      buildStatusService = FakeBuildStatusService(
        commitStatuses: <CommitStatus>[
          CommitStatus(recentCommit, const <Stage>[]),
        ],
      );
      handler = GetBranches(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_) => buildStatusService,
      );

      final Map<String, dynamic> result = (await decodeHandlerBody())!;
      expect(result['Branches'], isEmpty);
    });
  });
}
