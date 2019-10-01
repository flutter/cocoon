// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import '../service/cocoon.dart';

/// State for the Flutter Build Dashboard
class FlutterBuildState extends ChangeNotifier {
  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService _cocoonService;

  /// How often to query the Cocoon backend for the current build state.
  @visibleForTesting
  final Duration refreshRate = Duration(seconds: 10);

  /// Timer that calls [_fetchBuildStatusUpdate] on a set interval.
  @visibleForTesting
  Timer refreshTimer;

  /// The current status of the commits loaded.
  List<CommitStatus> statuses = [];

  /// Whether or not flutter/flutter currently passes tests.
  bool get isTreeBuilding => _isTreeBuilding;
  bool _isTreeBuilding = true;

  /// Creates a new [FlutterBuildState].
  ///
  /// If [CocoonService] is not specified, a new [CocoonService] instance is created.
  FlutterBuildState({CocoonService cocoonService})
      : _cocoonService = cocoonService ?? CocoonService();

  /// Start a fixed interval loop that fetches build state updates based on [refreshRate].
  void startFetchingBuildStateUpdates() async {
    if (refreshTimer != null) {
      // There's already an update loop, no need to make another.
      return;
    }

    /// [Timer.periodic] does not necessarily run at the start of the timer.
    _fetchBuildStatusUpdate();

    refreshTimer =
        Timer.periodic(refreshRate, (t) => _fetchBuildStatusUpdate());
  }

  /// Request the latest [statuses] from [CocoonService].
  void _fetchBuildStatusUpdate() async {
    await Future.wait([
      _cocoonService
          .fetchCommitStatuses()
          .then((commitStatuses) => statuses = commitStatuses),
      _cocoonService
          .fetchTreeBuildStatus()
          .then((treeStatus) => _isTreeBuilding = treeStatus),
    ]);

    notifyListeners();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
}
