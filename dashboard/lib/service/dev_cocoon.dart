// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';

import '../logic/qualified_task.dart';
import '../model/build_status_response.pb.dart';
import '../model/commit.pb.dart';
import '../model/commit_status.pb.dart';
import '../model/key.pb.dart';
import '../model/task.pb.dart';
import 'cocoon.dart';

class _PausedCommitStatus {
  _PausedCommitStatus(CocoonResponse<List<CommitStatus>> status)
      : _completer = Completer<CocoonResponse<List<CommitStatus>>>(),
        assert(status != null),
        _pausedStatus = status;

  final Completer<CocoonResponse<List<CommitStatus>>> _completer;
  CocoonResponse<List<CommitStatus>> _pausedStatus;

  bool get isComplete => _pausedStatus == null;

  Future<CocoonResponse<List<CommitStatus>>> get future => _completer.future;

  void update(CocoonResponse<List<CommitStatus>> newStatus) {
    assert(_completer != null);
    assert(_pausedStatus != null);
    _pausedStatus = newStatus;
  }

  void complete() {
    assert(_completer != null && _pausedStatus != null);
    _completer.complete(_pausedStatus);
    _pausedStatus = null;
  }
}

/// [CocoonService] for local development purposes.
///
/// This creates fake data that mimicks what production will send.
class DevelopmentCocoonService implements CocoonService {
  DevelopmentCocoonService(this.now, {this.simulateLoadingDelays = false})
      : _random = math.Random(now.millisecondsSinceEpoch);

  final math.Random _random;

  final DateTime now;

  final bool simulateLoadingDelays;

  _PausedCommitStatus _pausedStatus;
  bool _paused = false;
  bool get paused => _paused;
  set paused(bool pause) {
    if (_paused == pause) {
      return;
    }
    assert(_paused || _pausedStatus == null || _pausedStatus.isComplete);
    if (_pausedStatus != null && !_pausedStatus.isComplete) {
      _pausedStatus.complete();
      _pausedStatus = null;
    }
    _paused = pause;
  }

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus lastCommitStatus,
    String branch,
    String repo,
  }) async {
    final CocoonResponse<List<CommitStatus>> data =
        CocoonResponse<List<CommitStatus>>.data(_createFakeCommitStatuses(lastCommitStatus, repo));
    if (_pausedStatus == null || _pausedStatus.isComplete) {
      _pausedStatus = _PausedCommitStatus(data);
    } else {
      _pausedStatus.update(data);
    }

    if (!_paused) {
      if (simulateLoadingDelays) {
        final _PausedCommitStatus delayedStatus = _pausedStatus;
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!_paused && !delayedStatus.isComplete) {
            delayedStatus.complete();
          }
        });
      } else {
        _pausedStatus.complete();
      }
    }

    return _pausedStatus.future;
  }

  @override
  Future<CocoonResponse<List<String>>> fetchRepos() async {
    return const CocoonResponse<List<String>>.data(<String>[
      'flutter',
      'engine',
      'cocoon',
      'plugins',
    ]);
  }

  @override
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String branch,
    String repo,
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
  Future<CocoonResponse<List<String>>> fetchFlutterBranches() async {
    return const CocoonResponse<List<String>>.data(<String>['master', 'main', 'dev', 'beta', 'stable']);
  }

  @override
  Future<bool> vacuumGitHubCommits(String idToken) async {
    return false;
  }

  @override
  Future<bool> rerunTask(Task task, String accessToken, String repo) async {
    return false;
  }

  static const int _commitGap = 2 * 60 * 1000; // 2 minutes between commits

  List<CommitStatus> _createFakeCommitStatuses(CommitStatus lastCommitStatus, String repo) {
    final int baseTimestamp =
        lastCommitStatus != null ? (lastCommitStatus.commit.timestamp.toInt()) : now.millisecondsSinceEpoch;

    final List<CommitStatus> result = <CommitStatus>[];
    for (int index = 0; index < 25; index += 1) {
      final int commitTimestamp = baseTimestamp - ((index + 1) * _commitGap);
      final math.Random random = math.Random(commitTimestamp);
      final Commit commit = _createFakeCommit(commitTimestamp, random, repo);
      final CommitStatus status = CommitStatus()
        ..branch = defaultBranches[repo]
        ..commit = commit
        ..tasks.addAll(_createFakeTasks(commitTimestamp, commit, random));
      result.add(status);
    }
    return result;
  }

  final List<String> _authors = <String>['alice', 'bob', 'charlie', 'dobb', 'eli', 'fred'];
  final List<int> _messagePrimes = <int>[3, 11, 17, 23, 31, 41, 47, 67, 79];
  final List<String> _words = <String>['fixes', 'issue', 'crash', 'developer', 'blocker', 'intermittent', 'format'];

  Commit _createFakeCommit(int commitTimestamp, math.Random random, String repo) {
    final int author = random.nextInt(_authors.length);
    final int message = commitTimestamp % 37 + author;
    final int messageInc = _messagePrimes[message % _messagePrimes.length];
    return Commit()
      ..key = (RootKey()..child = (Key()..name = '$commitTimestamp'))
      ..author = _authors[author]
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/${2148558 + author}?v=4'
      ..message = List<String>.generate(6, (int i) => _words[(message + i * messageInc) % _words.length]).join(' ')
      ..repository = 'flutter/$repo'
      ..sha = commitTimestamp.hashCode.toRadixString(16).padRight(32, '0')
      ..timestamp = Int64(commitTimestamp)
      ..branch = 'master';
  }

  static const Map<String, int> _repoTaskCount = <String, int>{
    'flutter/cocoon': 3,
    'flutter/flutter': 100,
    'flutter/engine': 20,
    'flutter/plugins': 10,
  };

  List<Task> _createFakeTasks(int commitTimestamp, Commit commit, math.Random random) {
    if (_repoTaskCount.containsKey(commit.repository) == false) {
      throw Exception('Add ${commit.repository} to _repoTaskCount in DevCocoonService');
    }
    return List<Task>.generate(
        _repoTaskCount[commit.repository], (int i) => _createFakeTask(commitTimestamp, i, StageName.luci, random));
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
      ..startTimestamp = Int64(commitTimestamp + (index * 1000 * 60))
      ..endTimestamp = Int64(commitTimestamp + (index * 1000 * 60) + (index * 1000 * 60))
      ..name = 'Linux_android $index'
      ..builderName = 'Linux_android $index'
      ..attempts = attempts
      ..isFlaky = index == now.millisecondsSinceEpoch % 13
      ..requiredCapabilities.add('[linux/android]')
      ..reservedForAgentId = 'linux1'
      ..stageName = stageName
      ..status = status
      ..isTestFlaky = index == now.millisecondsSinceEpoch % 17;

    return task;
  }
}
