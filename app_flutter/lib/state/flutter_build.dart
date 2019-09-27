// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import '../service/cocoon.dart';

/// State for the build dashboard based on what is collected
class FlutterBuildState extends ChangeNotifier {
  /// Cocoon backend service that retrieves the data needed
  final CocoonService _cocoonService = CocoonService();

  /// How often to query the Cocoon backend for the current build state.
  final Duration refreshRate = Duration(seconds: 1);

  List<CommitStatus> statuses = [];

  Timer updateTimer;

  void startFetchingBuildStatusUpdates() async {
    print('start fetching!');
    updateTimer = Timer.periodic(refreshRate, (t) => _fetchBuildStatusUpdate());
  }

  void _fetchBuildStatusUpdate() async {
    print('updating!');

    statuses = await _cocoonService.fetchCommitStatuses();
    notifyListeners();
  }
}
