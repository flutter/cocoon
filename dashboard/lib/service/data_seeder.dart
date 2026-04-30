// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:uuid/uuid.dart';

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
    for (final repo in ['flutter', 'cocoon', 'packages']) {
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
    final checks = <PresubmitJob>[];

    // cafe5_1_mock_sha
    final prNum = 1234;
    var checkRunId = 123456;
    var creationTime = 1770000000000;
    final enginejobs = [
      'Mac mac_host_engine',
      'Mac mac_ios_engine',
      'Linux linux_android_aot_engine',
    ];
    final fusionjobs = [
      'Linux framework_tests',
      'Mac framework_tests',
      'Linux android framework_tests',
      'Windows framework_tests',
      'Mac_x64 framework_misc',
      'Linux_android_emu android_engine_opengles_tests',
      'Linux_android_emu_vulkan_stable android_engine_vulkan_tests',
      'Mac_arm64 run_debug_test_macos',
      'Linux_android_emu android views',
    ];
    var engineChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[0],
        status: TaskStatus.failed,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[1],
        status: TaskStatus.cancelled,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[2],
        status: TaskStatus.infraFailure,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];

    guards.add(
      _createPresubmitGuard(
        headSha: 'cafe5_1_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[0],
        stage: CiStage.fusionEngineBuild,
        creationTime: creationTime,
        jobs: {for (var check in engineChecks) check.jobName: check.status},
      ),
    );
    checks.addAll(engineChecks);

    // face5_2_mock_sha
    checkRunId = 234567;
    creationTime = creationTime + 100000;
    engineChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[0],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[1],
        status: TaskStatus.skipped,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[2],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];
    guards.add(
      _createPresubmitGuard(
        headSha: 'face5_2_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[1],
        stage: CiStage.fusionEngineBuild,
        creationTime: creationTime,
        jobs: _getLatestjobstatuses(engineChecks),
      ),
    );
    checks.addAll(engineChecks);
    creationTime = creationTime + 100000;
    var fusionChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[0],
        status: TaskStatus.inProgress,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[1],
        status: TaskStatus.skipped,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[2],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[3],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];
    guards.add(
      _createPresubmitGuard(
        headSha: 'face5_2_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[1],
        stage: CiStage.fusionTests,
        creationTime: creationTime,
        jobs: _getLatestjobstatuses(fusionChecks),
      ),
    );
    checks.addAll(fusionChecks);

    // decaf_3_mock_sha
    checkRunId = 345678;
    creationTime = creationTime + 100000;
    engineChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[0],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[1],
        status: TaskStatus.skipped,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[2],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];
    guards.add(
      _createPresubmitGuard(
        headSha: 'decaf_3_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[3],
        stage: CiStage.fusionEngineBuild,
        creationTime: creationTime,
        jobs: _getLatestjobstatuses(engineChecks),
      ),
    );
    checks.addAll(engineChecks);
    creationTime = creationTime + 100000;
    var creationTime2 = creationTime + 100000;
    fusionChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[0],
        status: TaskStatus.failed,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[0],
        status: TaskStatus.succeeded,
        attemptNumber: 2,
        creationTime: creationTime2,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[1],
        status: TaskStatus.skipped,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[2],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[3],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];
    guards.add(
      _createPresubmitGuard(
        headSha: 'decaf_3_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[3],
        stage: CiStage.fusionTests,
        creationTime: creationTime,
        jobs: _getLatestjobstatuses(fusionChecks),
      ),
    );
    checks.addAll(fusionChecks);

    // deafcab_mock_sha
    checkRunId = 456789;
    creationTime = creationTime + 100000;
    engineChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[0],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[1],
        status: TaskStatus.skipped,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: enginejobs[2],
        status: TaskStatus.succeeded,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];
    guards.add(
      _createPresubmitGuard(
        headSha: 'deafcab_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[4],
        stage: CiStage.fusionEngineBuild,
        creationTime: creationTime,
        jobs: _getLatestjobstatuses(engineChecks),
      ),
    );
    checks.addAll(engineChecks);
    creationTime = creationTime + 100000;
    creationTime2 = creationTime + 100000;
    fusionChecks = [
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[0],
        status: TaskStatus.failed,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[0],
        status: TaskStatus.succeeded,
        attemptNumber: 2,
        creationTime: creationTime2,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[1],
        status: TaskStatus.cancelled,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[2],
        status: TaskStatus.infraFailure,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[3],
        status: TaskStatus.failed,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[3],
        status: TaskStatus.failed,
        attemptNumber: 2,
        creationTime: creationTime2,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[4],
        status: TaskStatus.neutral,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[5],
        status: TaskStatus.neutral,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[6],
        status: TaskStatus.neutral,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[7],
        status: TaskStatus.neutral,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
      _createPresubmitJob(
        checkRunId: checkRunId,
        jobName: fusionjobs[8],
        status: TaskStatus.neutral,
        attemptNumber: 1,
        creationTime: creationTime,
      ),
    ];
    guards.add(
      _createPresubmitGuard(
        headSha: 'deafcab_mock_sha',
        checkRunId: checkRunId,
        prNum: prNum,
        author: _authors[4],
        stage: CiStage.fusionTests,
        creationTime: creationTime,
        jobs: _getLatestjobstatuses(fusionChecks),
      ),
    );
    checks.addAll(fusionChecks);

    final prCheckRuns = <PrCheckRuns>[];
    for (final guard in guards) {
      prCheckRuns.add(_createPrCheckRuns(guard));
    }

    // Add some checks with multiple attempts for testing fetchPresubmitJobDetails
    _server.firestore.putDocuments(guards);
    _server.firestore.putDocuments(checks);
    _server.firestore.putDocuments(prCheckRuns);
  }

  Map<String, TaskStatus> _getLatestjobstatuses(List<PresubmitJob> checks) {
    final latestChecks = <String, PresubmitJob>{};
    for (final check in checks) {
      if (!latestChecks.containsKey(check.jobName) ||
          check.attemptNumber > latestChecks[check.jobName]!.attemptNumber) {
        latestChecks[check.jobName] = check;
      }
    }
    return {for (var check in latestChecks.values) check.jobName: check.status};
  }

  PresubmitGuard _createPresubmitGuard({
    required String headSha,
    required int checkRunId,
    required int prNum,
    required String author,
    required CiStage stage,
    required int creationTime,
    required Map<String, TaskStatus> jobs,
  }) {
    final slug = RepositorySlug('flutter', 'flutter');
    final failedJobs = jobs.values.where((status) => status.isFailure).length;
    final remainingJobs = jobs.values
        .where((status) => !status.isComplete)
        .length;

    return PresubmitGuard(
      checkRun: generateCheckRun(
        checkRunId,
        name: 'Merge Queue Guard',
        startedAt: DateTime.fromMillisecondsSinceEpoch(creationTime),
      ),
      headSha: headSha,
      slug: slug,
      prNum: prNum,
      stage: stage,
      creationTime: creationTime,
      author: author,
      remainingJobs: remainingJobs,
      failedJobs: failedJobs,
      jobs: jobs,
    );
  }

  PresubmitJob _createPresubmitJob({
    required int checkRunId,
    required String jobName,
    required TaskStatus status,
    required int creationTime,
    int attemptNumber = 1,
  }) {
    return PresubmitJob(
      slug: RepositorySlug('flutter', 'flutter'),
      checkRunId: checkRunId,
      jobName: jobName,
      status: status,
      attemptNumber: attemptNumber,
      creationTime: creationTime,
      buildNumber: 1337 + attemptNumber,
      buildId: 24567 + attemptNumber,
      summary: switch (status) {
        .succeeded =>
          '[INFO] Starting task $jobName...\n[SUCCESS] All tests passed (452/452)',
        .failed =>
          '[INFO] Starting task $jobName...\n[ERROR] Test failed: Dummy Tests',
        .infraFailure =>
          '[INFO] Starting task $jobName...\n[ERROR] Infrastructure failure: Dummy Tests',
        .cancelled =>
          '[INFO] Starting task $jobName...\n[ERROR] Test cancelled: Dummy Tests',
        .inProgress => '[INFO] Starting task $jobName...',
        .waitingForBackfill => null,
        .skipped =>
          '[INFO] Starting task $jobName...\n[INFO] Test skipped: Dummy Tests',
        .neutral =>
          '[INFO] Starting task $jobName...\n[INFO] Test neutral: Dummy Tests',
      },
      startTime: creationTime + 30000,
      endTime: creationTime + 60000,
      logAnalysis: switch (status) {
        .failed =>
          'Based on my analysis of the provided LUCI logs and the context of the changes in this PR, here is the breakdown of the build failure:\n\n ### 1. Identify the specific test or command that failed for $jobName \n...',
        _ => null,
      },
    );
  }

  PrCheckRuns _createPrCheckRuns(PresubmitGuard guard) {
    final pr = PullRequest(
      number: guard.prNum,
      head: PullRequestHead(
        sha: guard.commitSha,
        repo: Repository(
          fullName: guard.slug.fullName,
          name: guard.slug.name,
          owner: UserInformation(guard.slug.owner, 1, '', ''),
        ),
      ),
      base: PullRequestHead(
        ref: 'master',
        repo: Repository(
          fullName: guard.slug.fullName,
          name: guard.slug.name,
          owner: UserInformation(guard.slug.owner, 1, '', ''),
        ),
      ),
      user: User(login: guard.author),
      labels: [],
    );
    final docName =
        'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}/documents/${PrCheckRuns.kCollectionId}/${const Uuid().v4()}';
    final prCheckRuns = PrCheckRuns()
      ..pullRequest = pr
      ..fields['sha'] = guard.commitSha.toValue()
      ..fields['slug'] = jsonEncode(guard.slug.toJson()).toValue()
      ..fields['Merge Queue Guard'] = guard.checkRun.id!.toString().toValue()
      ..name = docName;

    for (final jobName in guard.jobs.keys) {
      prCheckRuns.fields[jobName] = '234567'.toString().toValue();
    }

    return prCheckRuns;
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
      final headSha = _commitsSha[repo]![index];

      final authorIndex = commitRandom.nextInt(_authors.length);
      final messageSeed = commitTimestamp % 37 + authorIndex;
      final messageInc = _messagePrimes[messageSeed % _messagePrimes.length];
      final message = List<String>.generate(
        6,
        (int i) => _words[(messageSeed + i * messageInc) % _words.length],
      ).join(' ');

      final commit = generateFirestoreCommit(
        index,
        sha: headSha,
        repo: repo,
        branch: branch,
        createTimestamp: commitTimestamp,
        author: _authors[authorIndex],
        avatar: _avatars[authorIndex],
        message: message,
      );
      commits.add(commit);

      final taskCount = switch (repo) {
        'flutter' => 100,
        'packages' => 42,
        'cocoon' => 13,
        _ => 3,
      };
      for (var i = 0; i < taskCount; i++) {
        tasks.add(
          _createFakeTask(
            now,
            commitTimestamp,
            index,
            i,
            commitRandom,
            headSha,
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
    'packages': _commitsPackages,
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

  static const _commitsPackages = [
    '8dcfd1186ef968be1398f80432f94bb0a36e6d9e',
    'c1f116788a9c0187ac566517eecaf31a49c2bbf7',
    '99155a84f372cef1c5fc2d03c54d6980fb9df808',
    'b3a69599c7b8d2f97dc7f601df59b09f6a47a8ed',
    '43de301d0901cac145b39a994fe3b58889e00b85',
    'ca60bd020f339b5538423b3e60463717a702ddc7',
    '09ddfca4fe95c5aa90015ce4ecb31485eb7cf3d7',
    '94b93d4cd52af75b3298c1966394759a9e611f61',
    '071ed5b454e05b071ffb9113c33e7a423ca344b0',
    '3c0cdab2bbb0e98e5e5871f5949e38f21cff6385',
    'b3280ae0d8ed70ec2e354e000354099b8abcc448',
    'afa1a1c3564e5be4795193600b1c2f0e58d80bee',
    '2fbf78d1099c2ec04578c0db2737b81632f573da',
    '90a2dc1245d7a3e370230bcd2f308a35da67851f',
    '70049bdd9b88609b4485cc2cf71ccb60da57031c',
    'b2e421bc176c488730567e4edbdee6ed48d00473',
    'dd634a2186cfe9e5b57fca2c8cceae7b4fa41790',
    '1802599d43eb93a1ada0dfb294d3f030bdacc2a2',
    'a9d36fb7b9021b6e980156097fa8c0f8392273f3',
    '88afc6863149dfa1a26170a17789a1b711ddbe5a',
    '0f2eeaecde3f34322f9e9980177d15beaeb2b871',
    '409793bcb784b9464def8698557005fb8851a9e6',
    '1ad1a084c057b6c0383f6cf0ba9df70d5d4b0fc6',
    '392d771dac6e7956d30fe93ef2595df787f5a287',
    'ea9b53ba608a8aa6d0d243832fdcee37928e1614',
    'd809b4f2e1cb8381b0328234204c5423a0580999',
    '91f7c339b29af157db001e487e14274487f41688',
    '86543faf4d5634bdaf5d60661630ddf81ad0617f',
    '02f231f376761cc04610e8c566b0ba759db0bda7',
    '61b4096307bf8a20786716522a0f5ce55a577d82',
    'bba1da378c820040d57cf8cb01ca27c85728fe61',
    '14cbff2f7383a1563aef4efd29d92f65d8ddef2a',
    'ecace66e92c2f9235e0d811b064d9f0e97f6175e',
    '1ea3725c4396e1708571082a635f6132c059fd18',
    'a6542ceef278cf10bd82bc0c4c2feca611c582a2',
    '44980b66496ec338ed1ed256e40e161c5bb6d09b',
    '295819c44093d6fed1fe48c28b3ac01268154387',
    '77796111ab5f3d0a63d0f594d9499dc7dcc58c50',
    '406a9821eb084426e0264fca36e0afbc3acd5227',
    'a643267e6bf368f0ae83a17caf0a369c095ab0df',
    '37827fc0a5588f40ea5dba1a70383ae86e8265b6',
    '349d8853cab54514b15173337f3203093ccda106',
    'ee460d6a01fee815ffbe1dc169f851bd682addd6',
    '5bee35271f19d5bd039c5bd460a62e60b426ebca',
    'c7170181ffebd5efcc06bf78734c5820a27f7cfd',
    '9139f6c6bef51edf08dc587b43b06e359fb5c7de',
    '2673dcdf47156efdfae783bb389234df81ac9da7',
    'edc45c5f31a12875352048545bed57820e970edd',
    '79b53f3424dc889dd0d257c83461644dab46278e',
    '1e0338bfd3c6799713fe89c26a55a64521416e16',
    '4d0dfb290e773d4bf68d046f797584a172694966',
    '27b12509e5203fea3aa2ed3cc4a4c38cf3349634',
    'ff15dfdb36837e099424a4590ebf202472029f49',
    'e774c2a3f03b2c551506508f813c91d25c297d22',
    'fe3de646912443c073773acea83c783be6c2275c',
    'bf3a29cfccf105d652b03d2cb681081e6854eddd',
    '8d5c5cd0fa83b786429a5c7ce9f93a5f2f132648',
    '888ef055975de366031e514317ba8bc39f9c11d5',
    '82baf937218655b8befc2a391c955ae8eb7aa674',
    '3c04d2df64a497e646d344bf384049c0bcbccdf9',
    '03ed07755ce0761fee7ecd8b0a46cf3bfa85c667',
    'e5ef6e87e51bd3213e60ae060a48273a5384f855',
    '8212bdb4a2c8b5911b3ba33cbf85942917c9dcd9',
    '9083bc9bed1d399f54952848c85c54dc6cba8645',
    '7293eee6ac127b7c34185a56064f75bf46dcd892',
    '173a344964f6426579cb2b9578108d014585c79b',
    '12279ffac3cee623e51667e62dd720046f05fa03',
    'faa4e22db67cc5e6d6af84ebc85603330fff7353',
    '678f033811377ce039a491ad1beae56ac7ba87ed',
    '7f9860a70d20bc77166eba1a56f4e9c2d2680db3',
    '32a8a23e9be049c0da892e08e36e43cfe76799a1',
    'a27d7c50b3ac66cdcc9e774d2a5310793277ed34',
    '7026f1a62c30509b40023c67969c5d0eeb7c0f24',
    '6301571e051a814d6610ab199484d94f4aa0d795',
    'f3ce6cbfa7677fa6ea093982c5c7c4194976d339',
    '6d8b19d5fd7ae2f1905885f2b323af1cb2f0ad57',
    '3bef3cf3da7603393ed969e5cb1f814322c46058',
    '79c529a6bf794cca23ff33299e893a2b118cb19b',
    'f234c1f626d56f05eaeb0bd5f1094e5354ed2518',
    'e1d01695273f692c6a67848e72bd58b255837f7c',
    'f84c6e71882fd6af96fafec34c8fbced81016a0a',
    '40bb258f277522f87dc8c01a62293828116bb16a',
    '6c20ef3136acf476b3923dc9bdc74a1d512f3849',
    'b9ee0b3caffce7a33cac1e72cded5777865c6f79',
    '546d3542df2d017142bb9dcb1f142060f319e631',
    '7fe183f964b312cc51985067ac54f1ff292236b3',
    'd8970b12d60a31e9bae5521142f9881895244f88',
    'acd9adbe46762bc305c7502d17527accf184c3a6',
    '0b2baeb4fbf3e565f87cb2f7a28394a1d9c0e77d',
    '062c8d4f8dd51004a87b0abebb88c1986c5a73a5',
    '12013c49611994d08759f056294e347e5b5fa236',
    '9fa0fdce48a2b730da20c2d2228b75f819b1cbdd',
    '8f2fd365ea7b30762f4e67357b299954f9b4a996',
    '76183f418542218f3bb49a7ecfe5e2e1406ed126',
    '12b43a192e1f5fa5141181a72d681a15abd003c1',
    'df8be18fb5083a0baee0f9612b6488ef7c375d71',
    'de38ee1e9da563cbf70436db7f7b2e95595c07d8',
    '54b6834b2a74aa1165dd7fba3558edb6e71d1112',
    'bf37517977ffaa46c76dfbc1d30e3ef874cd9729',
    '673c2ac4b464aacb2b320ffc30eca0ab953e6212',
  ];
}
