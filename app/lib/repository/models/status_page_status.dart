// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import '../services/status_page_service.dart';
import 'providers.dart';

class StatusPageStatus {
  const StatusPageStatus({this.status, this.indicator});

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
    final StatusPageStatus otherStatus = other;
    return otherStatus.status == status && otherStatus.indicator == indicator;
  }

  @override
  int get hashCode => hashValues(status, indicator);
}

class RefreshGitHubStatus extends RefreshStatusPageStatus {
  const RefreshGitHubStatus({@required Widget child})
      : super(child: child, url: 'https://kctbh9vrtdwd.statuspage.io/api/v2/status.json');
}

class RefreshCoverallsStatus extends RefreshStatusPageStatus {
  const RefreshCoverallsStatus({@required Widget child})
      : super(child: child, url: 'https://status.coveralls.io/api/v2/status.json');
}

class RefreshStatusPageStatus extends StatefulWidget {
  const RefreshStatusPageStatus({@required this.url, @required this.child});

  final String url;
  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshStatusPageStatusState();
  }
}

class _RefreshStatusPageStatusState extends State<RefreshStatusPageStatus>
    with AutomaticKeepAliveClientMixin<RefreshStatusPageStatus> {
  _RefreshStatusPageStatusState();

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
      final StatusPageStatus status = await fetchStatusPageStatus(widget.url);
      if (status != null) {
        ModelBinding.update<StatusPageStatus>(context, status);
      }
    } catch (error) {
      print('Error refreshing StatusPage status $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
