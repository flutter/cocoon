// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'utils.dart';

typedef Adb AdbGetter();

/// Get an instance of [Adb].
///
/// See [createRealAdb] for signature. This can be overwritten for testing.
AdbGetter adb = createRealAdb;

Adb createRealAdb() {
  return new Adb(deviceId: config.androidDeviceId);
}

class Adb {
  Adb({String this.deviceId});

  final String deviceId;

  /// Whether the device is awake.
  Future<bool> isAwake() async {
    return await _getWakefulness() == 'Awake';
  }

  /// Whether the device is asleep.
  Future<bool> isAsleep() async {
    return await _getWakefulness() == 'Asleep';
  }

  /// Wake up the device if it is not awake using [togglePower].
  Future<Null> wakeUp() async {
    if (!(await isAwake()))
      await togglePower();
  }

  /// Send the device to sleep mode if it is not asleep using [togglePower].
  Future<Null> sendToSleep() async {
    if (!(await isAsleep()))
      await togglePower();
  }

  /// Sends `KEYCODE_POWER` (26), which causes the device to toggle its mode
  /// between awake and asleep.
  Future<Null> togglePower() async {
    await shellExec('input', const ['keyevent', '26']);
  }

  /// Unlocks the device by sending `KEYCODE_MENU` (82).
  ///
  /// This only works when the device doesn't have a secure unlock pattern.
  Future<Null> unlock() async {
    await wakeUp();
    await shellExec('input', const ['keyevent', '82']);
  }

  /// Retrieves device's wakefulness state.
  ///
  /// See: https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/PowerManagerInternal.java
  Future<String> _getWakefulness() async {
    String powerInfo = await shellEval('dumpsys', ['power']);
    String wakefulness = grep('mWakefulness=', from: powerInfo).single.split('=')[1].trim();
    return wakefulness;
  }

  /// Executes [command] on `adb shell` and returns its exit code.
  Future<Null> shellExec(String command, List<String> arguments, {Map<String, String> env}) async {
    await exec(config.adbPath, ['shell', command]..addAll(arguments), env: env, canFail: false, onKill: _adbTimeout());
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) {
    return eval(config.adbPath, ['shell', command]..addAll(arguments), env: env, canFail: false, onKill: _adbTimeout());
  }

  Future<Null> _adbTimeout() => new Future<Null>.delayed(const Duration(seconds: 5));
}
