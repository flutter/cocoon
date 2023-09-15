// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:cocoon_service/src/request_handlers/update_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' show GitCommit, GitCommitUser, RepositoryCommit;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/mocks.dart';

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
    final MockProcessManager processManager = MockProcessManager();

    const String stdoutResult = '72fe8a9ec3af4d76097f09a9c01bf31c62a942aa refs/heads/main';
    const String testBranchSha = '72fe8a9ec3af4d76097f09a9c01bf31c62a942aa';

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
      when(processManager.runSync(any)).thenAnswer((Invocation invocation) => ProcessResult(1, 0, stdoutResult, ''));

      config = FakeConfig(dbValue: db, keyHelperValue: keyHelper, githubClient: mockGitHubClient);
      handler = UpdateBranches(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        processManager: processManager,
      );

      const String id = 'flutter/flutter/main';
      final int lastActivity = DateTime.tryParse('2019-05-15T15:20:56Z')!.millisecondsSinceEpoch;
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
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
              committer: GitCommitUser(
                'dash',
                'dash@google.com',
                DateTime.now().subtract(const Duration(days: 90)),
              ),
            ),
          ),
        );
      });

      final List<dynamic> result = (await decodeHandlerBody())!;
      expect(result, isEmpty);
    });

    test('should retrieve branches with commit acitivities in the past week', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      // a recent commit is added for each of the 6 repos
      when(mockRepositoriesService.getCommit(any, any)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
              committer: GitCommitUser(
                'dash',
                'dash@google.com',
                DateTime.now(),
              ),
            ),
          ),
        );
      });

      final List<dynamic> result = (await decodeHandlerBody())!;
      final List<String> repos = [];
      for (dynamic k in result) {
        repos.add('${k['branch']['repository']}/${k['branch']['branch']}');
      }
      expect(repos, contains('flutter/flutter/main')); //flutter/flutter/main is updated
      expect(result.length, config.supportedRepos.length);
      expect(db.values.values.whereType<Branch>().length, config.supportedRepos.length);
    });

    test('should not retrieve branch if updated commit acitivities happened long ago', () async {
      expect(db.values.values.whereType<Branch>().length, 1);

      when(mockRepositoriesService.getCommit(any, any)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
              committer: GitCommitUser(
                'dash',
                'dash@google.com',
                DateTime.tryParse('2020-05-15T15:20:56Z'),
              ),
            ),
          ),
        );
      });

      final List<dynamic> result = (await decodeHandlerBody())!;
      expect(result, isEmpty);
    });

    test('should throw exception when git ls-remote fails', () async {
      expect(db.values.values.whereType<Branch>().length, 1);
      when(processManager.runSync(any)).thenAnswer((Invocation invocation) => ProcessResult(1, -1, stdoutResult, ''));

      when(mockRepositoriesService.getCommit(any, any)).thenAnswer((Invocation invocation) {
        return Future<RepositoryCommit>.value(
          RepositoryCommit(
            sha: testBranchSha,
            commit: GitCommit(
              committer: GitCommitUser(
                'dash',
                'dash@google.com',
                DateTime.tryParse('2020-05-15T15:20:56Z'),
              ),
            ),
          ),
        );
      });

      expect(() => decodeHandlerBody<List<dynamic>>(), throwsA(const TypeMatcher<FormatException>()));
    });
  });
}
