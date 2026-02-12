// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' as g;

import 'cocoon.dart';
import 'scenarios.dart';

/// Seeder to populate [IntegrationServer] with fake data.
class DataSeeder {
  DataSeeder(this._server, {this.scenario = Scenario.realistic});

  final IntegrationServer _server;
  final Scenario scenario;

  /// Seeds the [IntegrationServer] with initial data.
  void seed({DateTime? now}) {
    if (scenario == Scenario.empty) {
      return;
    }

    // Use a fixed seed for reproducibility in tests, matching DevelopmentCocoonService
    now ??= DateTime.now();
    final random = math.Random(now.millisecondsSinceEpoch);

    // Seed Commits and Tasks
    for (final repo in ['flutter', 'cocoon']) {
      final branch = defaultBranches[repo]!;
      _seedCommitStatuses(now, random, repo, branch);
    }

    // Seed Tree Status Changes
    _seedTreeStatusChanges(now);

    // Seed Suppressed Tests
    _seedSuppressedTests(now);

    // Seed Presubmit Data
    _seedPresubmitData(now);
  }

  void _seedPresubmitData(DateTime now) {
    final guards = <PresubmitGuard>[];
    final checks = <PresubmitCheck>[];

    // cafe5_1_mock_sha
    guards.add(
      _createPresubmitGuard(
        commitSha: 'cafe5_1_mock_sha',
        checkRunId: 456,
        pullRequestId: 123,
        author: _authors[0],
        stage: CiStage.fusionTests,
        creationTime: now.millisecondsSinceEpoch - 100000,
        builds: {
          'Mac mac_host_engine': TaskStatus.infraFailure,
          'Mac mac_ios_engine': TaskStatus.cancelled,
          'Linux linux_android_aot_engine': TaskStatus.infraFailure,
        },
      ),
    );
    for (final buildName in [
      'Mac mac_host_engine',
      'Mac mac_ios_engine',
      'Linux linux_android_aot_engine',
    ]) {
      checks.add(
        _createPresubmitCheck(
          checkRunId: 456,
          buildName: buildName,
          status: TaskStatus.infraFailure,
          creationTime: now.millisecondsSinceEpoch - 100000,
        ),
      );
    }

    // face5_2_mock_sha
    guards.add(
      _createPresubmitGuard(
        commitSha: 'face5_2_mock_sha',
        checkRunId: 789,
        pullRequestId: 123,
        author: _authors[1],
        stage: CiStage.fusionTests,
        creationTime: now.millisecondsSinceEpoch - 50000,
        builds: {
          'Mac mac_host_engine': TaskStatus.succeeded,
          'Mac mac_ios_engine': TaskStatus.cancelled,
          'Linux linux_android_aot_engine': TaskStatus.succeeded,
        },
      ),
    );
    guards.add(
      _createPresubmitGuard(
        commitSha: 'face5_2_mock_sha',
        checkRunId: 789,
        pullRequestId: 123,
        author: _authors[1],
        stage: CiStage.fusionEngineBuild,
        creationTime: now.millisecondsSinceEpoch - 40000,
        builds: {
          'Linux framework_tests': TaskStatus.succeeded,
          'Mac framework_tests': TaskStatus.failed,
          'Linux android framework_tests': TaskStatus.skipped,
          'Windows framework_tests': TaskStatus.failed,
        },
      ),
    );

    // decaf_3_mock_sha
    guards.add(
      _createPresubmitGuard(
        commitSha: 'decaf_3_mock_sha',
        checkRunId: 1011,
        pullRequestId: 123,
        author: _authors[2],
        stage: CiStage.fusionEngineBuild,
        creationTime: now.millisecondsSinceEpoch,
        builds: {
          'Mac mac_host_engine': TaskStatus.succeeded,
          'Mac mac_ios_engine': TaskStatus.cancelled,
          'Linux linux_android_aot_engine': TaskStatus.succeeded,
        },
      ),
    );
    guards.add(
      _createPresubmitGuard(
        commitSha: 'decaf_3_mock_sha',
        checkRunId: 1011,
        pullRequestId: 123,
        author: _authors[2],
        stage: CiStage.fusionTests,
        creationTime: now.millisecondsSinceEpoch,
        builds: {
          'Linux framework_tests': TaskStatus.succeeded,
          'Mac framework_tests': TaskStatus.waitingForBackfill,
          'Linux android framework_tests': TaskStatus.skipped,
          'Windows framework_tests': TaskStatus.inProgress,
        },
      ),
    );

    // deafcab_mock_sha
    guards.add(
      _createPresubmitGuard(
        commitSha: 'deafcab_mock_sha',
        checkRunId: 369,
        pullRequestId: 123,
        author: _authors[3],
        stage: CiStage.fusionEngineBuild,
        creationTime: now.millisecondsSinceEpoch - 300000,
        builds: {
          'Mac mac_host_engine': TaskStatus.succeeded,
          'Mac mac_ios_engine': TaskStatus.cancelled,
          'Linux linux_android_aot_engine': TaskStatus.succeeded,
        },
      ),
    );
    guards.add(
      _createPresubmitGuard(
        commitSha: 'deafcab_mock_sha',
        checkRunId: 369,
        pullRequestId: 123,
        author: _authors[3],
        stage: CiStage.fusionTests,
        creationTime: now.millisecondsSinceEpoch - 300000,
        builds: {
          'Linux framework_tests': TaskStatus.succeeded,
          'Mac framework_tests': TaskStatus.succeeded,
          'Linux android framework_tests': TaskStatus.skipped,
          'Windows framework_tests': TaskStatus.succeeded,
        },
      ),
    );

    // Add some checks with multiple attempts for testing fetchPresubmitCheckDetails
    checks.add(
      PresubmitCheck(
        checkRunId: 1234,
        buildName: 'Test Multi Attempt',
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: now.millisecondsSinceEpoch - 10000,
        buildNumber: 12345,
        summary: '''
[INFO] Starting task Test Multi Attempt...
[SUCCESS] Dependencies installed.
[INFO] Running build script...
[SUCCESS] All tests passed (452/452)
''',
      ),
    );
    checks.add(
      PresubmitCheck(
        checkRunId: 1234,
        buildName: 'Test Multi Attempt',
        status: TaskStatus.failed,
        attemptNumber: 2,
        creationTime: now.millisecondsSinceEpoch,
        buildNumber: 67890,
        summary:
            '[INFO] Starting task Test Multi Attempt...\n[ERROR] Test failed: Unit Tests',
      ),
    );

    _server.firestore.putDocuments(guards);
    _server.firestore.putDocuments(checks);
  }

