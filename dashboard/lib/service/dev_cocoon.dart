// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:flutter_dashboard/model/branch.pb.dart';
import 'package:flutter_dashboard/model/task_firestore.pb.dart';

import '../logic/qualified_task.dart';
import '../model/build_status_response.pb.dart';
import '../model/commit.pb.dart';
import '../model/commit_status.pb.dart';
import '../model/commit_tasks_status.pb.dart';
import '../model/key.pb.dart';
import '../model/task.pb.dart';
import 'cocoon.dart';

class _PausedCommitStatus {
  _PausedCommitStatus(CocoonResponse<List<CommitStatus>> status)
      : _completer = Completer<CocoonResponse<List<CommitStatus>>>(),
        _pausedStatus = status;

  final Completer<CocoonResponse<List<CommitStatus>>> _completer;
  CocoonResponse<List<CommitStatus>>? _pausedStatus;

  bool get isComplete => _pausedStatus == null;

  Future<CocoonResponse<List<CommitStatus>>> get future => _completer.future;

  void update(CocoonResponse<List<CommitStatus>> newStatus) {
    assert(_pausedStatus != null);
    _pausedStatus = newStatus;
  }

  void complete() {
    assert(_pausedStatus != null);
    _completer.complete(_pausedStatus!);
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

  _PausedCommitStatus? _pausedStatus;
  bool _paused = false;
  bool get paused => _paused;
  set paused(bool pause) {
    if (_paused == pause) {
      return;
    }
    assert(_paused || _pausedStatus == null || _pausedStatus!.isComplete);
    if (_pausedStatus != null && !_pausedStatus!.isComplete) {
      _pausedStatus!.complete();
      _pausedStatus = null;
    }
    _paused = pause;
  }

  @override
  Future<CocoonResponse<List<CommitTasksStatus>>> fetchCommitStatusesFirestore({
    CommitStatus? lastCommitStatus,
    String? branch,
    required String repo,
  }) async {
    // TODO(keyonghan): to be impelemented when logics are switched to Firestore.
    return const CocoonResponse<List<CommitTasksStatus>>.error('');
  }

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus? lastCommitStatus,
    String? branch,
    required String repo,
  }) async {
    final CocoonResponse<List<CommitStatus>> data =
        CocoonResponse<List<CommitStatus>>.data(_createFakeCommitStatuses(lastCommitStatus, repo));
    if (_pausedStatus == null || _pausedStatus!.isComplete) {
      _pausedStatus = _PausedCommitStatus(data);
    } else {
      _pausedStatus!.update(data);
    }

    if (!_paused) {
      if (simulateLoadingDelays) {
        final _PausedCommitStatus? delayedStatus = _pausedStatus;
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!_paused && !delayedStatus!.isComplete) {
            delayedStatus.complete();
          }
        });
      } else {
        _pausedStatus!.complete();
      }
    }

    return _pausedStatus!.future;
  }

  static const List<String> _repos = <String>[
    'flutter',
    'engine',
    'cocoon',
  ];

  @override
  Future<CocoonResponse<List<String>>> fetchRepos() async {
    return const CocoonResponse<List<String>>.data(_repos);
  }

  @override
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String? branch,
    required String repo,
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
  Future<CocoonResponse<List<Branch>>> fetchFlutterBranches() async {
    final List<Branch> fakeBranches = <Branch>[
      Branch()
        ..channel = 'HEAD'
        ..branch = 'master',
      Branch()
        ..channel = 'stable'
        ..branch = 'flutter-3.13-candidate.0',
      Branch()
        ..channel = 'beta'
        ..branch = 'flutter-3.15-candidate.5',
      Branch()
        ..channel = 'dev'
        ..branch = 'flutter-3.15-candidate.12',
    ];
    return CocoonResponse<List<Branch>>.data(fakeBranches);
  }

  @override
  Future<bool> vacuumGitHubCommits(String idToken) async {
    return false;
  }

  @override
  Future<CocoonResponse<bool>> rerunTask(TaskDocument task, String? accessToken, String repo) async {
    return const CocoonResponse<bool>.error(
      'Unable to retry against fake data. Try building the app to use prod data.',
    );
  }

  static const int _commitGap = 2 * 60 * 1000; // 2 minutes between commits

  List<CommitStatus> _createFakeCommitStatuses(CommitStatus? lastCommitStatus, String repo) {
    final int baseTimestamp =
        lastCommitStatus != null ? (lastCommitStatus.commit.timestamp.toInt()) : now.millisecondsSinceEpoch;

    final List<CommitStatus> result = <CommitStatus>[];
    for (int index = 0; index < 25; index += 1) {
      final int commitTimestamp = baseTimestamp - ((index + 1) * _commitGap);
      final math.Random random = math.Random(commitTimestamp);
      final Commit commit = _createFakeCommit(commitTimestamp, random, repo, _commits[index]);
      final CommitStatus status = CommitStatus()
        ..branch = defaultBranches[repo]!
        ..commit = commit
        ..tasks.addAll(_createFakeTasks(commitTimestamp, commit, random));
      result.add(status);
    }
    return result;
  }

  final List<String> _authors = <String>['alice', 'bob', 'charlie', 'dobb', 'eli', 'fred'];
  final List<int> _messagePrimes = <int>[3, 11, 17, 23, 31, 41, 47, 67, 79];
  final List<String> _words = <String>['fixes', 'issue', 'crash', 'developer', 'blocker', 'intermittent', 'format'];
  final List<String> _commits = <String>[
    '2d22b5e85f986f3fa2cf1bfaf085905c2182c270',
    '2fd76f920a38e4384248173d05ee482d5aeaf4c5',
    '77238bc7bf35489df03bc00ce2b2231a1afe6b06',
    '01d87b7a802e6ea388a066e773b1af3dace44053',
    '754039ae0cc524db1052da0f22c9275e32fe4f54',
    '1f5e006a398fa5d0e59f78cd5071e2532d2fe438',
    'a798b24044d567df62b8693b179932a8364c8dd8',
    '4389a8a3dbe1ed4c6a643641e95d7759f2158d9e',
    'c05e886884ec9adff2f43b87dbcb02e3507d971b',
    'a2acc46447cdfcd6628a897dea27ff64849bfc99',
    'd31d67ffb38fbd09ecf0a11ad5f6fd433cec9c9f',
    'e303d2c71c956c9c1eb7bf81473aac20d756eb75',
    '789f6bb335fe31de5d9c6adbab2fc169030a057f',
    'c97f0670658e04f096a3e57b20fa8241306ffcaa',
    'e8e31198861b5f53f04900bdf9a54e8bf6b7d597',
    '434a0a7d3c4c3bc633e06de7707ef590c54c20c3',
    'e7fca29b3f0408c7c1726e270a5aba0e28e74090',
    'dd6f94d8573a77506a122899a0592a956ac57bec',
    'cb19ec23d79b9d422f577722e5a14253fdcaea71',
    '4cb8c6498aedfd2ff0f89e34eb5da993a77392bd',
    'de892884aa089f22aced4d19a71b6a1d521c8db6',
    '214470ceb026525fa225d52dfe7d27db2c4ddf31',
    'e0f4628b4379286c433bab020b9e193fdc437d05',
    'be5975cb0b7fcad7ab2c3122a8df3d541befdeab',
    '06f7ab60d4914e00b342f098e1ef3e43e501b469',
    'e1005bea192673e54faa0c769d9f0fb7439a09b4',
    'e22d7f6bf2e1e1969dd963d39ad32c756fb0f20e',
    'f4b4b20bb27cbbd1c42eee7b17ce39c5819dc818',
    'd717ed969b6a477499eb3cf823c78dbe654ca709',
    '6a8d6a42b4c9f4b72caf0a3b808e50909686a2b7',
    'afaa9bfa5d26ab419f791d5ca97d602ec52a30a5',
    'f553212d9bfbc6e70c0d6a4ac3fe71208bb77ca1',
    'c35f8b79f4a5103603ceaaa14d1df3857a166fa1',
    '46447341838d480966926d0b32771e281af1c885',
    '4e3330081d4e0a3e109cf1cfb514072a90b999d7',
    '4199ef93c3184c29362520ea5292d854a8728494',
    'a0538938974c60cb9249acf8f0588c3df3c0e4b1',
    '49cac0b6c1e0d7d1d04865c328c8cbe5c8e0cda2',
    '97e3cc6295515f8292f5f57868506c70446594c3',
    'c94e577ef3b0ab48255633c63f0143d9e3eab6f8',
    '17d9af726fb6e4a4a8cc4f1becfc11dc9d4db96c',
    '4af6ec81ad538e3da23ee88cba65ed8687a72ea3',
    '69cb45166d2f4f61069e1f1a975dab3f48bed832',
    'ae227082570f75b614bb29593911ada5137654ad',
    '882b9fa44962df0b80d9a25b2553796bd4eba2ff',
    'e1f5c4c7178c34ce561c493b558df7450995a60c',
    '56d7272cd497c73502ec5a09bdf69b4c7ecbfd74',
    '36a99b302f7348848ec477ce867a8b78656d9c6c',
    '48be7a01565289f44c2c9d4ff1436800c52acf75',
    '422cb82e01ee0192256a05217102f45f2f74551d',
    'f8744d10460abae3d75e92336b3bb264bb78cc8c',
    '5000f246c8c568547c551b11e4b72acd0179e73c',
    '52c09522b288766a42900aa73f77216907d16b23',
    '61adb59fc097335b45b23fc884a78362b71a3e9b',
    'b81c3c58e5a6c45bc8728024068291a7e5f19c1a',
    'dec394e5401b62024ed71253e900c25a06eb46f9',
    'fbe142d2cb60fb981521cfe72961642d69db8784',
    '24a9c4557e0366945c179433fab8434c2c8ee59f',
    'ccc28f607ae11fe79c39c42d88798c19b1388af9',
    'd4d5ca665e56063fdd37d42d2192c64151915454',
    '4273fc07c3e8a36726087becdf331f7d63fc7e66',
    '5e0380895cc8e34a6a58f238b7fd33b9e0f027fe',
    '146908e48a8a9f92f59fae86a7a4ff28c0ce9109',
    '2779a449026423bc0f50a10eead2d9f3720b825c',
    'ff9b954908341360ffb39f5eee2857172a29c0e5',
    'b00b6d146c4f4af1d28260a3f28abd15f0105221',
    '4ffd03df44741d73877a0848935eea0d6cbfc1e9',
    'c2c5b73aaae2583cc235319e53200e0e15cda438',
    'b7b370faf46f4c682827fbb3967e1ef117b3b0d1',
    'bc6c9ac81e5909408518568729c2c3a147402928',
    'ba1aa77c5bc5fe545b245f2b1883af3dfeeae6c0',
    '97a7060a7e28ab1d13cb2f4ca90be624b417168e',
    '3df1da69ffcb4e00cf13c65c9f0497a56413e5e9',
    'ebb13b4ed0cb41814839d4084c064e62526b2ec0',
    '70b9d50722307f0f45ceed01d421d6a425e95291',
    '3f81ca7b73f21ca9b449c147942fbe4fcd31450d',
    '86d490939df232966dc6ba363ebc0baaac364701',
    '6ba51f3f61025543d66e59c2c1ae3d1b37d5d8d6',
    'b728942e1c9a9046c1a5c8d8a25a644d0db7160c',
    '920819252a398c0e3da9b6017b110ee047c1748e',
    'd7c114d803b1365ea3a975c9600fc8cfd9efb9d4',
    '792aa82143bb12e97f396cb2a462ad617dbd22bc',
  ];

  Commit _createFakeCommit(int commitTimestamp, math.Random random, String repo, String commitSha) {
    final int author = random.nextInt(_authors.length);
    final int message = commitTimestamp % 37 + author;
    final int messageInc = _messagePrimes[message % _messagePrimes.length];
    return Commit()
      ..key = (RootKey()..child = (Key()..name = '$commitTimestamp'))
      ..author = _authors[author]
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/${2148558 + author}?v=4'
      ..message = List<String>.generate(6, (int i) => _words[(message + i * messageInc) % _words.length]).join(' ')
      ..repository = 'flutter/$repo'
      ..sha = commitSha
      ..timestamp = Int64(commitTimestamp)
      ..branch = 'master';
  }

  static const Map<String, int> _repoTaskCount = <String, int>{
    'flutter/cocoon': 3,
    'flutter/flutter': 100,
    'flutter/engine': 20,
  };

  List<Task> _createFakeTasks(int commitTimestamp, Commit commit, math.Random random) {
    if (_repoTaskCount.containsKey(commit.repository) == false) {
      throw Exception('Add ${commit.repository} to _repoTaskCount in DevCocoonService');
    }
    return List<Task>.generate(
      _repoTaskCount[commit.repository]!,
      (int i) => _createFakeTask(commitTimestamp, i, StageName.luci, random),
    );
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
    final int minAttempts = _minAttempts[status]!;
    final int maxAttempts = _maxAttempts[status]!;
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
