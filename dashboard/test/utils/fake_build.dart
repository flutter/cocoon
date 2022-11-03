// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dashboard/logic/brooks.dart';
import 'package:flutter_dashboard/model/branch.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:flutter_dashboard/widgets/task_overlay.dart';

import 'mocks.dart';

class FakeBuildState extends ChangeNotifier implements BuildState {
  FakeBuildState({
    GoogleSignInService? authService,
    CocoonService? cocoonService,
    this.statuses = const <CommitStatus>[],
    this.moreStatusesExist = true,
    this.rerunTaskResult = false,
  })  : authService = authService ?? MockGoogleSignInService(),
        cocoonService = cocoonService ?? MockCocoonService();

  @override
  late GoogleSignInService authService;

  @override
  final CocoonService cocoonService;

  @override
  Timer? refreshTimer;

  @override
  final ErrorSink errors = ErrorSink();

  @override
  bool? isTreeBuilding;

  @override
  Duration? get refreshRate => const Duration(seconds: 30);

  @override
  Future<bool> refreshGitHubCommits() async => false;

  @override
  Future<bool> rerunTask(Task task) async {
    if (!rerunTaskResult) {
      errors.send(TaskOverlayContents.rerunErrorMessage);
      return false;
    }
    return true;
  }

  final bool rerunTaskResult;

  @override
  final List<CommitStatus> statuses;

  @override
  final bool moreStatusesExist;

  @override
  Future<void>? fetchMoreCommitStatuses() => null;

  @override
  List<Branch> get branches {
    final List<Branch> fakeBranches = <Branch>[];
    for (String repo in ['flutter', 'engine', 'cocoon']) {
      fakeBranches.add(
        Branch()
          ..repository = repo
          ..branch = defaultBranches[repo]!,
      );
      fakeBranches.addAll(
        <Branch>[
          Branch()
            ..repository = repo
            ..branch = '$repo-release',
          Branch()
            ..repository = repo
            ..branch = '$repo-release-very-long-name-that-should-be-truncated',
        ],
      );
    }
    return fakeBranches;
  }

  @override
  String get currentBranch => _currentBranch;
  String _currentBranch = 'master';

  @override
  List<String> get failingTasks => <String>[];

  @override
  String get currentRepo => _currentRepo;
  String _currentRepo = 'flutter';

  @override
  List<String> get repos => <String>['flutter', 'engine', 'cocoon'];

  @override
  Future<void> updateCurrentRepoBranch(String repo, String branch) async {
    _currentBranch = branch;
    _currentRepo = repo;
  }
}
