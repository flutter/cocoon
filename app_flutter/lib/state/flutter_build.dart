// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, Task;

import '../service/cocoon.dart';
import '../service/google_authentication.dart';

/// State for the Flutter Build Dashboard
class FlutterBuildState extends ChangeNotifier {
  /// Creates a new [FlutterBuildState].
  ///
  /// If [CocoonService] is not specified, a new [CocoonService] instance is created.
  FlutterBuildState({
    CocoonService cocoonServiceValue,
    GoogleSignInService authServiceValue,
  })  : _cocoonService = cocoonServiceValue ?? CocoonService(),
        authService = authServiceValue ?? GoogleSignInService() {
    authService.notifyListeners = notifyListeners;
  }

  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService _cocoonService;

  /// Authentication service for managing Google Sign In.
  GoogleSignInService authService;

  /// How often to query the Cocoon backend for the current build state.
  @visibleForTesting
  final Duration refreshRate = const Duration(seconds: 10);

  /// Timer that calls [_fetchBuildStatusUpdate] on a set interval.
  @visibleForTesting
  Timer refreshTimer;

  /// The current status of the commits loaded.
  List<CommitStatus> _statuses = <CommitStatus>[];
  List<CommitStatus> get statuses => _statuses;

  /// Whether or not flutter/flutter currently passes tests.
  bool _isTreeBuilding;
  bool get isTreeBuilding => _isTreeBuilding;

  /// A [ChangeNotifer] for knowing when errors occur that relate to this [FlutterBuildState].
  FlutterBuildStateErrors errors = FlutterBuildStateErrors();

  @visibleForTesting
  static const String errorMessageFetchingStatuses =
      'An error occured fetching build statuses from Cocoon';

  @visibleForTesting
  static const String errorMessageFetchingTreeStatus =
      'An error occured fetching tree status from Cocoon';

  /// Start a fixed interval loop that fetches build state updates based on [refreshRate].
  Future<void> startFetchingBuildStateUpdates() async {
    if (refreshTimer != null) {
      // There's already an update loop, no need to make another.
      return;
    }

    /// [Timer.periodic] does not necessarily run at the start of the timer.
    _fetchBuildStatusUpdate();

    refreshTimer =
        Timer.periodic(refreshRate, (_) => _fetchBuildStatusUpdate());
  }

  /// Request the latest [statuses] and [isTreeBuilding] from [CocoonService].
  Future<void> _fetchBuildStatusUpdate() async {
    await Future.wait(<Future<void>>[
      _cocoonService
          .fetchCommitStatuses()
          .then((CocoonResponse<List<CommitStatus>> response) {
        if (response.error != null) {
          print(response.error);
          errors.message = errorMessageFetchingStatuses;
          errors.notifyListeners();
        } else {
          _statuses = response.data;
        }
        notifyListeners();
      }),
      _cocoonService
          .fetchTreeBuildStatus()
          .then((CocoonResponse<bool> response) {
        if (response.error != null) {
          print(response.error);
          errors.message = errorMessageFetchingTreeStatus;
          errors.notifyListeners();
        } else {
          _isTreeBuilding = response.data;
        }
        notifyListeners();
      }),
    ]);
  }

  Future<void> signIn() => authService.signIn();
  Future<void> signOut() => authService.signOut();

  Future<bool> rerunTask(Task task) async {
    return _cocoonService.rerunTask(task, await authService.idToken);
  }

  Future<bool> downloadLog(Task task, Commit commit) async {
    return _cocoonService.downloadLog(
        task, await authService.idToken, commit.sha);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
}

class FlutterBuildStateErrors extends ChangeNotifier {
  String message;
}
