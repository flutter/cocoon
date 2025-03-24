// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart'
    as firestore_commit;
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' as github;
import 'package:googleapis/firestore/v1.dart' hide Status;

import '../service/fake_scheduler.dart';

Key<T> generateKey<T>(Type type, T id) =>
    Key<T>.emptyKey(Partition(null)).append<T>(type, id: id);

Commit generateCommit(
  int i, {
  String? sha,
  String branch = 'master',
  String? owner = 'flutter',
  String repo = 'flutter',
  int? timestamp,
}) => Commit(
  sha: sha ?? '$i',
  timestamp: timestamp ?? i,
  repository: '$owner/$repo',
  branch: branch,
  key: generateKey<String>(Commit, '$owner/$repo/$branch/${sha ?? '$i'}'),
);

github.Branch generateBranch(int i, {String? name, String? sha}) =>
    github.Branch(
      name ?? '$i',
      github.CommitData(
        sha,
        github.GitCommit(),
        null,
        null,
        null,
        null,
        null,
        null,
      ),
    );

github.Tag generateTag(int i, {String? name, String? sha}) => github.Tag(
  name ?? '$i',
  github.CommitInfo(sha, null),
  'blah_zip',
  'blah_tar',
);

Task generateTask(
  int i, {
  String? name,
  String status = Task.statusNew,
  int attempts = 1,
  bool isFlaky = false,
  String? builderName,
  String stage = 'test-stage',
  Commit? parent,
  int? buildNumber,
  DateTime? created,
}) => Task(
  name: name ?? 'task$i',
  status: status,
  commitKey: parent?.key ?? generateCommit(i).key,
  key: (parent ?? generateCommit(i)).key.append(Task, id: i),
  attempts: attempts,
  isFlaky: isFlaky,
  builderName: builderName,
  buildNumber: buildNumber,
  buildNumberList: buildNumber != null ? '$buildNumber' : null,
  createTimestamp: created?.millisecondsSinceEpoch ?? 0,
  stageName: stage,
);

firestore.Task generateFirestoreTask(
  int i, {
  String? name,
  String status = Task.statusNew,
  int attempts = 1,
  bool bringup = false,
  bool testFlaky = false,
  int? buildNumber,
  DateTime? created,
  DateTime? started,
  DateTime? ended,
  String? commitSha,
}) {
  final taskName = name ?? 'task$i';
  final sha = commitSha ?? 'testSha';
  final task =
      firestore.Task()
        ..name = '${sha}_${taskName}_$attempts'
        ..fields = <String, Value>{
          firestore.kTaskCreateTimestampField: Value(
            integerValue: (created?.millisecondsSinceEpoch ?? 0).toString(),
          ),
          firestore.kTaskStartTimestampField: Value(
            integerValue: (started?.millisecondsSinceEpoch ?? 0).toString(),
          ),
          firestore.kTaskEndTimestampField: Value(
            integerValue: (ended?.millisecondsSinceEpoch ?? 0).toString(),
          ),
          firestore.kTaskBringupField: Value(booleanValue: bringup),
          firestore.kTaskTestFlakyField: Value(booleanValue: testFlaky),
          firestore.kTaskStatusField: Value(stringValue: status),
          firestore.kTaskNameField: Value(stringValue: taskName),
          firestore.kTaskCommitShaField: Value(stringValue: sha),
        };
  if (buildNumber != null) {
    task.fields![firestore.kTaskBuildNumberField] = Value(
      integerValue: buildNumber.toString(),
    );
  }
  return task;
}

firestore_commit.Commit generateFirestoreCommit(
  int i, {
  String? sha,
  String branch = 'master',
  String? owner = 'flutter',
  String repo = 'flutter',
  int? createTimestamp,
  String? message = 'test message',
  String? author = 'author',
  String? avatar = 'avatar',
}) {
  final commit =
      firestore_commit.Commit()
        ..name = sha ?? '$i'
        ..fields = <String, Value>{
          firestore_commit.kCommitCreateTimestampField: Value(
            integerValue: (createTimestamp ?? i).toString(),
          ),
          firestore_commit.kCommitRepositoryPathField: Value(
            stringValue: '$owner/$repo',
          ),
          firestore_commit.kCommitBranchField: Value(stringValue: branch),
          firestore_commit.kCommitMessageField: Value(stringValue: message),
          firestore_commit.kCommitAuthorField: Value(stringValue: author),
          firestore_commit.kCommitAvatarField: Value(stringValue: avatar),
          firestore_commit.kCommitShaField: Value(stringValue: sha ?? '$i'),
        };
  return commit;
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
  final githubGoldStatus =
      GithubGoldStatus()
        ..name = '{$pr}_$head'
        ..fields = <String, Value>{
          kGithubGoldStatusHeadField: Value(stringValue: head),
          kGithubGoldStatusPrNumberField: Value(integerValue: pr.toString()),
          kGithubGoldStatusRepositoryField: Value(stringValue: '$owner/$repo'),
          kGithubGoldStatusUpdatesField: Value(
            integerValue: updates.toString(),
          ),
          kGithubGoldStatusDescriptionField: Value(stringValue: description),
          kGithubGoldStatusStatusField: Value(stringValue: status),
        };
  return githubGoldStatus;
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
  final githubBuildStatus =
      GithubBuildStatus()
        ..name = '{$pr}_$head'
        ..fields = <String, Value>{
          kGithubBuildStatusHeadField: Value(stringValue: head),
          kGithubBuildStatusPrNumberField: Value(integerValue: pr.toString()),
          kGithubBuildStatusRepositoryField: Value(stringValue: '$owner/$repo'),
          kGithubBuildStatusUpdatesField: Value(
            integerValue: updates.toString(),
          ),
          kGithubBuildStatusStatusField: Value(stringValue: status),
        };
  return githubBuildStatus;
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
}) {
  final config = schedulerConfig ?? exampleConfig.configFor(CiType.any);
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
      name: '$platform $i',
      properties: properties,
      dimensions: dimensions,
      runIf: runIf ?? <String>[],
      bringup: bringup ?? false,
      recipe: recipe,
      scheduler: schedulerSystem ?? pb.SchedulerSystem.cocoon,
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
