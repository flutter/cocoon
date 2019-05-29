// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import 'providers.dart';
import '../services/build_status_service.dart';

class BuildStatus {
  const BuildStatus({this.anticipatedBuildStatus, this.failingAgents = const <String>[]});

  final String anticipatedBuildStatus;
  final List<String> failingAgents;

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
      && (otherStatus.failingAgents == failingAgents);
  }

  @override
  int get hashCode => hashValues(anticipatedBuildStatus, failingAgents);
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
      BuildStatus status = await fetchBuildStatus();
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

