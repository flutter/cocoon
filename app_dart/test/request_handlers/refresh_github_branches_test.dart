// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/server.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/service/fake_github_service.dart';

const String branchRegExp = '''
      master
      ^flutter-[0-9]+\.[0-9]+-candidate\.[0-9]+
      ''';

void main() {
  group('RefreshGithubBranches', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    RefreshGithubBranches handler;
    List<String> githubBranches;
    FakeHttpClient branchHttpClient;

    Stream<Branch> branchStream() async* {
      for (String branchName in githubBranches) {
        final CommitDataUser author = CommitDataUser('a', 1, 'b');
        final GitCommit gitCommit = GitCommit();
        final CommitData commitData = CommitData('sha', gitCommit, 'test',
            'test', 'test', author, author, <Map<String, dynamic>>[]);
        final Branch branch = Branch(branchName, commitData);
        yield branch;
      }
    }

    setUp(() {
      final MockRepositoriesService repositories = MockRepositoriesService();
      final FakeGithubService githubService = FakeGithubService();
      config = FakeConfig(githubService: githubService,);
      tester = ApiRequestHandlerTester();
      branchHttpClient = FakeHttpClient();
      handler = RefreshGithubBranches(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
      );

      const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
      when(githubService.github.repositories).thenReturn(repositories);
      when(repositories.listBranches(slug)).thenAnswer((Invocation _) {
        return branchStream();
      });
    });

    test('update authorization token for agent', () async {
      githubBranches = <String>['master', 'flutter-1.1-candidate.0'];
      final CocoonConfig cocoonConfig = CocoonConfig()
        ..id = 'FlutterBranches'
        ..parentKey = config.db.emptyKey
        ..value = 'test';
      config.db.values[cocoonConfig.key] = cocoonConfig;

      expect(cocoonConfig.id, 'FlutterBranches');

      branchHttpClient.request.response.body = branchRegExp;
      await tester.get(handler);

      // Length of the hashed code using [dbcrypt] is 60
      expect(cocoonConfig.value, 'master,flutter-1.1-candidate.0');
    });
  });
}

class MockGitHub extends Mock implements GitHub {}

class MockRepositoriesService extends Mock implements RepositoriesService {}
