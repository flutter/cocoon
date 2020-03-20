// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, Task;

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/brooks.dart';
import 'package:app_flutter/state/flutter_build.dart';

class FakeFlutterBuildState extends ChangeNotifier implements FlutterBuildState {
  @override
  GoogleSignInService authService = GoogleSignInService();

  @override
  Timer refreshTimer;

  @override
  final ErrorSink errors = ErrorSink();

  @override
  bool isTreeBuilding;

  @override
  Duration get refreshRate => null;

  @override
  Future<bool> rerunTask(Task task) => null;

  @override
  Future<void> signIn() => null;

  @override
  Future<void> signOut() => null;

  @override
  Future<void> startFetchingUpdates() => null;

  @override
  List<CommitStatus> statuses = <CommitStatus>[];

  @override
  Future<bool> downloadLog(Task task, Commit commit) => null;

  @override
  Future<void> fetchMoreCommitStatuses() => null;

  @override
  List<String> get branches => <String>['master'];

  @override
  String get currentBranch => 'master';
}
