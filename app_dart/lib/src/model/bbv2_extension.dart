// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';

extension StatusExtension on bbv2.Status {
  /// Converts from a [bbv2.Status] to a [TaskStatus].
  ///
  /// An unrecognized status is disallowed.
  TaskStatus toTaskStatus() {
    return switch (this) {
      bbv2.Status.SCHEDULED || bbv2.Status.STARTED => TaskStatus.inProgress,
      bbv2.Status.SUCCESS => TaskStatus.succeeded,
      bbv2.Status.CANCELED => TaskStatus.cancelled,
      bbv2.Status.INFRA_FAILURE => TaskStatus.infraFailure,
      bbv2.Status.FAILURE => TaskStatus.failed,
      _ => throw StateError('Unexpected status: $this'),
    };
  }
}