  PresubmitGuard _createPresubmitGuard({
    required String commitSha,
    required int checkRunId,
    required int pullRequestId,
    required String author,
    required CiStage stage,
    required int creationTime,
    required Map<String, TaskStatus> builds,
    String repo = 'flutter',
  }) {
    final slug = RepositorySlug('flutter', repo);
    final failedBuilds = builds.values
        .where((status) => status.isFailure)
        .length;
    final remainingBuilds = builds.values
        .where((status) => !status.isBuildCompleted)
        .length;

    return PresubmitGuard(
      checkRun: generateCheckRun(checkRunId),
      commitSha: commitSha,
      slug: slug,
      pullRequestId: pullRequestId,
      stage: stage,
      creationTime: creationTime,
      author: author,
      remainingBuilds: remainingBuilds,
      failedBuilds: failedBuilds,
      builds: builds,
    );
  }

  PresubmitCheck _createPresubmitCheck({
    required int checkRunId,
    required String buildName,
    required TaskStatus status,
    required int creationTime,
    int attemptNumber = 1,
  }) {
    return PresubmitCheck(
      checkRunId: checkRunId,
      buildName: buildName,
      status: status,
      attemptNumber: attemptNumber,
      creationTime: creationTime,
    );
  }

  void _seedTreeStatusChanges(DateTime now) {
    final changes = <TreeStatusChange>[];
    // Create a history of tree status changes
    for (var i = 0; i < 10; i++) {
      changes.add(
        _createTreeStatusChange(
          i,
          created: now.subtract(Duration(hours: i)),
          status: i.isEven ? TreeStatus.success : TreeStatus.failure,
          reason: i.isEven ? null : 'Build failure on Linux',
        ),
      );
    }
    _server.firestore.putDocuments(changes);
  }

  void _seedSuppressedTests(DateTime now) {
    final suppressed = <SuppressedTest>[];
    suppressed.add(
      _createSuppressedTest(
        name: 'Linux_android 0',
        created: now.subtract(const Duration(days: 1)),
        issueLink: 'https://github.com/flutter/flutter/issues/12345',
      ),
    );
    _server.firestore.putDocuments(suppressed);
  }

