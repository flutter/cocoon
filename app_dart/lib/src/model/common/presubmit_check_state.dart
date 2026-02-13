// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'presubmit_check_state.dart';
library;

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';

import '../../service/luci_build_service/build_tags.dart';
import '../bbv2_extension.dart';

/// Represents the current state of a check run.
class PresubmitCheckState {
  final String buildName;
  final TaskStatus status;
  final int attemptNumber; //static int _currentAttempt(BuildTags buildTags)
  final int? startTime;
  final int? endTime;
  final String? summary;
  final int? buildNumber;

  const PresubmitCheckState({
    required this.buildName,
    required this.status,
    required this.attemptNumber,
    this.startTime,
    this.endTime,
    this.summary,
    this.buildNumber,
  });
}

extension BuildToPresubmitCheckState on bbv2.Build {
  PresubmitCheckState toPresubmitCheckState() => PresubmitCheckState(
    buildName: builder.builder,
    status: status.toTaskStatus(),
    attemptNumber: BuildTags.fromStringPairs(tags).currentAttempt,
    startTime: startTime.toDateTime().microsecondsSinceEpoch,
    endTime: endTime.toDateTime().microsecondsSinceEpoch,
    summary: summaryMarkdown,
    buildNumber: number,
  );
}
