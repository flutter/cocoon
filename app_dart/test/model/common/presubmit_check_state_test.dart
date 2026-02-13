// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/presubmit_check_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();
  group('PresubmitCheckState', () {
    test('BuildToPresubmitCheckState extension maps build number', () {
      final build = bbv2.Build(
        builder: bbv2.BuilderID(builder: 'linux_test'),
        status: bbv2.Status.SUCCESS,
        number: 12345,
        startTime: bbv2.Timestamp(seconds: Int64(1000)),
        endTime: bbv2.Timestamp(seconds: Int64(2000)),
        summaryMarkdown: 'Summary',
        tags: [bbv2.StringPair(key: 'github_checkrun', value: '123')],
      );

      final state = build.toPresubmitCheckState();
      expect(state.buildName, 'linux_test');
      expect(state.status, TaskStatus.succeeded);
      expect(state.buildNumber, 12345);
    });
  });
}
