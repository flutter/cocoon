// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/material.dart';

import '../services/github_service.dart';
import 'providers.dart';

class RollHistory {
  DateTime lastSkiaAutoRoll;
  DateTime lastEngineRoll;
  DateTime lastDevBranchRoll;
  DateTime lastBetaBranchRoll;
  DateTime lastStableBranchRoll;

  RollHistory copy() {
    return RollHistory()
      ..lastSkiaAutoRoll = lastSkiaAutoRoll
      ..lastEngineRoll = lastEngineRoll
      ..lastDevBranchRoll = lastDevBranchRoll
      ..lastBetaBranchRoll = lastBetaBranchRoll
      ..lastStableBranchRoll = lastStableBranchRoll;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final RollHistory otherHistory = other;
    return (otherHistory.lastSkiaAutoRoll == lastSkiaAutoRoll)
      && (otherHistory.lastEngineRoll == lastEngineRoll)
      && (otherHistory.lastDevBranchRoll == lastDevBranchRoll)
      && (otherHistory.lastBetaBranchRoll == lastBetaBranchRoll)
      && (otherHistory.lastStableBranchRoll == lastStableBranchRoll);
  }

  @override
  int get hashCode => hashValues(lastSkiaAutoRoll, lastEngineRoll, lastDevBranchRoll, lastBetaBranchRoll, lastStableBranchRoll);
}

class RefreshRollHistory extends StatefulWidget {
  const RefreshRollHistory({@required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshRollHistoryState();
  }
}

class _RefreshRollHistoryState extends State<RefreshRollHistory> {
  Timer _refreshTimer;

  @override
  void initState() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), _refresh);
    super.initState();
    Timer.run(() => _refresh(null));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh(Timer timer) async {
    final RollHistory rollHistory = ModelBinding.of<RollHistory>(context).copy();
    await _updateLastSkiaAutoRoll(rollHistory);
    await _updateLastEngineAutoRoll(rollHistory);
    await _updateLastDevBranchRoll(rollHistory);
    await _updateLastBetaBranchRoll(rollHistory);
    await _updateLastStableBranchRoll(rollHistory);

    ModelBinding.update<RollHistory>(context, rollHistory);
  }

  Future<void> _updateLastSkiaAutoRoll(RollHistory history) async {
    try {
      DateTime fetchedDate = await lastCommitFromAuthor('engine', 'skia-flutter-autoroll');
      if (fetchedDate != null) {
        history.lastSkiaAutoRoll = fetchedDate;
      }
    } catch (error) {
      print('Error refreshing last Skia auto-roll $error');
    }
  }

  Future<void> _updateLastEngineAutoRoll(RollHistory history) async {
    try {
      DateTime fetchedDate = await lastCommitFromAuthor('flutter', 'engine-flutter-autoroll');
      if (fetchedDate != null) {
        history.lastEngineRoll = fetchedDate;
      }
    } catch (error) {
      print('Error refreshing last engine auto-roll $error');
    }
  }

  Future<void> _updateLastDevBranchRoll(RollHistory history) async {
    try {
      DateTime fetchedDate = await fetchFlutterBranchLastCommitDate('dev');
      if (fetchedDate != null) {
        history.lastDevBranchRoll = fetchedDate;
      }
    } catch (error) {
      print('Error refreshing last dev commit date: $error');
    }
  }

  Future<void> _updateLastBetaBranchRoll(RollHistory history) async {
    try {
      DateTime fetchedDate = await fetchFlutterBranchLastCommitDate('beta');
      if (fetchedDate != null) {
        history.lastBetaBranchRoll = fetchedDate;
      }
    } catch (error) {
      print('Error refreshing last beta commit date: $error');
    }
  }

  Future<void> _updateLastStableBranchRoll(RollHistory history) async {
    try {
      DateTime fetchedDate = await fetchFlutterBranchLastCommitDate('stable');
      if (fetchedDate != null) {
        history.lastStableBranchRoll = fetchedDate;
      }
    } catch (error) {
      print('Error refreshing last stable commit date: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