  TreeStatusChange _createTreeStatusChange(
    int i, {
    DateTime? created,
    TreeStatus status = TreeStatus.success,
    String author = 'dash',
    String? reason,
    String repo = 'flutter',
  }) {
    final name =
        'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}/documents/${TreeStatusChange.metadata.collectionId}/$i';
    return TreeStatusChange.fromDocument(
      g.Document(
        name: name,
        fields: {
          'createTimestamp': (created ?? DateTime.fromMillisecondsSinceEpoch(i))
              .toValue(),
          'status': status.name.toValue(),
          'author': author.toValue(),
          'repository': RepositorySlug('flutter', repo).fullName.toValue(),
          if (reason != null) 'reason': reason.toValue(),
        },
      ),
    );
  }

  SuppressedTest _createSuppressedTest({
    String name = 'task',
    String repository = 'flutter/flutter',
    bool isSuppressed = true,
    String issueLink = 'link',
    DateTime? created,
  }) {
    final docName =
        'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}/documents/${SuppressedTest.kCollectionId}/$name';
    return SuppressedTest(
      name: name,
      repository: repository,
      isSuppressed: isSuppressed,
      issueLink: issueLink,
      createTimestamp: created ?? DateTime.fromMillisecondsSinceEpoch(1),
    )..name = docName;
  }

  void _seedCommitStatuses(
    DateTime now,
    math.Random random,
    String repo,
    String branch,
  ) {
    const commitGap = 2 * 60 * 1000; // 2 minutes between commits
    final baseTimestamp = now.millisecondsSinceEpoch;

    final commits = <Commit>[];
    final tasks = <Task>[];

    final commitCount = scenario == Scenario.highLoad ? 100 : 25;

    for (var index = 0; index < commitCount; index += 1) {
      final commitTimestamp = baseTimestamp - ((index + 1) * commitGap);
      // Use the same random sequence as DevelopmentCocoonService
      final commitRandom = math.Random(commitTimestamp);

      // Generate a stable and unique SHA for each commit
      final commitSha = _commitsSha[repo]![index];

      final authorIndex = commitRandom.nextInt(_authors.length);
      final messageSeed = commitTimestamp % 37 + authorIndex;
      final messageInc = _messagePrimes[messageSeed % _messagePrimes.length];
      final message = List<String>.generate(
        6,
        (int i) => _words[(messageSeed + i * messageInc) % _words.length],
      ).join(' ');

      final commit = generateFirestoreCommit(
        index,
        sha: commitSha,
        repo: repo,
        branch: branch,
        createTimestamp: commitTimestamp,
        author: _authors[authorIndex],
        avatar: _avatars[authorIndex],
        message: message,
      );
      commits.add(commit);

      final taskCount = repo == 'flutter' ? 100 : 3;
      for (var i = 0; i < taskCount; i++) {
        tasks.add(
          _createFakeTask(
            now,
            commitTimestamp,
            index,
            i,
            commitRandom,
            commitSha,
            repo,
          ),
        );
      }
    }

    _server.firestore.putDocuments(commits);
    _server.firestore.putDocuments(tasks);
  }

