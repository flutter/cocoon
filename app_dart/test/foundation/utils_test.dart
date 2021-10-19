// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/service/logging.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';

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
      late MockClient branchHttpClient;

      test('returns branches', () async {
        branchHttpClient = MockClient((_) async => http.Response(branchRegExp, HttpStatus.ok));
        final String branches = await githubFileContent(
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
        final String branches = await githubFileContent(
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

      test('gives up after 3 tries', () async {
        int retry = 0;
        branchHttpClient = MockClient((_) async {
          retry++;
          return http.Response('', HttpStatus.serviceUnavailable);
        });
        final List<LogRecord> records = <LogRecord>[];
        log.onRecord.listen((LogRecord record) => records.add(record));
        await expectLater(
            githubFileContent(
              'branches.txt',
              httpClientProvider: () => branchHttpClient,
              retryOptions: const RetryOptions(
                maxAttempts: 3,
                delayFactor: Duration.zero,
                maxDelay: Duration.zero,
              ),
            ),
            throwsA(isA<HttpException>()));
        expect(retry, 3);
        expect(records.where((LogRecord record) => record.level == Level.WARNING), isNotEmpty);
      });
    });

    group('GetBranches', () {
      late MockClient branchHttpClient;

      test('returns branches', () async {
        branchHttpClient = MockClient((_) async => http.Response(branchRegExp, HttpStatus.ok));
        final Uint8List branches = await getBranches(
          () => branchHttpClient,
          retryOptions: noRetry,
        );
        expect(String.fromCharCodes(branches), 'master,flutter-1.1-candidate.1');
      });

      test('returns master when http request fails', () async {
        branchHttpClient = MockClient((_) async {
          return http.Response('', HttpStatus.serviceUnavailable);
        });
        final Uint8List builders = await getBranches(
          () => branchHttpClient,
          retryOptions: noRetry,
        );
        expect(String.fromCharCodes(builders), 'master');
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
        final RepositorySlug? result = await repoNameForBuilder(builders, 'DoesNotExist');
        expect(result, isNull);
      });

      test('Builder exists', () async {
        final List<LuciBuilder> builders = <LuciBuilder>[
          const LuciBuilder(name: 'Cocoon', repo: 'cocoon', flaky: false)
        ];
        final RepositorySlug result = (await repoNameForBuilder(builders, 'Cocoon'))!;
        expect(result.fullName, equals('flutter/cocoon'));
      });
    });

    group('bigquery', () {
      late FakeTabledataResource tabledataResourceApi;

      setUp(() {
        tabledataResourceApi = FakeTabledataResource();
      });
      test('Insert data to bigquery', () async {
        await insertBigquery('test', <String, dynamic>{'test': 'test'}, tabledataResourceApi);
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
