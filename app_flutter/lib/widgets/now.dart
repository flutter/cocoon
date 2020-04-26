// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// An inherited widget that reports the current time and
/// ticks once per second.
class Now extends InheritedNotifier<ValueNotifier<DateTime>> {
  /// For production.
  Now({
    Key key,
    Widget child,
  }) : super(
          key: key,
          notifier: _Clock(),
          child: child,
        );

  /// For tests.
  Now.fixed({
    Key key,
    @required DateTime dateTime,
    Widget child,
  })  : assert(dateTime != null),
        super(
          key: key,
          notifier: ValueNotifier<DateTime>(dateTime),
          child: child,
        );

  static DateTime of(BuildContext context) {
    final Now now = context.dependOnInheritedWidgetOfExactType<Now>();
    assert(now != null);
    return now.notifier.value;
  }
}

class _Clock extends ValueNotifier<DateTime> {
  _Clock() : super(null);

  Timer _timer;

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      assert(_timer == null);
      value = DateTime.now();
      _scheduleTick();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners && _timer != null) {
      _timer.cancel();
      _timer = null;
      value = null;
    }
  }

  void _tick() {
    value = DateTime.now();
    _scheduleTick();
    notifyListeners();
  }

  void _scheduleTick() {
    // To make the application appear responsive, we try to tick at the start of each second
    // (as opposed to just anywhere within a second, each second). To do that, each tick, we
    // set up a new timer to fire just as the time on the device reaches a new second, right
    // when the milliseconds component of the time is zero.
    //
    // To compute the time until the next second, we take the current time, ignore all parts
    // except the milliseconds, and subtract that from one second. (We have to take care and
    // never wait for zero milliseconds; if the milliseconds part is zero, then we must wait
    // a full second.)
    //
    // By scheduling a new tick each time, we also ensure that we skip past any seconds that
    // we were too busy to service without increasing the load on the device.
    _timer = Timer(Duration(milliseconds: 1000 - (value.millisecondsSinceEpoch % 1000)), _tick);
  }
}
