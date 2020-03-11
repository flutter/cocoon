// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handlers/utils.dart';

import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

const String branchRegExp = '''
      master
      ^flutter-[0-9]+\.[0-9]+-candidate\.[0-9]+
      ''';

void main() {
  group('GetBranches', () {
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

  group('GitHubBackoffCalculator', () {
    test('twoSecondLinearBackoff', () {
      expect(twoSecondLinearBackoff(0), const Duration(seconds: 2));
      expect(twoSecondLinearBackoff(1), const Duration(seconds: 4));
      expect(twoSecondLinearBackoff(2), const Duration(seconds: 6));
      expect(twoSecondLinearBackoff(3), const Duration(seconds: 8));
    });
  });
}
