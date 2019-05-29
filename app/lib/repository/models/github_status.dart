// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import '../services/github_status_service.dart';
import 'providers.dart';

class GithubStatus {
  const GithubStatus({this.status, this.indicator});

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
    final GithubStatus otherStatus = other;
    return (otherStatus.status == status)
      && (otherStatus.indicator == indicator);
  }

  @override
  int get hashCode => hashValues(status, indicator);
}

class RefreshGithubStatus extends StatefulWidget {
  const RefreshGithubStatus({@required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshGithubStatusState();
  }
}

class _RefreshGithubStatusState extends State<RefreshGithubStatus> with AutomaticKeepAliveClientMixin<RefreshGithubStatus> {
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
      final GithubStatus status = await fetchGithubStatus();
      if (status != null) {
        ModelBinding.update<GithubStatus>(context, status);
      }
    } catch (error) {
      print('Error refreshing Github status $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

