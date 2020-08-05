// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/foundation/utils.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

const String branchRegExp = '''
      master
      flutter-1.1-candidate.1
      ''';
const String luciBuilders = '''
      {
        "builders":[
            {
              "name":"Cocoon",
              "repo":"cocoon"
            }, {
              "name":"Cocoon2",
              "repo":"cocoon"
            }
        ]
      }
      ''';

void main() {
  group('Test utils', () {
    group('LoadBranches', () {
      FakeHttpClient branchHttpClient;
      FakeLogging log;

      setUp(() {
        branchHttpClient = FakeHttpClient();
        log = FakeLogging();
      });

      test('returns branches', () async {
        branchHttpClient.request.response.body = branchRegExp;
        final String branches =
            await remoteFileContent(() => branchHttpClient, log, (int attempt) => Duration.zero, 'branches.txt');
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
        final String branches =
            await remoteFileContent(() => branchHttpClient, log, (int attempt) => Duration.zero, 'branches.txt');
        final List<String> branchList = branches.split('\n').map((String branch) => branch.trim()).toList();
        branchList.removeWhere((String branch) => branch.isEmpty);
        expect(retry, 2);
        expect(branchList, <String>['master', 'flutter-1.1-candidate.1']);
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
      });

      test('gives up branches download after 3 tries', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
        branchHttpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
        branchHttpClient.request.response.body = branchRegExp;
        final String branches =
            await remoteFileContent(() => branchHttpClient, log, (int attempt) => Duration.zero, 'branches.txt');
        expect(branches, null);
        expect(retry, 3);
        expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isNotEmpty);
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
        final Uint8List branches = await getBranches(() => branchHttpClient, log, (int attempt) => Duration.zero);
        expect(String.fromCharCodes(branches), 'master,flutter-1.1-candidate.1');
      });

      test('returns master when http request fails', () async {
        int retry = 0;
        branchHttpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
        branchHttpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
        branchHttpClient.request.response.body = luciBuilders;
        final Uint8List builders = await getBranches(() => branchHttpClient, log, (int attempt) => Duration.zero);
        expect(String.fromCharCodes(builders), 'master');
      });
    });

    group('GetBuilders', () {
      FakeHttpClient lucBuilderHttpClient;
      FakeLogging log;

      setUp(() {
        lucBuilderHttpClient = FakeHttpClient();
        log = FakeLogging();
      });
      test('returns luci builders', () async {
        lucBuilderHttpClient.request.response.body = luciBuilders;
        final List<Map<String, dynamic>> builders =
            await getBuilders(() => lucBuilderHttpClient, log, (int attempt) => Duration.zero, 'try');
        expect(builders.length, 2);
        expect(builders[0]['name'], 'Cocoon');
        expect(builders[0]['repo'], 'cocoon');
      });

      test('logs error and returns empty list when json file is invalid', () async {
        lucBuilderHttpClient.request.response.body = '{"builders":[';
        final List<Map<String, dynamic>> builders =
            await getBuilders(() => lucBuilderHttpClient, log, (int attempt) => Duration.zero, 'try');
        expect(log.records.where(hasLevel(LogLevel.ERROR)), isNotEmpty);
        expect(builders.length, 0);
      });

      test('returns empty list when http request fails', () async {
        int retry = 0;
        lucBuilderHttpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
        lucBuilderHttpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
        lucBuilderHttpClient.request.response.body = luciBuilders;
        final List<Map<String, dynamic>> builders =
            await getBuilders(() => lucBuilderHttpClient, log, (int attempt) => Duration.zero, 'try');
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
        final List<Map<String, dynamic>> builders = <Map<String, dynamic>>[];
        final RepositorySlug result = await repoNameForBuilder(builders, 'DoesNotExist');
        expect(result, isNull);
      });

      test('Builder exists', () async {
        final List<Map<String, dynamic>> builders = <Map<String, dynamic>>[
          <String, String>{'name': 'Cocoon', 'repo': 'cocoon'}
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
  });
}
