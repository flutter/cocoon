// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/foundation/utils.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';

const String branchRegExp = '''
      master
      ^flutter-[0-9]+\.[0-9]+-candidate\.[0-9]+
      ''';

void main() {
  group('Test utils', () {
    group('LoadBranchRegExps', () {
      FakeHttpClient branchHttpClient;
      FakeLogging log;

      setUp(() {
        branchHttpClient = FakeHttpClient();
        log = FakeLogging();
      });

      test('returns branches matching regExps', () async {
        branchHttpClient.request.response.body = branchRegExp;
        final List<String> branches = await loadBranchRegExps(
            () => branchHttpClient, log, (int attempt) => Duration.zero);
        expect(branches.length, 2);
      });

      test('retries regExps download upon HTTP failure', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest = (FakeHttpClientRequest request) {
          request.response.statusCode =
              retry == 0 ? HttpStatus.serviceUnavailable : HttpStatus.ok;
          retry++;
        };

        branchHttpClient.request.response.body = branchRegExp;
        final List<String> branches = await loadBranchRegExps(
            () => branchHttpClient, log, (int attempt) => Duration.zero);
        expect(retry, 2);
        expect(branches,
            <String>['master', '^flutter-[0-9]+.[0-9]+-candidate.[0-9]+']);
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
      });

      test('gives up regExps download after 3 tries', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest =
            (FakeHttpClientRequest request) => retry++;
        branchHttpClient.request.response.statusCode =
            HttpStatus.serviceUnavailable;
        branchHttpClient.request.response.body = branchRegExp;
        final List<String> branches = await loadBranchRegExps(
            () => branchHttpClient, log, (int attempt) => Duration.zero);
        expect(branches, <String>['master']);
        expect(retry, 3);
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isNotEmpty);
      });
    });

    group('GetBranches', () {
      FakeConfig config;
      FakeHttpClient branchHttpClient;
      FakeLogging log;
      List<String> githubBranches = <String>[];

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
        final FakeGithubService githubService = FakeGithubService();
        //final MockGitHub github = MockGitHub();
        final MockRepositoriesService repositoriesService =
            MockRepositoriesService();
        branchHttpClient = FakeHttpClient();
        config = FakeConfig(githubService: githubService);
        log = FakeLogging();

        when(githubService.github.repositories).thenReturn(repositoriesService);
        final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
        when(repositoriesService.listBranches(slug)).thenAnswer((_) {
          return branchStream();
        });
      });
      test('returns matched branches', () async {
        githubBranches = <String>['dev', 'flutter-0.0-candidate.0'];
        branchHttpClient.request.response.body = branchRegExp;
        final Uint8List branches = await getBranches(config,
            () => branchHttpClient, log, (int attempt) => Duration.zero);
        expect(String.fromCharCodes(branches).split(',').length, 1);
      });
    });

    group('GitHubBackoffCalculator', () {
      test('twoSecondLinearBackoff', () {
        expect(twoSecondLinearBackoff(0), const Duration(seconds: 2));
        expect(twoSecondLinearBackoff(1), const Duration(seconds: 4));
        expect(twoSecondLinearBackoff(2), const Duration(seconds: 6));
        expect(twoSecondLinearBackoff(3), const Duration(seconds: 8));
      });
    });
  });
}
