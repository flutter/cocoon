// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_service/src/model/bbv2_extension.dart';
import 'package:test/test.dart';

void main() {
  const expectedMapping = {
    bbv2.Status.CANCELED: TaskStatus.cancelled,
    bbv2.Status.FAILURE: TaskStatus.failed,
    bbv2.Status.INFRA_FAILURE: TaskStatus.infraFailure,
    bbv2.Status.SCHEDULED: TaskStatus.inProgress,
    bbv2.Status.STARTED: TaskStatus.inProgress,
    bbv2.Status.SUCCESS: TaskStatus.succeeded,
  };

  for (final MapEntry(key: bbv2, value: expected) in expectedMapping.entries) {
    test('$bbv2 -> $expected', () {
      expect(bbv2.toTaskStatus(), expected);
    });
  }

  test('refuses to convert unknown status', () {
    expect(
      () => bbv2.Status.STATUS_UNSPECIFIED.toTaskStatus(),
      throwsStateError,
    );
  });
}
