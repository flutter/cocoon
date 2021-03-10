// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import 'commit.dart';
import 'stage.dart';

part 'commit_status.g.dart';

/// Class that holds the status for all tasks corresponding to a particular
/// commit.
///
/// Tasks may still be running, and thus their status is subject to change.
/// Put another way, this class holds information that is a snapshot in time.
@JsonSerializable()
class CommitStatus {
  CommitStatus({this.commit, this.stages});

  factory CommitStatus.fromJson(Map<String, dynamic> json) => _$CommitStatusFromJson(json);

  final Commit commit;
  final List<Stage> stages;

  Map<String, dynamic> toJson() => _$CommitStatusToJson(this);
}