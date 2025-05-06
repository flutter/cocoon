// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' as github;

import '../service/fake_scheduler.dart';

Task generateFirestoreTask(
  int i, {
  String? name,
  TaskStatus status = TaskStatus.waitingForBackfill,
  int attempts = 1,
  bool bringup = false,
  bool testFlaky = false,
  int? buildNumber,
  DateTime? created,
  DateTime? started,
  DateTime? ended,
  String? commitSha,
}) {
  return Task(
    builderName: name ?? 'task$i',
    currentAttempt: attempts,
    commitSha: commitSha ?? 'testSha',
    bringup: bringup,
    buildNumber: buildNumber,
    createTimestamp: created?.millisecondsSinceEpoch ?? 0,
    startTimestamp: started?.millisecondsSinceEpoch ?? 0,
    endTimestamp: ended?.millisecondsSinceEpoch ?? 0,
    status: status,
    testFlaky: testFlaky,
  );
}

Commit generateFirestoreCommit(
  int i, {
  String? sha,
  String branch = 'master',
  String? owner = 'flutter',
  String repo = 'flutter',
  int? createTimestamp,
  String message = 'test message',
  String author = 'author',
  String avatar = 'avatar',
}) {
  sha ??= '$i';
  return Commit(
    createTimestamp: createTimestamp ?? i,
    repositoryPath: '$owner/$repo',
    branch: branch,
    message: message,
    author: author,
    avatar: avatar,
    sha: sha,
  );
}

GithubGoldStatus generateFirestoreGithubGoldStatus(
  int i, {
  String? head,
  int? pr,
  String owner = 'flutter',
  String repo = 'flutter',
  String? status,
  int? updates,
  String? description,
}) {
  pr ??= i;
  head ??= 'sha$i';
  return GithubGoldStatus(
    prNumber: pr,
    head: head,
    status: status ?? GithubGoldStatus.statusRunning,
    description: description ?? '',
    updates: updates ?? 0,
    repository: '$owner/$repo',
  );
}

GithubBuildStatus generateFirestoreGithubBuildStatus(
  int i, {
  String? head,
  int? pr,
  String owner = 'flutter',
  String repo = 'flutter',
  int updates = 0,
  String status = GithubBuildStatus.statusSuccess,
}) {
  pr ??= i;
  head ??= 'sha$i';
  return GithubBuildStatus(
    status: status,
    prNumber: pr,
    head: head,
    repository: '$owner/$repo',
    updates: updates,
    updateTimeMillis: DateTime.now().millisecondsSinceEpoch,
  );
}

Target generateTarget(
  int i, {
  pb.SchedulerConfig? schedulerConfig,
  String platform = 'Linux',
  Map<String, String>? platformProperties,
  Map<String, String>? platformDimensions,
  Map<String, String>? properties,
  Map<String, String>? dimensions,
  List<String>? runIf,
  bool? bringup,
  github.RepositorySlug? slug,
  pb.SchedulerSystem? schedulerSystem,
  String recipe = 'devicelab/devicelab',
  String? name,
  bool? backfill,
}) {
  final config =
      schedulerConfig ?? multiTargetFusionConfig.configFor(CiType.any);
  if (platformProperties != null && platformDimensions != null) {
    config.platformProperties[platform
        .toLowerCase()] = pb.SchedulerConfig_PlatformProperties(
      properties: platformProperties,
      dimensions: platformDimensions,
    );
  } else if (platformDimensions != null) {
    config.platformProperties[platform.toLowerCase()] =
        pb.SchedulerConfig_PlatformProperties(dimensions: platformDimensions);
  } else if (platformProperties != null) {
    config.platformProperties[platform.toLowerCase()] =
        pb.SchedulerConfig_PlatformProperties(properties: platformProperties);
  }
  return Target(
    schedulerConfig: config,
    slug: slug ?? github.RepositorySlug('flutter', 'flutter'),
    value: pb.Target(
      name: name ?? '$platform $i',
      properties: properties,
      dimensions: dimensions,
      runIf: runIf ?? <String>[],
      bringup: bringup ?? false,
      recipe: recipe,
      scheduler: schedulerSystem ?? pb.SchedulerSystem.cocoon,
      backfill: backfill,
    ),
  );
}

