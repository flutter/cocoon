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
  final Duration _refreshRate = Duration(seconds: 10);

  /// Timer that calls [_fetchBuildStatusUpdate] on a set interval.
  Timer _refreshTimer;

  /// The current status of the commits loaded.
  List<CommitStatus> statuses = [];

  /// Start a fixed interval loop that fetches build state updates based on [_refreshRate].
  void startFetchingBuildStateUpdates() async {
    if (_refreshTimer != null) {
      throw 'already fetching build state updates';
    }

    _refreshTimer =
        Timer.periodic(_refreshRate, (t) => _fetchBuildStatusUpdate());
  }

  /// Request the latest [statuses] from [CocoonService].
  void _fetchBuildStatusUpdate() async {
    statuses = await _cocoonService.fetchCommitStatuses();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();

    _refreshTimer?.cancel();
  }
}
