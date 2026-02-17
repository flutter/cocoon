// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PresubmitGuardResponse', () {
    test('fromJson creates a valid object', () {
      final json = {
        'pr_num': 123,
        'check_run_id': 456,
        'author': 'dash',
        'guard_status': 'In Progress',
        'stages': [
          {
            'name': 'fusion',
            'created_at': 123456789,
            'builds': {'test1': 'Succeeded', 'test2': 'In Progress'},
          },
        ],
      };

      final response = PresubmitGuardResponse.fromJson(json);

      expect(response.prNum, 123);
      expect(response.checkRunId, 456);
      expect(response.author, 'dash');
      expect(response.guardStatus, GuardStatus.inProgress);
      expect(response.stages.length, 1);
      expect(response.stages[0].name, 'fusion');
      expect(response.stages[0].builds['test1'], TaskStatus.succeeded);
      expect(response.stages[0].builds['test2'], TaskStatus.inProgress);
    });
  });

  group('PresubmitCheckResponse', () {
    test('fromJson creates a valid object', () {
      final json = {
        'attempt_number': 1,
        'build_name': 'Linux Device Doctor',
        'creation_time': 1620134239000,
        'status': 'Succeeded',
        'summary': 'Check passed',
      };

      final response = PresubmitCheckResponse.fromJson(json);

      expect(response.attemptNumber, 1);
      expect(response.buildName, 'Linux Device Doctor');
      expect(response.creationTime, 1620134239000);
      expect(response.status, 'Succeeded');
      expect(response.summary, 'Check passed');
    });
  });
}