  Task _createFakeTask(
    DateTime now,
    int commitTimestamp,
    int commitIndex,
    int taskIndex,
    math.Random random,
    String commitSha,
    String repo,
  ) {
    const commitGap = 2 * 60 * 1000;
    final age = (now.millisecondsSinceEpoch - commitTimestamp) ~/ commitGap;

    TaskStatus status;
    if (scenario == Scenario.allGreen) {
      status = TaskStatus.succeeded;
    } else if (scenario == Scenario.redTree && commitIndex == 0) {
      status = TaskStatus.failed;
    } else {
      // The [statusesProbability] list is an list of proportional
      // weights to give each of the values in _statuses when randomly
      // determining the status. So e.g. if one is 150, another 50, and
      // the rest 0, then the first has a 75% chance of being picked,
      // the second a 25% chance, and the rest a 0% chance.
      final statusesProbability = <int>[
        // bigger = more probable
        math.max(taskIndex % 2, 20 - age * 2), // TaskStatus.waitingForBackfill
        math.max(0, 10 - age * 2), // TaskStatus.inProgress
        math.min(10 + age * 2, 100), // TaskStatus.succeeded
        math.min(1 + age ~/ 3, 30), // TaskStatus.failed
        if (taskIndex % 15 == 0) // TaskStatus.infraFailure
          5
        else if (taskIndex % 25 == 0)
          15
        else
          1,
        if (taskIndex % 20 == 0) 30,
        1, // TaskStatus.cancelled
      ];

      final maxProbability = statusesProbability.fold(
        0,
        (int c, int p) => c + p,
      );
      var weightedIndex = random.nextInt(maxProbability);
      var statusIndex = 0;
      while (weightedIndex > statusesProbability[statusIndex]) {
        weightedIndex -= statusesProbability[statusIndex];
        statusIndex += 1;
      }
      status = _statuses[statusIndex];
    }

    final minAttempts = _minAttempts[status]!;
    final maxAttempts = _maxAttempts[status]!;
    final attempts =
        minAttempts + random.nextInt(maxAttempts - minAttempts + 1);

    final buildNumber = attempts > 0 ? random.nextInt(1000) : null;

    return generateFirestoreTask(
      taskIndex,
      name: 'Linux_android $taskIndex',
      status: status,
      attempts: attempts,
      buildNumber: buildNumber,
      commitSha: commitSha,
      created: DateTime.fromMillisecondsSinceEpoch(commitTimestamp + taskIndex),
      started: DateTime.fromMillisecondsSinceEpoch(
        commitTimestamp + (taskIndex * 1000 * 60),
      ),
      ended: DateTime.fromMillisecondsSinceEpoch(
        commitTimestamp + (taskIndex * 1000 * 60) + (taskIndex * 1000 * 60),
      ),
      bringup: taskIndex == now.millisecondsSinceEpoch % 13,
      testFlaky: attempts > 1,
    );
  }

  static const _statuses = [
    TaskStatus.waitingForBackfill,
    TaskStatus.inProgress,
    TaskStatus.succeeded,
    TaskStatus.failed,
    TaskStatus.infraFailure,
    TaskStatus.skipped,
    TaskStatus.cancelled,
  ];

  static const _minAttempts = {
    TaskStatus.waitingForBackfill: 1,
    TaskStatus.inProgress: 1,
    TaskStatus.succeeded: 1,
    TaskStatus.failed: 1,
    TaskStatus.infraFailure: 1,
    TaskStatus.skipped: 1,
    TaskStatus.cancelled: 1,
  };

  static const _maxAttempts = {
    TaskStatus.waitingForBackfill: 1,
    TaskStatus.inProgress: 2,
    TaskStatus.succeeded: 1,
    TaskStatus.failed: 2,
    TaskStatus.infraFailure: 2,
    TaskStatus.skipped: 1,
    TaskStatus.cancelled: 1,
  };

  static const List<String> _authors = <String>[
    'matan',
    'yegor',
    'john',
    'jenn',
    'kate',
    'stuart',
  ];

  static const List<String> _avatars = [
    'https://avatars.githubusercontent.com/u/168174?v=4',
    'https://avatars.githubusercontent.com/u/211513?v=4',
    'https://avatars.githubusercontent.com/u/1924313?v=4',
    'https://avatars.githubusercontent.com/u/682784?v=4',
    'https://avatars.githubusercontent.com/u/16964204?v=4',
    'https://avatars.githubusercontent.com/u/122189?v=4',
  ];

  static const List<int> _messagePrimes = <int>[
    3,
    11,
    17,
    23,
    31,
    41,
    47,
    67,
    79,
  ];
  static const List<String> _words = <String>[
    'fixes',
    'issue',
    'crash',
    'developer',
    'blocker',
    'intermittent',
    'format',
  ];

  static const _commitsSha = {
    'cocoon': _commitsCocoon,
    'flutter': _commitsFlutter,
  };

