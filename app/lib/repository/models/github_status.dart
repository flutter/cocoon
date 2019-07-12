// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import '../services/github_status_service.dart';
import 'providers.dart';

class GitHubStatus {
  const GitHubStatus({this.status, this.indicator});

  final String status;
  final String indicator;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final GitHubStatus otherStatus = other;
    return (otherStatus.status == status)
      && (otherStatus.indicator == indicator);
  }

  @override
  int get hashCode => hashValues(status, indicator);
}

class RefreshGitHubStatus extends StatefulWidget {
  const RefreshGitHubStatus({@required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshGitHubStatusState();
  }
}

class _RefreshGitHubStatusState extends State<RefreshGitHubStatus> with AutomaticKeepAliveClientMixin<RefreshGitHubStatus> {
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

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh(Timer timer) async {
    try {
      final GitHubStatus status = await fetchGitHubStatus();
      if (status != null) {
        ModelBinding.update<GitHubStatus>(context, status);
      }
    } catch (error) {
      print('Error refreshing GitHub status $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

