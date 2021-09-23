// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' as github;

Key<T> generateKey<T>(Type type, T id) => Key<T>.emptyKey(Partition('test-dashboard')).append<T>(type, id: id);

Commit generateCommit(
  int i, {
  String branch = 'master',
}) =>
    Commit(
      sha: '$i',
      repository: 'flutter/flutter',
      branch: branch,
      key: generateKey<String>(
        Commit,
        'flutter/flutter/$branch/$i',
      ),
    );

Task generateTask(int i,
        {String status = Task.statusNew, int attempts = 1, bool isFlaky = false, String stage = 'test-stage'}) =>
    Task(
      name: 'task$i',
      status: status,
      commitKey: generateCommit(i).key,
      key: generateKey<int>(Task, i),
      attempts: attempts,
      isFlaky: isFlaky,
      stageName: stage,
    );

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