  // These commits from from flutter/cocoon
  static const List<String> _commitsCocoon = <String>[
    '2fd76f920a38e4384248173d05ee482d5aeaf4c5',
    '2d22b5e85f986f3fa2cf1bfaf085905c2182c270',
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
    'b69dda7e6e7c605aacb0ab973a21830c4401db20',
    '90b5950051487c57c9120f6d0b98d61dfb05a197',
    '177ac767fdfbe9799f91bfc0f22b44109f7b1b20',
    '18d71ce8066b0653b5ecd1a235571fd806f420a0',
    '39016691752550109065cb506393f9a88eeb5433',
    '3477afbf65aac3fd3dfca54770803283d827222a',
    'ec17795bcac60741f0b4009fd60e654333173c0d',
    '02d64e3e6b65d430adc8f28e76b65fef06112e81',
    '6d378d876bb342380e5aaa2671d7c2687bc67df2',
    'b47732a57770a5a1780f25bb495cbcc2b61722b9',
    '4b666b1f44634a5766220adc84e01c6f804cf552',
    '642bbd51338f2ea19e97409e3abaa07391707df9',
    '49935920c84157e8c0b981ac6b4eac9f92022613',
    'ce4105b9a777ed2b494ee61465584d58faa52cde',
    '24aeb8dffb2e9a83161a89e88e9aacf5f01beb63',
    '07280e78af25d07f1bd00c391fd0928f5d9aa543',
    '13239ea26d46db5a3268592b88ba65f732fcca7a',
    '213244f8ec1740c1db65cd02853de2e5736b26bd',
  ];

