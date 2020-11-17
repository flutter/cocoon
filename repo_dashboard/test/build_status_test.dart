// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:repository_dashboard/models/build_status.dart';

void main() {
  group('Build status', () {
    test('equals', () {
      const CommitTestResult commitTestResult1 = CommitTestResult(failingTests: <String>['test1', 'test2']);
      const CommitTestResult commitTestResult2 = CommitTestResult(failingTests: <String>['test2', 'test1']);
      BuildStatus buildStatus1 = const BuildStatus(
          anticipatedBuildStatus: 'Build',
          failingAgents: <String>['mac1', 'mac2'],
          commitTestResults: <CommitTestResult>[commitTestResult1]);
      BuildStatus buildStatus2 = const BuildStatus(
          anticipatedBuildStatus: 'Build',
          failingAgents: <String>['mac1', 'mac2'],
          commitTestResults: <CommitTestResult>[commitTestResult2]);
      BuildStatus buildStatus3 = const BuildStatus(
          anticipatedBuildStatus: 'Build',
          failingAgents: <String>['mac2', 'mac1'],
          commitTestResults: <CommitTestResult>[commitTestResult1]);
      expect(buildStatus1 == buildStatus1, true);
      expect(buildStatus1 == buildStatus2, false);
      expect(buildStatus2 == buildStatus2, true);
      expect(buildStatus3 == buildStatus3, true);
      expect(buildStatus3 == buildStatus1, false);
      expect(buildStatus3 == buildStatus2, false);
    });
  });
}
