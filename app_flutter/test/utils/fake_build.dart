// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/models.dart' show Commit, CommitStatus, Task;

import 'package:app_flutter/logic/brooks.dart';
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/build.dart';

import 'mocks.dart';

class FakeBuildState extends ChangeNotifier implements BuildState {
  FakeBuildState({
    GoogleSignInService authService,
    CocoonService cocoonService,
    this.statuses = const <CommitStatus>[],
    this.moreStatusesExist = true,
    this.rerunTaskResult,
  })  : authService = authService ?? MockGoogleSignInService(),
        cocoonService = cocoonService ?? MockCocoonService();

  @override
  final GoogleSignInService authService;

  @override
  final CocoonService cocoonService;

  @override
  Timer refreshTimer;

  @override
  final ErrorSink errors = ErrorSink();

  @override
  bool isTreeBuilding;

  @override
  Duration get refreshRate => null;

  @override
  Future<bool> rerunTask(Task task) async => rerunTaskResult;
  final bool rerunTaskResult;

  @override
  final List<CommitStatus> statuses;

  @override
  final bool moreStatusesExist;

  @override
  Future<bool> downloadLog(Task task, Commit commit) => null;

  @override
  Future<void> fetchMoreCommitStatuses() => null;

  @override
  List<String> get branches => <String>['master'];

  @override
  String get currentBranch => 'master';

  @override
  Future<void> updateCurrentBranch(String branch) => throw UnimplementedError();

  @override
  List<String> get failingTasks => <String>[];
}
