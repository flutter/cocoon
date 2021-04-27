// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:cocoon_service/protos.dart';

import '../logic/qualified_task.dart';
import 'cocoon.dart';

/// [CocoonService] for local development purposes.
///
/// This creates fake data that mimicks what production will send.
class DevelopmentCocoonService implements CocoonService {
  DevelopmentCocoonService(this.now) : _random = math.Random(now.millisecondsSinceEpoch);

  final math.Random _random;

  final DateTime now;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus lastCommitStatus,
    String branch,
  }) async {
    return CocoonResponse<List<CommitStatus>>.data(_createFakeCommitStatuses(lastCommitStatus));
  }

  @override
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String branch,
  }) async {
    final bool failed = _random.nextBool();
    final BuildStatusResponse response = BuildStatusResponse()
      ..buildStatus = failed ? EnumBuildStatus.failure : EnumBuildStatus.success;
    if (failed) {
      response.failingTasks.addAll(<String>['failed_task_1', 'failed_task_2']);
    }

    return CocoonResponse<BuildStatusResponse>.data(response);
  }

  @override
  Future<CocoonResponse<List<Agent>>> fetchAgentStatuses() async {
    return CocoonResponse<List<Agent>>.data(_createFakeAgentStatuses());
  }

  @override
  Future<CocoonResponse<List<String>>> fetchFlutterBranches() async {
    return const CocoonResponse<List<String>>.data(<String>['master', 'dev', 'beta', 'stable']);
  }

  @override
  Future<bool> vacuumGitHubCommits(String idToken) async {
    return false;
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
  Future<CocoonResponse<String>> createAgent(String agentId, List<String> capabilities, String idToken) async =>
      const CocoonResponse<String>.data('abc123');

  @override
  Future<void> reserveTask(Agent agent, String idToken) => null;

  static const List<String> _agentKinds = <String>[
    'linux',
    'linux-vm',
    'mac',
    'windows',
  ];

  List<Agent> _createFakeAgentStatuses() {
    return List<Agent>.generate(
      10,
      (int i) => Agent()
        ..agentId = 'fake-${_agentKinds[i % _agentKinds.length]}-${i ~/ _agentKinds.length}'
        ..capabilities.add('dash')
        ..isHealthy = _random.nextBool()
        ..isHidden = false
        ..healthCheckTimestamp = Int64.parseInt(now.millisecondsSinceEpoch.toString())
        ..healthDetails = 'ssh-connectivity: succeeded\n'
            'Last known IP address: flutter-devicelab-linux-vm-1\n\n'
            'android-device-ZY223D6B7B: succeeded\n'
            'has-healthy-devices: succeeded\n'
            'Found 1 healthy devices\n\n'
            'cocoon-authentication: succeeded\n'
            'cocoon-connection: succeeded\n'
            'able-to-perform-health-check: succeeded\n',
    );
  }

  static const int _commitGap = 2 * 60 * 1000; // 2 minutes between commits

  List<CommitStatus> _createFakeCommitStatuses(CommitStatus lastCommitStatus) {
    final int baseTimestamp =
        lastCommitStatus != null ? (lastCommitStatus.commit.timestamp.toInt()) : now.millisecondsSinceEpoch;

    final List<CommitStatus> result = <CommitStatus>[];
    for (int index = 0; index < 25; index += 1) {
      final int commitTimestamp = baseTimestamp - ((index + 1) * _commitGap);
      final math.Random random = math.Random(commitTimestamp);
      final Commit commit = _createFakeCommit(commitTimestamp, random);
      final CommitStatus status = CommitStatus()
        ..branch = 'master'
        ..commit = commit
        ..stages.addAll(_createFakeStages(commitTimestamp, commit, random));
      result.add(status);
    }
    return result;
  }

  final List<String> _authors = <String>['alice', 'bob', 'charlie', 'dobb', 'eli', 'fred'];
  final List<int> _messagePrimes = <int>[3, 11, 17, 23, 31, 41, 47, 67, 79];
  final List<String> _words = <String>['fixes', 'issue', 'crash', 'developer', 'blocker', 'intermittent', 'format'];

  Commit _createFakeCommit(int commitTimestamp, math.Random random) {
    final int author = random.nextInt(_authors.length);
    final int message = commitTimestamp % 37 + author;
    final int messageInc = _messagePrimes[message % _messagePrimes.length];
    return Commit()
      ..key = (RootKey()..child = (Key()..name = '$commitTimestamp'))
      ..author = _authors[author]
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/${2148558 + author}?v=4'
      ..message = List<String>.generate(6, (int i) => _words[(message + i * messageInc) % _words.length]).join(' ')
      ..repository = 'flutter/cocoon'
      ..sha = commitTimestamp.hashCode.toRadixString(16).padRight(32, '0')
      ..timestamp = Int64(commitTimestamp)
      ..branch = 'master';
  }

  static const List<String> _stages = <String>[
    'cirrus',
    'chromebot',
    'devicelab',
    'devicelab_win',
    'devicelab_ios',
  ];
  static const List<int> _stageCount = <int>[
    2,
    3,
    50,
    25,
    30,
  ];

  List<Stage> _createFakeStages(int commitTimestamp, Commit commit, math.Random random) {
    final List<Stage> stages = <Stage>[];
    assert(_stages.length == _stageCount.length);
    for (int stage = 0; stage < _stages.length; stage += 1) {
      stages.add(
        Stage()
          ..commit = commit
          ..name = _stages[stage]
          ..tasks.addAll(List<Task>.generate(
              _stageCount[stage], (int i) => _createFakeTask(commitTimestamp, i, _stages[stage], random))),
      );
    }
    return stages;
  }

  static const List<String> _statuses = <String>[
    'New',
    'In Progress',
    'Succeeded',
    'Succeeded Flaky',
    'Failed',
    'Underperformed',
    'Underperfomed In Progress',
    'Skipped',
  ];

  static const Map<String, int> _minAttempts = <String, int>{
    'New': 0,
    'In Progress': 1,
    'Succeeded': 1,
    'Succeeded Flaky': 1,
    'Failed': 1,
    'Underperformed': 1,
    'Underperfomed In Progress': 1,
    'Skipped': 0,
  };

  static const Map<String, int> _maxAttempts = <String, int>{
    'New': 0,
    'In Progress': 1,
    'Succeeded': 1,
    'Succeeded Flaky': 2,
    'Failed': 2,
    'Underperformed': 2,
    'Underperfomed In Progress': 2,
    'Skipped': 0,
  };

  Task _createFakeTask(int commitTimestamp, int index, String stageName, math.Random random) {
    final int age = (now.millisecondsSinceEpoch - commitTimestamp) ~/ _commitGap;
    assert(age >= 0);
    // The [statusesProbability] list is an list of proportional
    // weights to give each of the values in _statuses when randomly
    // determining the status. So e.g. if one is 150, another 50, and
    // the rest 0, then the first has a 75% chance of being picked,
    // the second a 25% chance, and the rest a 0% chance.
    final List<int> statusesProbability = <int>[
      // bigger = more probable
      math.max(index % 2, 20 - age * 2), // blue
      math.max(0, 10 - age * 2), // spinny
      math.min(10 + age * 2, 100), // green
      math.min(1 + age ~/ 3, 30), // yellow
      if (index % 15 == 0) // red
        5
      else if (index % 25 == 0) // red
        15
      else
        1,
      1, // orange
      1, // orange spinny
      if (index == now.millisecondsSinceEpoch % 20) // white
        math.max(0, 1000 - age * 20)
      else if (index == now.millisecondsSinceEpoch % 22)
        math.max(0, 1000 - age * 10)
      else
        0,
    ];
    // max is the sum of all the values in statusesProbability.
    final int max = statusesProbability.fold(0, (int c, int p) => c + p);
    // weightedIndex is the random number in the range 0 <= weightedIndex < max.
    int weightedIndex = random.nextInt(max);
    // statusIndex is the actual index into _statuses that corresponds
    // to the randomly selected weightedIndex. So if
    // statusesProbability is 10,20,30 and weightedIndex is 15, then
    // the statusIndex will be 1 (corresponding to the second entry,
    // the one with weight 20, since lists are zero-indexed).
    int statusIndex = 0;
    while (weightedIndex > statusesProbability[statusIndex]) {
      weightedIndex -= statusesProbability[statusIndex];
      statusIndex += 1;
    }
    // Finally we get the actual status using statusIndex as an index into _statuses.
    final String status = _statuses[statusIndex];
    final int minAttempts = _minAttempts[status];
    final int maxAttempts = _maxAttempts[status];
    final int attempts = minAttempts + random.nextInt(maxAttempts - minAttempts + 1);
    final Task task = Task()
      ..createTimestamp = Int64(commitTimestamp + index)
      ..startTimestamp = Int64(commitTimestamp + index + 10000)
      ..endTimestamp = Int64(commitTimestamp + index + 10000 + random.nextInt(1000 * 60 * 15))
      ..name = 'task $index'
      ..attempts = attempts
      ..isFlaky = index == now.millisecondsSinceEpoch % 13
      ..requiredCapabilities.add('[linux/android]')
      ..reservedForAgentId = 'linux1'
      ..stageName = stageName
      ..status = status;

    if (stageName == StageName.luci) {
      task
        ..buildNumberList = '$index'
        ..builderName = 'Linux'
        ..luciBucket = 'luci.flutter.prod';
    }

    return task;
  }
}
