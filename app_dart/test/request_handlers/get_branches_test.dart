// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/request_handlers/get_branches.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:github/server.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';

const String branchRegExp = '''
      master
      ^flutter-[0-9]+\.[0-9]+-candidate\.[0-9]+
      ''';

void main() {
  group('GetBranches', () {
    FakeConfig config;
    FakeHttpClient branchHttpClient;
    RequestHandlerTester tester;
    GetBranches handler;
    List<String> githubBranches;

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
      final MockGitHub github = MockGitHub();
      final MockRepositoriesService repositories = MockRepositoriesService();

      config = FakeConfig(githubClient: github);
      branchHttpClient = FakeHttpClient();
      tester = RequestHandlerTester();
      handler = GetBranches(
        config,
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculatorBranch: (int attempt) => Duration.zero,
      );

      const RepositorySlug slug = RepositorySlug('flutter', 'flutter');
      when(github.repositories).thenReturn(repositories);
      when(repositories.listBranches(slug)).thenAnswer((Invocation _) {
        return branchStream();
      });
    });

    test('returns branches matching regExps', () async {
      githubBranches = <String>['flutter-1.1-candidate.1', 'master', 'test'];

      branchHttpClient.request.response.body = branchRegExp;

      final Body body = await tester.get(handler);
      final Map<String, dynamic> result = await utf8.decoder
          .bind(body.serialize())
          .transform(json.decoder)
          .single as Map<String, dynamic>;

      expect(result['Branches'], <String>['flutter-1.1-candidate.1', 'master']);
    });
  });
}

class MockGitHub extends Mock implements GitHub {}

class MockRepositoriesService extends Mock implements RepositoriesService {}
