// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;
import 'package:fixnum/fixnum.dart';
import 'package:http/src/mock_client.dart';

import 'appengine_cocoon.dart';

/// Service class for interacting with flutter/flutter build data.
///
/// This service exists as a common interface for getting build data from a data source.
abstract class CocoonService {
  /// Creates a new [CocoonService] based on if the Flutter app is in production.
  ///
  /// Production uses the Cocoon backend running on AppEngine.
  /// Otherwise, it uses fake data populated from a mock service.
  factory CocoonService() {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      return AppEngineCocoonService();
    }

    return MockCocoonService();
  }

  /// Gets build information from the last 200 commits.
  ///
  /// TODO(chillers): Make configurable to get range of commits
  Future<List<CommitStatus>> getStats();
}

class MockCocoonService implements CocoonService {
  @override
  Future<List<CommitStatus>> getStats() {
    return Future.delayed(Duration(seconds: 1), () => _getFakeStats());
  }

  List<CommitStatus> _getFakeStats() {
    List<CommitStatus> stats = List();

    final int baseTimestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < 100; i++) {
      Commit commit = _getFakeCommit(i, baseTimestamp);

      CommitStatus status = CommitStatus()
        ..commit = commit
        ..stages.addAll(_getFakeStages(i, commit));

      stats.add(status);
    }

    return stats;
  }

  Commit _getFakeCommit(int index, int baseTimestamp) {
    return Commit()
      ..author = 'Author McAuthory $index'
      ..authorAvatarUrl = 'https://avatars2.githubusercontent.com/u/2148558?v=4'
      ..repository = 'flutter/cocoon'
      ..sha = 'Sha Shank Hash $index'
      ..timestamp = (baseTimestamp - (index * 100)) as Int64;
  }

  List<Stage> _getFakeStages(int index, Commit commit) {
    List<Stage> stages = List();

    stages.add(Stage()
      ..commit = commit
      ..name = 'chromebot'
      ..tasks.addAll(List.generate(3, (i) => _getFakeTask(i))));

    // TODO(chillers): Generate multiple stages to mimick production.

    return stages;
  }

  Task _getFakeTask(int index) {
    return Task();
  }
}
