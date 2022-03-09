// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as push_message;
import 'package:cocoon_service/src/model/proto/protos.dart' as pb;
import 'package:gcloud/db.dart';
import 'package:github/github.dart' as github;

import '../service/fake_scheduler.dart';

Key<T> generateKey<T>(Type type, T id) => Key<T>.emptyKey(Partition('flutter-dashboard')).append<T>(type, id: id);

Commit generateCommit(
  int i, {
  String? sha,
  String branch = 'master',
  String repo = 'flutter',
}) =>
    Commit(
      sha: sha ?? '$i',
      repository: 'flutter/$repo',
      branch: branch,
      key: generateKey<String>(
        Commit,
        'flutter/$repo/$branch/' + (sha ?? '$i'),
      ),
    );

Task generateTask(
  int i, {
  String? name,
  String status = Task.statusNew,
  int attempts = 1,
  bool isFlaky = false,
  String stage = 'test-stage',
  Commit? parent,
  int? buildNumber,
}) =>
    Task(
      name: name ?? 'task$i',
      status: status,
      commitKey: parent?.key ?? generateCommit(i).key,
      key: (parent ?? generateCommit(i)).key.append(Task, id: i),
      attempts: attempts,
      isFlaky: isFlaky,
      buildNumber: buildNumber,
      buildNumberList: buildNumber != null ? '$buildNumber' : null,
      stageName: stage,
    );

Target generateTarget(
  int i, {
  pb.SchedulerConfig? schedulerConfig,
  String platform = 'Linux',
  Map<String, String>? platformProperties,
  Map<String, String>? properties,
  List<String>? runIf,
  github.RepositorySlug? slug,
}) {
  final pb.SchedulerConfig config = schedulerConfig ?? exampleConfig.config;
  if (platformProperties != null) {
    config.platformProperties[platform.toLowerCase()] = pb.SchedulerConfig_Properties(properties: platformProperties);
  }
  return Target(
    schedulerConfig: config,
    slug: slug ?? github.RepositorySlug('flutter', 'flutter'),
    value: pb.Target(
      name: '$platform $i',
      properties: properties,
      runIf: runIf ?? <String>[],
    ),
  );
}

Build generateBuild(
  int i, {
  String bucket = 'prod',
  String name = 'Linux test_builder',
  Status status = Status.success,
  Map<String?, List<String?>>? tags,
  int buildNumber = 1,
}) =>
    Build(
      id: i.toString(),
      builderId: BuilderId(
        project: 'flutter',
        bucket: bucket,
        builder: name,
      ),
      status: status,
      tags: tags,
      number: buildNumber,
    );

push_message.Build generatePushMessageBuild(
  int i, {
  String bucket = 'prod',
  String name = 'Linux test_builder',
  push_message.Status? status = push_message.Status.completed,
  push_message.Result result = push_message.Result.success,
  List<String>? tags,
  int buildNumber = 1,
  DateTime? completedTimestamp,
  DateTime? createdTimestamp,
  DateTime? startedTimestamp,
}) {
  tags ??= <String>[];
  tags.add('build_address:luci.flutter.prod/$name/$buildNumber');

  return push_message.Build(
    bucket: bucket,
    id: i.toString(),
    project: 'flutter',
    status: status,
    result: result,
    createdTimestamp: createdTimestamp,
    completedTimestamp: completedTimestamp,
    startedTimestamp: startedTimestamp,
    tags: tags,
  );
}

github.CheckRun generateCheckRun(
  int i, {
  int checkSuite = 2,
  DateTime? startedAt,
}) {
  startedAt ??= DateTime.utc(2020, 05, 12);
  return github.CheckRun.fromJson(<String, dynamic>{
    'id': i,
    'started_at': startedAt.toIso8601String(),
    'check_suite': <String, dynamic>{'id': checkSuite}
  });
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
  String sha = 'abc',
  bool merged = true,
}) {
  mergedAt ??= DateTime.fromMillisecondsSinceEpoch(1);
  return github.PullRequest(
    id: id,
    title: title,
    number: number,
    mergedAt: mergedAt,
    base: github.PullRequestHead(
        ref: branch,
        repo: github.Repository(
          fullName: 'flutter/$repo',
          name: repo,
          owner: github.UserInformation('flutter', 1, '', ''),
        )),
    head: github.PullRequestHead(
      ref: branch,
      sha: sha,
    ),
    user: github.User(
      login: authorLogin,
      avatarUrl: authorAvatar,
    ),
    mergeCommitSha: sha,
    merged: merged,
  );
}
