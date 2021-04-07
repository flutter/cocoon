// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';

const String branchRegExp = '''
      master
      flutter-1.1-candidate.1
      ''';
const String luciBuilders = '''
      {
        "builders":[
            {
              "name":"Cocoon",
              "repo":"cocoon",
              "enabled":true
            }, {
              "name":"Cocoon2",
              "repo":"cocoon",
              "enabled":false
            }
        ]
      }
      ''';

void main() {
  group('Test utils', () {
    const RetryOptions noRetry = RetryOptions(
      maxAttempts: 1,
      delayFactor: Duration.zero,
      maxDelay: Duration.zero,
    );
    group('githubFileContent', () {
      FakeHttpClient branchHttpClient;
      FakeLogging log;

      setUp(() {
        branchHttpClient = FakeHttpClient();
        log = FakeLogging();
      });

      test('returns branches', () async {
        branchHttpClient.request.response.body = branchRegExp;
        final String branches = await githubFileContent(
          'branches.txt',
          httpClientProvider: () => branchHttpClient,
          log: log,
          retryOptions: noRetry,
        );
        final List<String> branchList = branches.split('\n').map((String branch) => branch.trim()).toList();
        branchList.removeWhere((String branch) => branch.isEmpty);
        expect(branchList, <String>['master', 'flutter-1.1-candidate.1']);
      });

      test('retries branches download upon HTTP failure', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest = (FakeHttpClientRequest request) {
          request.response.statusCode = retry == 0 ? HttpStatus.serviceUnavailable : HttpStatus.ok;
          retry++;
        };

        branchHttpClient.request.response.body = branchRegExp;
        final String branches = await githubFileContent(
          'branches.txt',
          httpClientProvider: () => branchHttpClient,
          log: log,
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
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
      });

      test('gives up after 3 tries', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
        branchHttpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
        branchHttpClient.request.response.body = branchRegExp;
        await expectLater(
            githubFileContent(
              'branches.txt',
              httpClientProvider: () => branchHttpClient,
              log: log,
              retryOptions: const RetryOptions(
                maxAttempts: 3,
                delayFactor: Duration.zero,
                maxDelay: Duration.zero,
              ),
            ),
            throwsA(isA<HttpException>()));
        expect(retry, 3);
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
      });
    });

    group('GetBranches', () {
      FakeHttpClient branchHttpClient;
      FakeLogging log;

      setUp(() {
        branchHttpClient = FakeHttpClient();
        log = FakeLogging();
      });
      test('returns branches', () async {
        branchHttpClient.request.response.body = branchRegExp;
        final Uint8List branches = await getBranches(
          () => branchHttpClient,
          log,
          retryOptions: noRetry,
        );
        expect(String.fromCharCodes(branches), 'master,flutter-1.1-candidate.1');
      });

      test('returns master when http request fails', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
        branchHttpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
        branchHttpClient.request.response.body = luciBuilders;
        final Uint8List builders = await getBranches(
          () => branchHttpClient,
          log,
          retryOptions: noRetry,
        );
        expect(String.fromCharCodes(builders), 'master');
      });
    });

    group('GetLuciBuilders', () {
      FakeGithubService githubService;
      FakeHttpClient luciBuilderHttpClient;
      FakeLogging log;

      setUp(() {
        githubService = FakeGithubService();
        luciBuilderHttpClient = FakeHttpClient();
        log = FakeLogging();
      });
      test('returns enabled luci builders', () async {
        final RepositorySlug slug = RepositorySlug('flutter', 'cocoon');
        luciBuilderHttpClient.request.response.body = luciBuilders;
        final List<LuciBuilder> builders = await getLuciBuilders(
          githubService,
          () => luciBuilderHttpClient,
          log,
          slug,
          'try',
          retryOptions: noRetry,
        );
        expect(builders.length, 1);
        expect(builders[0].name, 'Cocoon');
        expect(builders[0].repo, 'cocoon');
      });

      test('returns empty list when http request 404s', () async {
        final RepositorySlug slug = RepositorySlug('flutter', 'cocoon');
        int retry = 0;
        luciBuilderHttpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
        luciBuilderHttpClient.request.response.statusCode = HttpStatus.notFound;
        luciBuilderHttpClient.request.response.body = luciBuilders;
        final List<LuciBuilder> builders = await getLuciBuilders(
          githubService,
          () => luciBuilderHttpClient,
          log,
          slug,
          'try',
          retryOptions: noRetry,
        );
        expect(builders.length, 0);
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

    group('repoNameForBuilder', () {
      test('Builder config does not exist', () async {
        final List<LuciBuilder> builders = <LuciBuilder>[];
        final RepositorySlug result = await repoNameForBuilder(builders, 'DoesNotExist');
        expect(result, isNull);
      });

      test('Builder exists', () async {
        final List<LuciBuilder> builders = <LuciBuilder>[
          const LuciBuilder(name: 'Cocoon', repo: 'cocoon', flaky: false)
        ];
        final RepositorySlug result = await repoNameForBuilder(builders, 'Cocoon');
        expect(result, isNotNull);
        expect(result.fullName, equals('flutter/cocoon'));
      });
    });

    group('bigquery', () {
      FakeTabledataResourceApi tabledataResourceApi;
      FakeLogging log;

      setUp(() {
        tabledataResourceApi = FakeTabledataResourceApi();
        log = FakeLogging();
      });
      test('Insert data to bigquery', () async {
        await insertBigquery('test', <String, dynamic>{'test': 'test'}, tabledataResourceApi, log);
        final TableDataList tableDataList = await tabledataResourceApi.list('test', 'test', 'test');
        expect(tableDataList.totalRows, '1');
      });
    });

    group('getFilteredBuilders', () {
      List<String> files;
      List<LuciBuilder> builders;

      test('does not return builders when run_if does not match any file', () async {
        builders = <LuciBuilder>[
          const LuciBuilder(name: 'abc', repo: 'def', taskName: 'ghi', flaky: true, runIf: <String>['d/'])
        ];
        files = <String>['a/b', 'c/d'];
        final List<LuciBuilder> result = await getFilteredBuilders(builders, files);
        expect(result.length, 0);
      });

      test('returns builders when run_if is null', () async {
        files = <String>['a/b', 'c/d'];
        builders = <LuciBuilder>[const LuciBuilder(name: 'abc', repo: 'def', taskName: 'ghi', flaky: true)];
        final List<LuciBuilder> result = await getFilteredBuilders(builders, files);
        expect(result, builders);
      });

      test('returns builders when run_if matches files', () async {
        files = <String>['a/b', 'c/d'];
        builders = <LuciBuilder>[
          const LuciBuilder(name: 'abc', repo: 'def', taskName: 'ghi', flaky: true, runIf: <String>['a/'])
        ];
        final List<LuciBuilder> result = await getFilteredBuilders(builders, files);
        expect(result, builders);
      });

      test('returns builders when run_if matches files with **', () async {
        builders = <LuciBuilder>[
          const LuciBuilder(name: 'abc', repo: 'def', taskName: 'ghi', flaky: true, runIf: <String>['a/**'])
        ];
        files = <String>['a/b', 'c/d'];
        final List<LuciBuilder> result = await getFilteredBuilders(builders, files);
        expect(result, builders);
      });

      test('returns builders when run_if matches files with both * and **', () async {
        builders = <LuciBuilder>[
          const LuciBuilder(name: 'abc', repo: 'def', taskName: 'ghi', flaky: true, runIf: <String>['a/b*c/**'])
        ];
        files = <String>['a/baddsc/defg', 'c/d'];
        final List<LuciBuilder> result = await getFilteredBuilders(builders, files);
        expect(result, builders);
      });

      test('returns correct builders when file and folder share the same name', () async {
        builders = <LuciBuilder>[
          const LuciBuilder(name: 'abc', repo: 'def', taskName: 'ghi', flaky: true, runIf: <String>['a/b/']),
          const LuciBuilder(name: 'jkl', repo: 'mno', taskName: 'pqr', flaky: true, runIf: <String>['a'])
        ];
        files = <String>['a'];
        final List<LuciBuilder> result = await getFilteredBuilders(builders, files);
        expect(result.length, 1);
        expect(result[0], builders[1]);
      });
    });
  });
}
