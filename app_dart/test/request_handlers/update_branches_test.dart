// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:cocoon_service/src/request_handlers/update_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' show GitCommit, GitCommitUser, RepositoryCommit;
import 'package:mockito/mockito.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/mocks.dart';
import 'update_branches_test_data.dart';

void main() {
  group('update branches', () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late UpdateBranches handler;
    late FakeHttpRequest request;
    late FakeDatastoreDB db;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    late MockRepositoriesService mockRepositoriesService;
    final MockProcessRunner processRunner = MockProcessRunner();

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

      final MockGitHub mockGitHubClient = MockGitHub();
      mockRepositoriesService = MockRepositoriesService();
      when(mockGitHubClient.repositories).thenReturn(mockRepositoriesService);
      when(processRunner.runProcess(any)).thenAnswer(
          (Invocation invocation) => Future.value(ProcessRunnerResult(0, stdoutArray, stderrArray, outputArray)));
      // this encodes '72fe8a9ec3af4d76097f09a9c01bf31c62a942aa' and 'refs/heads/main'

      config = FakeConfig(dbValue: db, keyHelperValue: keyHelper, githubClient: mockGitHubClient);
      handler = UpdateBranches(
        config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        processRunner: processRunner,
      );

      const String id = 'flutter/flutter/main';
      int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(
        key: branchKey,
        lastActivity: lastActivity,
      );
      db.values[currentBranch.key] = currentBranch;
    });

    test('should not retrieve branches older than 2 months', () async {
      expect(db.values.values.whereType<Branch>().length, 1);
      when(mockRepositoriesService.getCommit(any, any)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
                committer: GitCommitUser(
              'xilaizhang',
              'xilaizhang@google.com',
              DateTime.now().subtract(const Duration(days: 90)),
            ))));
      });

      final List<dynamic> result = (await decodeHandlerBody())!;
      expect(result, isEmpty);
    });

    test('should retrieve branches with commit acitivities in the past week', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      // a recent commit is added for each of the 6 repos
      when(mockRepositoriesService.getCommit(any, any)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
                committer: GitCommitUser(
              'xilaizhang',
              'xilaizhang@google.com',
              DateTime.now(),
            ))));
      });

      final List<dynamic> result = (await decodeHandlerBody())!;
      List<String> repos = [];
      for (dynamic k in result) {
        repos.add('${k['branch']['repository']}/${k['branch']['branch']}');
      }
      expect(repos, contains('flutter/flutter/main')); //flutter/flutter/main is updated
      expect(repos, contains('flutter/cocoon/main'));
      expect(result.length, 6);
      expect(db.values.values.whereType<Branch>().length, 6);
    });

    test('should not retrieve branch if updated commit acitivities happened long ago', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      when(mockRepositoriesService.getCommit(any, any)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
                committer: GitCommitUser(
              'xilaizhang',
              'xilaizhang@google.com',
              DateTime.tryParse('2020-05-15T15:20:56Z'),
            ))));
      });

      final List<dynamic> result = (await decodeHandlerBody())!;
      expect(result, isEmpty);
    });
  });
}