  static const _commitsFlutter = [
    '692b51763d45cc4d574a06cf3d7b9b36f69c5170',
    '450478ad313f8291c3a48b00a7331e7d12e2bda0',
    'fb75b2b671c7702b549a80a420144097f4fab5a9',
    '9020331a243162781b2c5a645cdca892b1d32b97',
    '7672bd756ac34099907137e51f276ee5c0cfb582',
    '6172ba6c553e7642bc58997c200f5dde488b64bc',
    '1da41c5015a28e0025a00b7c189077e3872a358c',
    'fafe9c3c1e772019a4894f6c3092f3f633654b1f',
    '8d3b8d8b7fa1267439e979803af8d41e237e9c95',
    '113ea6ae72deb26444c3b561c65c9c6b2c0f3ef3',
    'f4e490131e338bf8b1a3bcab8dae68c56c4498cd',
    'b13a8b24362d7a0b2fafe2a404cd9852b27dc688',
    'a545549c4e33a548600a8045d1bd5388346cf187',
    'f76936bb858dbade620fc8710b5fd89dc1fab750',
    '4c4f5e70b14e238ceebd03372765abb204070573',
    '3b21872f9aea4d1cdf3a09c7d74c3970d9316330',
    'c5643e21933389ab21a45e38515494c53d2cc2f6',
    'ee7e28ec979562d0ab722fd24b5e145068ec6b63',
    'cbb7a618809ee9dfb525ca6ea28044e016718ae7',
    '399a692f7db0bd5faba36003d67880776a3767d3',
    'c389cc0b790a10482a82a5ab2915e907aa442ad1',
    'd88a5099b202bd289c508d1dd5ef3e006ccf8144',
    'c71e0e31aeb6b855477dee84b391d64f14967616',
    '88ef36199ddebf36b0596af73047b56ed0208fa3',
    '4f5478cce38d837e14b7a032a12500d3fc0f1310',
    '02f61b17f1aa91dca2df3108676bc13700f9efe7',
    '7ff0723e08fd3f40bf866c164da8f1895ad41e71',
    'fbfe04e0c4e7311a92f9407abb6ec6f3c9543d8e',
    'dad6f9d4107a5332d15c126207882edbd8acdc97',
    '95144d41fa78bde126c4c1460d4f9ec1a0c3daa5',
    '1e1df36da3654f3bec977435cee56637ab77d398',
    'efb43ece1f40a0a5f04348951eb625f81318587a',
    'd2d2a7a0c18d7465dd12225f511d998135e0036d',
    '8774a3b33cb281791933f1cd45f0e77ddd9d4bd1',
    '3ff83f39d2fe9c228f4fa16709392c27ef1d7d32',
    '3f0a7310dfb6ae1ce29c09b58167b2c16cff743a',
    '2a4b712361668ae230fbf1077bf6a5ef07552641',
    'e6e36963d3bdbd3810f8986ab56811b9ff145a5c',
    '9c8defed0245315b2dab8986ae66fc84b186ff3e',
    '6d42ae50140884ec72886665cfb5d4bf39f30afe',
    '075faff72b964ee4fb6f4e45f260d0223ff55f23',
    '1af98a6bfc879852008bd2108242a64c07403b1d',
    '5b5a69ff0a4288b1e53c3d1337c5ac69ca26ebfc',
    '4c020ad5dad530afde20c2830a5a6f22c6e3b867',
    '3109939de842eb6fe00a831e436963d4568bdc0e',
    'f38a3e07af777d51606cd9912bc28c274eb6f05b',
    '5655697a23d54dadeb4f527424b3da3ffa1051a2',
    '9dc7888929d9112dfed9deb16f3f20d6a341bb5b',
    '91b2d41a66d1c540233b819525553afc0fa1f58d',
    '2d7e80963b3ad3594b7fcab231f1bd08c13cf0d1',
    '81c91517d55c15f9f3a10d5b88401c7e191a5179',
    '6c9a881a59f6a2e79e0896e0b475ee9293983947',
    '8034db0bd38b1c682146474cc5986e2e00dad96f',
    'd134331bf8f01c213b87cc611a76a0013ed3e860',
    '34073f4f2a86acd23f4966acbb24d550b5f31563',
    '56956c33ef102ac0b5fc46b62bd2dd9f50a86616',
    '0ef66c7d1a4c3ed303fdd2aa0349d39955b0e0ef',
    '935b8f70305b2d82d76b2a15d568d973e2835895',
    '9af4145b8ecb5da13d053dd2a6702c73705a862a',
    'a8911cbac88ef8f73c083465d0cbc35a7537f35f',
    'd33442bedb88e1579c58f5dee14951712bdaf94d',
    '7008d4acb2076798da0adf3c16dc08286dbea765',
    '06df71c51446e96939c6a615b7c34ce9123806ba',
    '230240c56880f2c19bf92d2c32203b064054f173',
    '1fdf684e327544e93c39f1da5429c3e880d22d15',
    '8a80222e4d09460d6615636df152adc6772cb9f6',
    'de1b130cf637ad91ebf17db0893b7e1ce5f2b064',
    'e1f11bd5aafda71a21854a0cc53022666c1c5449',
    '76f70d21da9c58da773ca7ebb044b2bbb8808c28',
    '1f506886e11c3cb59deb216b6139f718f5a2dd67',
    'b9e7e3ffe808a93f1e50d3b1729bf1f40e375de2',
    '2c24f0f31223fbda063ad40e25219578742ac299',
    'e0e7a7d72db3fef30b221433e259e4e94a4d3aec',
    '96d292fa0acd9d11e85fd04f7355a47cf3fb2723',
    '246b62f221f3966a0fcfcecc3e8cb1ef7ce3e953',
    '1e97fd38cf89f94f5159f4e9d0b598a0871103ab',
    '6c90a6559480c7b46a3e6c767af614326fb8ca9b',
    '2b2bdc6df9e061b0bdf0ff61e9c508d963e3ac64',
    '9f2cb479c8aa66c82a4ae9f6ca825aee5949382b',
    'c023e5b2474f8ff1c146240dd685237cd8490f89',
    '24ce716cfddfef201027c1a5fa2299a8aeffb03e',
    '1887f3f8e0d4ebff550dcc08319e338290edf339',
    '0c72661d44978a4e9374a14e882bbb26a46c0ac5',
    '5e7b2a0bb3e58cbe4771ae3b7965941f9f38b84e',
    '64866862f623ceeb45fd8be4782e8db8b58910c0',
    '4c7144a4a890b98ed812be8648ff16c917216e8b',
    '294aa14e763f7e8a3729f15eef72f50f16b48e05',
    'ec11254157f69d5d9260e12f53f82a6569b5c1fa',
    'f5825a22a47969ce9fec303dbefee035eadb1acc',
    'a58324d980b1e1d6805eac3e4a7748ae5965a242',
    '8f61855dede30a55e9e00c9cb0caa62829798cd1',
    '7ac16a276391e26e448e50447f2bb4f3e8146c87',
    '70870ee8d3b6280e2366f95f067e075f11c08f58',
    'ecf688eb21e8e7d6e21456a2d2fbede4c4ab5b94',
    '5b1c84cec15ce15283fe67cb202f37d3f9a911be',
    '35e8dae34234cf605ab622ae5c91ff0c3676da55',
    '6e4a481bdf2793a05a2569693d3b88b200159217',
    '9292bb3a66ea6377899df5a7fc17857fa364477c',
    '9fa7f81be038464d2aabef4752d2f50ea60ce561',
    'aba16bc2db714ba438f5480fd328c14ca92c42db',
  ];
}
