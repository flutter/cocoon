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
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
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
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), _refresh);
    super.initState();
    Timer.run(() => _refresh(null));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refresh(Timer timer) {
    _fetchLastSkiaAutoRoll(() {
      _fetchLastEngineAutoRoll(() {
        _fetchLastDevBranchRoll(() {
          _fetchLastBetaBranchRoll(() {
            _fetchLastStableBranchRoll(null);
          });
        });
      });
    });
  }

  void _fetchLastSkiaAutoRoll(Function nextStep) {
    GithubService.lastCommitFromAuthor('engine', 'skia-flutter-autoroll').then((fetchedDate) {
      if (fetchedDate != null) {
        RollHistory skiaAutoRollHistory = ModelBinding.of<RollHistory>(context).copy();
        skiaAutoRollHistory.lastSkiaAutoRoll = fetchedDate;
        ModelBinding.update<RollHistory>(context, skiaAutoRollHistory);
      }
      if (nextStep != null) nextStep();
    }, onError: (skiaRollError) {
      print('Error refreshing last Skia auto-roll $skiaRollError');
    });
  }

  void _fetchLastEngineAutoRoll(Function nextStep) {
    GithubService.lastCommitFromAuthor('flutter', 'engine-flutter-autoroll').then((fetchedDate) {
      if (fetchedDate != null) {
        RollHistory history = ModelBinding.of<RollHistory>(context).copy();
        history.lastEngineRoll = fetchedDate;
        ModelBinding.update<RollHistory>(context, history);
      }
      if (nextStep != null) nextStep();
    }, onError: (engineRollError) {
      print('Error refreshing last engine auto-roll $engineRollError');
    });
  }

  void _fetchLastDevBranchRoll(Function nextStep) {
    GithubService.fetchFlutterBranchLastCommitDate('dev').then((fetchedDate) {
      if (fetchedDate != null) {
        RollHistory history = ModelBinding.of<RollHistory>(context).copy();
        history.lastDevBranchRoll = fetchedDate;
        ModelBinding.update<RollHistory>(context, history);
      }
      if (nextStep != null) nextStep();
    }, onError: (detailsError) {
      print('Error refreshing last dev commit date: $detailsError');
    });
  }

  void _fetchLastBetaBranchRoll(Function nextStep) {
    GithubService.fetchFlutterBranchLastCommitDate('beta').then((fetchedDate) {
      if (fetchedDate != null) {
        RollHistory history = ModelBinding.of<RollHistory>(context).copy();
        history.lastBetaBranchRoll = fetchedDate;
        ModelBinding.update<RollHistory>(context, history);
      }
      if (nextStep != null) nextStep();
    }, onError: (detailsError) {
      print('Error refreshing last beta commit date: $detailsError');
    });
  }

  void _fetchLastStableBranchRoll(Function nextStep) {
    GithubService.fetchFlutterBranchLastCommitDate('stable').then((fetchedDate) {
      if (fetchedDate != null) {
        RollHistory history = ModelBinding.of<RollHistory>(context).copy();
        history.lastStableBranchRoll = fetchedDate;
        ModelBinding.update<RollHistory>(context, history);
      }
      if (nextStep != null) nextStep();
    }, onError: (detailsError) {
      print('Error refreshing last stable commit date: $detailsError');
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
