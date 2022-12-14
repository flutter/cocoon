// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/service/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/utilities/entity_generators.dart';

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

    group('GitHubBackoffCalculator', () {
      test('twoSecondLinearBackoff', () {
        expect(twoSecondLinearBackoff(0), const Duration(seconds: 2));
        expect(twoSecondLinearBackoff(1), const Duration(seconds: 4));
        expect(twoSecondLinearBackoff(2), const Duration(seconds: 6));
        expect(twoSecondLinearBackoff(3), const Duration(seconds: 8));
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
      List<Target> targets;

      test('does not return builders when run_if does not match any file', () async {
        targets = <Target>[
          generateTarget(1, runIf: <String>['d/']),
        ];
        files = <String>['a/b', 'c/d'];
        final List<Target> result = await getTargetsToRun(targets, files);
        expect(result.isEmpty, isTrue);
      });

      test('returns builders when run_if is null', () async {
        files = <String>['a/b', 'c/d'];
        targets = <Target>[generateTarget(1)];
        final List<Target> result = await getTargetsToRun(targets, files);
        expect(result, targets);
      });

      test('returns builders when run_if matches files', () async {
        files = <String>['a/b', 'c/d'];
        targets = <Target>[
          generateTarget(1, runIf: <String>['a/'])
        ];
        final List<Target> result = await getTargetsToRun(targets, files);
        expect(result, targets);
      });

      test('returns builders when run_if matches files with **', () async {
        targets = <Target>[
          generateTarget(1, runIf: <String>['a/**']),
        ];
        files = <String>['a/b', 'c/d'];
        final List<Target> result = await getTargetsToRun(targets, files);
        expect(result, targets);
      });

      test('returns builders when run_if matches files with both * and **', () async {
        targets = <Target>[
          generateTarget(1, runIf: <String>['a/b*c/**']),
        ];
        files = <String>['a/baddsc/defg', 'c/d'];
        final List<Target> result = await getTargetsToRun(targets, files);
        expect(result, targets);
      });

      test('returns correct builders when file and folder share the same name', () async {
        targets = <Target>[
          generateTarget(1, runIf: <String>['a/b/']),
          generateTarget(2, runIf: <String>['a']),
        ];
        files = <String>['a'];
        final List<Target> result = await getTargetsToRun(targets, files);
        expect(result.length, 1);
        expect(result.single, targets[1]);
      });
    });
  });
}
