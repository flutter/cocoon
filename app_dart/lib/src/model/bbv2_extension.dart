// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bb;
import 'package:cocoon_common/task_status.dart';

extension StatusExtension on bb.Status {
  /// Converts from a [bb.Status] to a [TaskStatus].
  ///
  /// An unrecognized status is disallowed.
  TaskStatus toTaskStatus() {
    return switch (this) {
      bb.Status.SCHEDULED || bb.Status.STARTED => TaskStatus.inProgress,
      bb.Status.SUCCESS => TaskStatus.succeeded,
      bb.Status.CANCELED => TaskStatus.cancelled,
      bb.Status.INFRA_FAILURE => TaskStatus.infraFailure,
      bb.Status.FAILURE => TaskStatus.failed,
      _ => throw StateError('Unexpected status: $this'),
    };
  }
}

extension TaskFailedExtension on bb.Status {
  bool isTaskFailed() => switch (this) {
    bb.Status.FAILURE || bb.Status.CANCELED || bb.Status.INFRA_FAILURE => true,
    _ => false,
  };
}
