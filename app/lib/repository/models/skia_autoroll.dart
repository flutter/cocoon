// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import '../services/skia_autoroll_service.dart';
import 'providers.dart';

class SkiaAutoRoll {
  const SkiaAutoRoll({this.mode, this.lastRollResult});

  final String mode;
  final String lastRollResult;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SkiaAutoRoll otherStatus = other;
    return (otherStatus.mode == mode)
      && (otherStatus.lastRollResult == lastRollResult);
  }

  @override
  int get hashCode => hashValues(mode, lastRollResult);
}

class RefreshEngineFrameworkRoll extends RefreshAutoRoll {
  const RefreshEngineFrameworkRoll({@required Widget child}) : super(child: child, url: 'https://autoroll.skia.org/r/flutter-engine-flutter-autoroll/json/status');
}

class RefreshSkiaFlutterRoll extends RefreshAutoRoll {
  const RefreshSkiaFlutterRoll({@required Widget child}) : super(child: child, url: 'https://autoroll.skia.org/r/skia-flutter-autoroll/json/status');
}

class RefreshAutoRoll extends StatefulWidget {
  const RefreshAutoRoll({@required this.url, @required this.child});

  final String url;
  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshAutoRollState(url: url);
  }
}

class _RefreshAutoRollState extends State<RefreshAutoRoll> with AutomaticKeepAliveClientMixin<RefreshAutoRoll> {
  _RefreshAutoRollState({@required this.url});
  final String url;

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
      final SkiaAutoRoll status = await fetchSkiaAutoRollModeStatus(url);
      if (status != null) {
        ModelBinding.update<SkiaAutoRoll>(context, status);
      }
    } catch (error) {
      print('Error refreshing autoroller status $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

