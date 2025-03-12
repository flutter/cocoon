// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dashboard/logic/brooks.dart';
import 'package:flutter_dashboard/model/commit.pb.dart';
import 'package:flutter_dashboard/model/commit_status.pb.dart';
import 'package:flutter_dashboard/model/task.pb.dart';
import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/src/rpc_model.dart';
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
  }) : authService = authService ?? MockGoogleSignInService(),
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
  Future<bool> rerunTask(Task task, Commit commit) async {
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
    // TODO(matanlurey): Previously the channel names were implicitly empty,
    // which meant the UI fit in a very small screen (Pixel 4-ish). To make
    // these more "real" the build_dashboard_page_test.dart will need to be
    // updated to have a larger UI *or* widget changes will need to be made to
    // fit better on a mobile device.
    return [
      Branch(channel: '', reference: 'master'),
      Branch(channel: '', reference: 'stable-release'),
      Branch(
        channel: '',
        reference: 'release-very-long-name-that-should-be-truncated',
      ),
    ];
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
  List<String> get repos => <String>['flutter', 'cocoon'];

  @override
  Future<void> updateCurrentRepoBranch(String repo, String branch) async {
    _currentBranch = branch;
    _currentRepo = repo;
  }
}
