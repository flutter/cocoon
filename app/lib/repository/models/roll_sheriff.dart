// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/material.dart';

import '../services/sheriff_rotation_service.dart';
import 'providers.dart';

class RollSheriff {
  const RollSheriff({this.currentSheriff});

  final String currentSheriff;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final RollSheriff otherSheriff = other;
    return otherSheriff.currentSheriff == currentSheriff;
  }

  @override
  int get hashCode => currentSheriff.hashCode;
}

class RefreshSheriffRotation extends StatefulWidget {
  const RefreshSheriffRotation({@required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _RefreshSheriffRotationState();
  }
}

class _RefreshSheriffRotationState extends State<RefreshSheriffRotation>
    with AutomaticKeepAliveClientMixin<RefreshSheriffRotation> {
  _RefreshSheriffRotationState();

  Timer _refreshTimer;

  @override
  void initState() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), _refresh);
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
      final RollSheriff sheriff = await fetchSheriff();
      if (sheriff != null) {
        ModelBinding.update<RollSheriff>(context, sheriff);
      }
    } catch (error) {
      print('Error refreshing roll sheriff $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
