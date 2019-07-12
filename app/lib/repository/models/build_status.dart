// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import '../services/build_status_service.dart';
import 'providers.dart';

class BuildStatus {
  const BuildStatus({this.anticipatedBuildStatus, this.failingAgents = const <String>[], this.commitTestResults = const <CommitTestResult>[]});

  final String anticipatedBuildStatus;
  final List<String> failingAgents;
  final List<CommitTestResult> commitTestResults;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final BuildStatus otherStatus = other;
    return (otherStatus.anticipatedBuildStatus == anticipatedBuildStatus)
      && const ListEquality().equals(otherStatus.failingAgents, failingAgents)
      && const DeepCollectionEquality().equals(otherStatus.commitTestResults, commitTestResults);
  }

  @override
  int get hashCode => hashValues(anticipatedBuildStatus, failingAgents);
}

class CommitTestResult {
  const CommitTestResult({this.sha, this.authorName, this.avatarImageURL, this.createDateTime, this.inProgressTestCount, this.succeededTestCount, this.failedFlakyTestCount, this.failedTestCount, this.failingTests = const <String>[]});
  final String sha;
  final String authorName;
  final String avatarImageURL;
  final DateTime createDateTime;
  final int inProgressTestCount;
  final int succeededTestCount;
  final int failedFlakyTestCount;
  final int failedTestCount;
  final List<String> failingTests;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final CommitTestResult otherResult = other;
    return (otherResult.sha == sha)
      && (otherResult.authorName == authorName)
      && (otherResult.avatarImageURL == avatarImageURL)
      && (otherResult.createDateTime == createDateTime)
      && (otherResult.inProgressTestCount == inProgressTestCount)
      && (otherResult.succeededTestCount == succeededTestCount)
      && (otherResult.failedFlakyTestCount == failedFlakyTestCount)
      && (otherResult.failedTestCount == failedTestCount)
      && const ListEquality().equals(otherResult.failingTests, failingTests);
  }

  @override
  int get hashCode => hashValues(sha, authorName, avatarImageURL, createDateTime, inProgressTestCount, succeededTestCount, failedFlakyTestCount, failedTestCount, failingTests);
}

class RefreshBuildStatus extends StatefulWidget {
  const RefreshBuildStatus({@required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshRefreshBuildStatusState();
  }
}

class _RefreshRefreshBuildStatusState extends State<RefreshBuildStatus> with AutomaticKeepAliveClientMixin<RefreshBuildStatus> {
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

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh(Timer timer) async {
    try {
      final BuildStatus status = await fetchBuildStatus();
      if (status != null) {
        ModelBinding.update<BuildStatus>(context, status);
      }
    } catch (error) {
      print('Error refreshing build status $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

