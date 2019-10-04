// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import '../service/cocoon.dart';

/// State for the Flutter Build Dashboard
class FlutterBuildState extends ChangeNotifier {
  /// Creates a new [FlutterBuildState].
  ///
  /// If [CocoonService] is not specified, a new [CocoonService] instance is created.
  FlutterBuildState({CocoonService cocoonService})
      : _cocoonService = cocoonService ?? CocoonService();

  /// Cocoon backend service that retrieves the data needed for this state.
  final CocoonService _cocoonService;

  /// How often to query the Cocoon backend for the current build state.
  @visibleForTesting
  final Duration refreshRate = const Duration(seconds: 10);

  /// Timer that calls [_fetchBuildStatusUpdate] on a set interval.
  @visibleForTesting
  Timer refreshTimer;

  /// The current status of the commits loaded.
  final CocoonResponse<List<CommitStatus>> _statuses =
      CocoonResponse<List<CommitStatus>>()..data = <CommitStatus>[];
  CocoonResponse<List<CommitStatus>> get statuses => _statuses;

  /// Whether or not flutter/flutter currently passes tests.
  final CocoonResponse<bool> _isTreeBuilding = CocoonResponse<bool>()
    ..data = false;
  CocoonResponse<bool> get isTreeBuilding => _isTreeBuilding;

  /// Whether an error occured getting the latest data for the fields of this state.
  bool get hasError => _isTreeBuilding.error != null || _statuses.error != null;

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
      _cocoonService.fetchCommitStatuses().then(
          (List<CommitStatus> commitStatuses) {
        _statuses.data = commitStatuses;
        _statuses.error = null;
      }, onError: (dynamic error) {
        _statuses.error = error.toString();
      }),
      _cocoonService.fetchTreeBuildStatus().then((bool treeStatus) {
        _isTreeBuilding.data = treeStatus;
        _isTreeBuilding.error = null;
      }, onError: (dynamic error) {
        _isTreeBuilding.error = error.toString();
      }),
    ]);

    notifyListeners();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
}

/// Wrapper class for data this state serves.
///
/// Holds [data] and possible error information.
class CocoonResponse<T> {
  /// The data that gets used from [CocoonService].
  T data;

  /// Error information that can be used for debugging.
  String error;
}
