// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/refresh_cirrus_status.dart';
import 'package:test/test.dart';

void main() {
  group('RefreshCirrusStatus', () {
    Map<String, dynamic>? data;
    final List<Map<String, dynamic>> tasks = <Map<String, dynamic>>[];
    setUp(() {
      data = dataWithMultipleBuilds;
    });
    test('returns first build result', () async {
      final CirrusResult cirrusResult = getFirstBuildResult(data, tasks);
      expect(cirrusResult.id, "4532390054854656");
      expect(cirrusResult.tasks[0]['id'] as String, "4566569471705088");
    });
  });
}

Map<String, dynamic> dataWithMultipleBuilds = <String, dynamic>{
  "searchBuilds": [
    {
      "id": "4532390054854656",
      "branch": "dependabot/github_actions/ossf/scorecard-action-1.0.4",
      "latestGroupTasks": [
        {"id": "4566569471705088", "name": "format+analyze", "status": "COMPLETED"},
        {"id": "5692469378547712", "name": "publishable", "status": "COMPLETED"},
      ],
    },
    {
      "id": "6393714829426688",
      "branch": "dependabot/github_actions/ossf/scorecard-action-1.0.4",
      "latestGroupTasks": [
        {"id": "4930474559668224", "name": "format+analyze", "status": "COMPLETED"},
        {"id": "4971160919080960", "name": "publishable", "status": "COMPLETED"},
      ],
    }
  ],
};
