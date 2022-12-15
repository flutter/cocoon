// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/service/github_service.dart';

import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/utilities/mocks.dart';

void main() {
  late GithubService githubService;
  MockGitHub mockGitHub;
  late RepositorySlug slug;

  const String branch = 'master';
  const int lastCommitTimestampMills = 100;

  const String authorName = 'Jane Doe';
  const String authorEmail = 'janedoe@example.com';
  const String authorDate = '2000-01-01T10:10:10Z';
  const String authorLogin = 'Username';
  const String authorAvatarUrl = 'http://example.com/avatar';
  const String commitMessage = 'commit message';

  List<String> shas;

  setUp(() {
    shas = <String>[];
    mockGitHub = MockGitHub();
    githubService = GithubService(mockGitHub);
    slug = RepositorySlug('flutter', 'flutter');
    final PostExpectation<Future<http.Response>> whenGithubRequest = when(
      mockGitHub.request(
        'GET',
        '/repos/${slug.owner}/${slug.name}/commits',
        headers: anyNamed('headers'),
        params: anyNamed('params'),
        body: anyNamed('body'),
        statusCode: anyNamed('statusCode'),
      ),
    );
    whenGithubRequest.thenAnswer((_) async {
      final List<dynamic> data = <dynamic>[];
      for (String sha in shas) {
        // https://developer.github.com/v3/repos/commits/#list-commits
        data.add(<String, dynamic>{
          'sha': sha,
          'commit': <String, dynamic>{
            'message': commitMessage,
            'author': <String, dynamic>{
              'name': authorName,
              'email': authorEmail,
              'date': authorDate,
            },
          },
          'author': <String, dynamic>{
            'login': authorLogin,
            'avatar_url': authorAvatarUrl,
          },
        });
      }
      return http.Response(json.encode(data), HttpStatus.ok);
    });
  });

  test('listCommits decodes all relevant fields of each commit', () async {
    shas = <String>['1'];
    final List<RepositoryCommit> commits = await githubService.listCommits(
      slug,
      branch,
      lastCommitTimestampMills,
    );
    expect(commits, hasLength(1));
    final RepositoryCommit commit = commits.single;
    expect(commit.sha, shas.single);
    expect(commit.author, isNotNull);
    expect(commit.author!.login, authorLogin);
    expect(commit.author!.avatarUrl, authorAvatarUrl);
    expect(commit.commit, isNotNull);
    expect(commit.commit!.message, commitMessage);
    expect(commit.commit!.committer, isNotNull);
    expect(commit.commit!.committer!.name, authorName);
    expect(commit.commit!.committer!.email, authorEmail);
  });
  group('getFileContent', () {
    late MockClient branchHttpClient;

    test('returns branches', () async {
      branchHttpClient = MockClient((_) async => http.Response(branchRegExp, HttpStatus.ok));
      final String branches = await getFileContent(
        RepositorySlug('flutter', 'cocoon'),
        'branches.txt',
        httpClientProvider: () => branchHttpClient,
        retryOptions: noRetry,
      );
      final List<String> branchList = branches.split('\n').map((String branch) => branch.trim()).toList();
      branchList.removeWhere((String branch) => branch.isEmpty);
      expect(branchList, <String>['master', 'flutter-1.1-candidate.1']);
    });

    test('retries branches download upon HTTP failure', () async {
      int retry = 0;
      branchHttpClient = MockClient((_) async {
        if (retry++ == 0) {
          return http.Response('', HttpStatus.serviceUnavailable);
        }
        return http.Response(branchRegExp, HttpStatus.ok);
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      final String branches = await getFileContent(
        RepositorySlug('flutter', 'cocoon'),
        'branches.txt',
        httpClientProvider: () => branchHttpClient,
        retryOptions: const RetryOptions(
          maxAttempts: 3,
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
        ),
      );
      final List<String> branchList = branches.split('\n').map((String branch) => branch.trim()).toList();
      branchList.removeWhere((String branch) => branch.isEmpty);
      expect(retry, 2);
      expect(branchList, <String>['master', 'flutter-1.1-candidate.1']);
      expect(records.where((LogRecord record) => record.level == Level.INFO), isNotEmpty);
      expect(records.where((LogRecord record) => record.level == Level.SEVERE), isEmpty);
    });

    test('falls back to git on borg', () async {
      branchHttpClient = MockClient((http.Request request) async {
        if (request.url.toString() ==
            'https://flutter.googlesource.com/mirrors/cocoon/+/ba7fe03781762603a1cdc364f8f5de56a0fdbf5c/.ci.yaml?format=text') {
          return http.Response(base64Encode(branchRegExp.codeUnits), HttpStatus.ok);
        }
        // Mock a GitHub outage
        return http.Response('', HttpStatus.serviceUnavailable);
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      final String branches = await getFileContent(
        RepositorySlug('flutter', 'cocoon'),
        '.ci.yaml',
        httpClientProvider: () => branchHttpClient,
        ref: 'ba7fe03781762603a1cdc364f8f5de56a0fdbf5c',
        retryOptions: const RetryOptions(
          maxAttempts: 1,
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
        ),
      );
      final List<String> branchList = branches.split('\n').map((String branch) => branch.trim()).toList();
      branchList.removeWhere((String branch) => branch.isEmpty);
      expect(branchList, <String>['master', 'flutter-1.1-candidate.1']);
    });

    test('falls back to git on borg when given sha', () async {
      branchHttpClient = MockClient((http.Request request) async {
        if (request.url.toString() ==
            'https://flutter.googlesource.com/mirrors/cocoon/+/refs/heads/main/.ci.yaml?format=text') {
          return http.Response(base64Encode(branchRegExp.codeUnits), HttpStatus.ok);
        }
        // Mock a GitHub outage
        return http.Response('', HttpStatus.serviceUnavailable);
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      final String branches = await getFileContent(
        RepositorySlug('flutter', 'cocoon'),
        '.ci.yaml',
        ref: 'main',
        httpClientProvider: () => branchHttpClient,
        retryOptions: const RetryOptions(
          maxAttempts: 1,
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
        ),
      );
      final List<String> branchList = branches.split('\n').map((String branch) => branch.trim()).toList();
      branchList.removeWhere((String branch) => branch.isEmpty);
      expect(branchList, <String>['master', 'flutter-1.1-candidate.1']);
    });

    test('gives up after 6 tries', () async {
      int retry = 0;
      branchHttpClient = MockClient((_) async {
        retry++;
        return http.Response('', HttpStatus.serviceUnavailable);
      });
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await expectLater(
        getFileContent(
          RepositorySlug('flutter', 'cocoon'),
          'branches.txt',
          httpClientProvider: () => branchHttpClient,
          retryOptions: const RetryOptions(
            maxAttempts: 3,
            delayFactor: Duration.zero,
            maxDelay: Duration.zero,
          ),
        ),
        throwsA(isA<HttpException>()),
      );
      // It will request from GitHub 3 times, fallback to GoB, then fail.
      expect(retry, 6);
      expect(records.where((LogRecord record) => record.level == Level.WARNING), isNotEmpty);
    });
  });
}
