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
  final CocoonService _cocoonService = CocoonService();

  /// How often to query the Cocoon backend for the current build state.
  final Duration refreshRate = Duration(seconds: 10);

  /// The current status of the commits loaded.
  List<CommitStatus> statuses = [];

  Timer _updateTimer;

  void startFetchingBuildStatusUpdates() async {
    _updateTimer =
        Timer.periodic(refreshRate, (t) => _fetchBuildStatusUpdate());
  }

  void stopFetchingBuildStatusUpdate() {
    _updateTimer.cancel();
  }

  void _fetchBuildStatusUpdate() async {
    statuses = await _cocoonService.fetchCommitStatuses();
    notifyListeners();
  }
}
