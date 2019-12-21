// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:fixnum/fixnum.dart';

import 'package:cocoon_service/protos.dart';

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
    return CocoonResponse<bool>()..data = random.nextBool();
  }

  @override
  Future<CocoonResponse<List<Agent>>> fetchAgentStatuses() async {
    return CocoonResponse<List<Agent>>()..data = _createFakeAgentStatuses();
  }

  @override
  Future<bool> rerunTask(Task task, String accessToken) async {
    return false;
  }

  @override
  Future<bool> downloadLog(Task task, String idToken, String commitSha) async {
    return false;
  }

  @override
  Future<String> createAgent(
          String agentId, List<String> capabilities, String idToken) async =>
      'abc123';

  List<Agent> _createFakeAgentStatuses() {
    return List<Agent>.generate(
      10,
      (int i) => Agent()
        ..agentId = 'dash-test-$i'
        ..capabilities.add('moral support')
        ..isHealthy = true
        ..isHidden = false
        ..healthCheckTimestamp =
            Int64.parseInt(DateTime.now().millisecondsSinceEpoch.toString())
        ..healthDetails =
            'ssh-connectivity: succeeded\n'
            'Last known IP address: 192.168.1.29\n\n'
            'android-device-ZY223D6B7B: succeeded\n'
            'has-healthy-devices: succeeded\n'
            'Found 1 healthy devices\n\n'
            'cocoon-authentication: succeeded\n'
            'cocoon-connection: succeeded\n'
            'able-to-perform-health-check: succeeded\n',
    );
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
