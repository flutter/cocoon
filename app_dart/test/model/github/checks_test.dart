// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:cocoon_service/src/model/github/checks.dart';
import 'package:github/github.dart' show PullRequest;
import 'package:test/test.dart';

import 'checks_test_data.dart';

void main() {
  group('CheckSuiteEvent', () {
    test('deserialize', () async {
      final CheckSuiteEvent checkSuiteEvent =
          CheckSuiteEvent.fromJson(json.decode(checkSuiteString) as Map<String, dynamic>);
      // Top level properties.
      expect(checkSuiteEvent.action, 'requested');
      expect(checkSuiteEvent.checkSuite, isA<CheckSuite>());
      final CheckSuite suite = checkSuiteEvent.checkSuite;
      // CheckSuite properties.
      expect(suite.headSha, equals('dabc07b74c555c9952f7b63e139f2bb83b75250f'));
      expect(suite.headBranch, equals('update_licenses'));
      // PullRequestProperties.
      expect(suite.pullRequests, hasLength(1));
      final PullRequest pullRequest = suite.pullRequests[0];
      expect(pullRequest.base.ref, equals('master'));
      expect(pullRequest.base.sha, equals('cc430b2e8d6448dfbacf5bcbbd6160cd1fe9dc0b'));
      expect(pullRequest.base.repo.name, equals('cocoon'));
      expect(pullRequest.head.ref, equals('update_licenses'));
      expect(pullRequest.head.sha, equals('5763f4c2b3b5e529f4b35c655761a7e818eced2e'));
      expect(pullRequest.head.repo.name, equals('cocoon'));
    });
  });
  group('CheckRunEvent', () {
    test('deserialize', () async {
      final CheckRunEvent checkRunEvent = CheckRunEvent.fromJson(json.decode(checkRunString) as Map<String, dynamic>);
      // Top level properties.
      expect(checkRunEvent.action, 'rerequested');
      expect(checkRunEvent.checkRun, isA<CheckRun>());
      // CheckSuite properties.
      final CheckRun checkRun = checkRunEvent.checkRun;
      expect(checkRun.headSha, equals('66d6bd9a3f79a36fe4f5178ccefbc781488a596c'));
      expect(checkRun.checkSuite.headBranch, equals('independent_agent'));
      // PullRequestProperties.
      expect(checkRun.pullRequests, hasLength(1));
      final PullRequest pullRequest = checkRun.pullRequests[0];
      expect(pullRequest.base.ref, equals('master'));
      expect(pullRequest.base.sha, equals('96b953d99588ade4a2b5e9c920813f8f3841b7fb'));
      expect(pullRequest.base.repo.name, equals('cocoon'));
      expect(pullRequest.head.ref, equals('independent_agent'));
      expect(pullRequest.head.sha, equals('66d6bd9a3f79a36fe4f5178ccefbc781488a596c'));
      expect(pullRequest.head.repo.name, equals('cocoon'));
    });
  });
}