bbv2.Build generateBbv2Build(
  Int64 i, {
  String bucket = 'prod',
  String name = 'Linux test_builder',
  bbv2.Status status = bbv2.Status.SUCCESS,
  Iterable<bbv2.StringPair>? tags,
  bbv2.Build_Input? input,
  int buildNumber = 1,
}) => bbv2.Build(
  id: i,
  builder: bbv2.BuilderID(project: 'flutter', bucket: bucket, builder: name),
  status: status,
  tags: tags,
  number: buildNumber,
  input: input,
);

github.CheckRun generateCheckRun(
  int i, {
  String name = 'name',
  int checkSuite = 2,
  DateTime? startedAt,
}) {
  startedAt ??= DateTime.utc(2020, 05, 12);
  return github.CheckRun.fromJson(<String, dynamic>{
    'id': i,
    'name': name,
    'started_at': startedAt.toIso8601String(),
    'check_suite': <String, dynamic>{'id': checkSuite},
  });
}

github.CheckSuite generateCheckSuite(
  int i, {
  String headBranch = 'main',
  String headSha = 'abc',
  github.CheckRunConclusion conclusion = github.CheckRunConclusion.success,
  List<github.PullRequest> pullRequests = const <github.PullRequest>[],
}) {
  return github.CheckSuite(
    id: i,
    headBranch: headBranch,
    headSha: headSha,
    conclusion: conclusion,
    pullRequests: pullRequests,
  );
}

github.PullRequest generatePullRequest({
  int id = 789,
  String branch = 'master',
  String repo = 'flutter',
  String authorLogin = 'dash',
  String authorAvatar = 'dashatar',
  String title = 'example message',
  int number = 123,
  DateTime? mergedAt,
  String headSha = 'abc',
  String baseSha = 'def',
  bool merged = true,
  List<github.IssueLabel> labels = const [],
  int changedFilesCount = 1,
}) {
  mergedAt ??= DateTime.fromMillisecondsSinceEpoch(1);
  return github.PullRequest(
    id: id,
    title: title,
    number: number,
    mergedAt: mergedAt,
    base: github.PullRequestHead(
      ref: branch,
      sha: baseSha,
      repo: github.Repository(
        fullName: 'flutter/$repo',
        name: repo,
        owner: github.UserInformation('flutter', 1, '', ''),
      ),
    ),
    head: github.PullRequestHead(
      ref: branch,
      sha: headSha,
      repo: github.Repository(
        fullName: 'flutter/$repo',
        name: repo,
        owner: github.UserInformation('flutter', 1, '', ''),
      ),
    ),
    user: github.User(login: authorLogin, avatarUrl: authorAvatar),
    mergeCommitSha: headSha,
    merged: merged,
    labels: labels,
    changedFilesCount: changedFilesCount,
  );
}

GerritCommit generateGerritCommit(String sha, int milliseconds) => GerritCommit(
  commit: sha,
  tree: 'main',
  author: GerritUser(
    email: 'dash@flutter.dev',
    time: DateTime.fromMillisecondsSinceEpoch(milliseconds),
  ),
);

github.RepositoryCommit generateGitCommit(
  int i, {
  DateTime? commitDate,
  String? sha,
}) => github.RepositoryCommit(
  sha: sha ?? '$i',
  commit: github.GitCommit(
    committer: github.GitCommitUser(
      'dash',
      'dash@flutter.dev',
      commitDate ?? DateTime.fromMillisecondsSinceEpoch(i),
    ),
  ),
);

github.Issue generateIssue(
  int i, {
  String authorLogin = 'dash',
  String authorAvatar = 'dashatar',
  String title = 'example message',
  int number = 123,
}) {
  return github.Issue(
    id: i,
    title: title,
    number: number,
    user: github.User(login: authorLogin, avatarUrl: authorAvatar),
  );
}
