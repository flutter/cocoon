// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:fixnum/fixnum.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;

import 'cocoon.dart';

/// [CocoonService] for local development purposes.
///
/// This creates fake data that mimicks what production will send.
class FakeCocoonService implements CocoonService {
  FakeCocoonService({Random rand}) : random = rand ?? Random();

  final Random random;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses() async {
    return CocoonResponse<List<CommitStatus>>()
      ..data = _createFakeCommitStatuses();
  }

  @override
  Future<CocoonResponse<bool>> fetchTreeBuildStatus() async {
    return CocoonResponse<bool>()
      ..data = false
      ..error = 'random error';

    // return CocoonResponse<bool>()..data = random.nextBool();
  }

  @override
  Future<bool> rerunTask(Task task, String accessToken) async {
    return false;
  }

  @override
  Future<bool> downloadLog(Task task, String idToken, String commitSha) async {
    return false;
  }

  List<CommitStatus> _createFakeCommitStatuses() {
    final List<CommitStatus> stats = <CommitStatus>[];

    final int baseTimestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < 100; i++) {
      final Commit commit = _createFakeCommit(i, baseTimestamp);

      final CommitStatus status = CommitStatus()
        ..commit = commit
        ..stages.addAll(_createFakeStages(i, commit));

      stats.add(status);
    }

    return stats;
  }

  Commit _createFakeCommit(int index, int baseTimestamp) {
    return Commit()
      ..author = 'Author McAuthory $index'
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/2148558?v=4'
      ..repository = 'flutter/cocoon'
      ..sha = 'Sha Shank Hash $index'
      ..timestamp = Int64(baseTimestamp - (index * 100));
  }

  List<Stage> _createFakeStages(int index, Commit commit) {
    final List<Stage> stages = <Stage>[];

    stages.add(Stage()
      ..commit = commit
      ..name = 'devicelab'
      ..tasks.addAll(
          List<Task>.generate(40, (int i) => _createFakeTask(i, 'devicelab'))));

    stages.add(Stage()
      ..commit = commit
      ..name = 'devicelab_win'
      ..tasks.addAll(List<Task>.generate(
          30, (int i) => _createFakeTask(i, 'devicelab_win'))));

    return stages;
  }

  Task _createFakeTask(int index, String stageName) {
    return Task()
      ..createTimestamp = Int64(index)
      ..startTimestamp = Int64(index + 1)
      ..endTimestamp = Int64(index + 2)
      ..name = 'task $index'
      ..attempts = index % 3
      ..isFlaky = false
      ..requiredCapabilities.add('[linux/android]')
      ..reservedForAgentId = 'linux1'
      ..stageName = stageName
      ..status = 'Succeeded';
  }
}
