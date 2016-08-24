// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'utils.dart';

typedef Future<Adb> AdbGetter();

/// Get an instance of [Adb].
///
/// See [realAdbGetter] for signature. This can be overwritten for testing.
AdbGetter adb = realAdbGetter;

Adb _currentDevice;

/// Picks a random Android device out of connected devices and sets it as
/// [_currentDevice].
Future<Null> pickNextDevice() async {
  List<Adb> allDevices = (await Adb.deviceIds)
    .map((String id) => new Adb(deviceId: id))
    .toList();

  if (allDevices.length == 0)
    throw 'No Android devices detected';

  // TODO(yjbanov): filter out and warn about those with low battery level
  _currentDevice = allDevices[new math.Random().nextInt(allDevices.length)];
}

Future<Adb> realAdbGetter() async {
  if (_currentDevice == null)
    await pickNextDevice();
  return _currentDevice;
}

/// Gets the ID of an unlocked device, unlocking it if necessary.
// TODO(yjbanov): abstract away iOS from Android.
Future<String> getUnlockedDeviceId({ bool ios: false }) async {
  if (ios) {
    // We currently do not have a way to lock/unlock iOS devices, or even to
    // pick one out of many. So we pick the first random iPhone and assume it's
    // already unlocked. For now we'll just keep them at minimum screen
    // brightness so they don't drain battery too fast.
    List<String> iosDeviceIds = grep('UniqueDeviceID', from: await eval('ideviceinfo', []))
      .map((String line) => line.split(' ').last).toList();

    if (iosDeviceIds.isEmpty)
      throw 'No connected iOS devices found.';

    return iosDeviceIds.first;
  }

  Adb device = await adb();
  device.unlock();
  return device.deviceId;
}

class Adb {
  Adb({String this.deviceId});

  final String deviceId;

  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = new RegExp(r'^(\S+)\s+(\S+)(.*)');

  static Future<Map<String, HealthCheckResult>> checkDevices() async {
    Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (String deviceId in await deviceIds) {
      try {
        Adb device = new Adb(deviceId: deviceId);
        // Just a smoke test that we can read wakefulness state
        // TODO(yjbanov): check battery level
        await device._getWakefulness();
        results['android-device-$deviceId'] = new HealthCheckResult.success();
      } catch(e, s) {
        results['android-device-$deviceId'] = new HealthCheckResult.error(e, s);
      }
    }
    return results;
  }

  /// Kills and restarts the `adb` server.
  ///
  /// Restarting `adb` helps with keeping device connections alive. When `adb`
  /// runs non-stop for too long it loses connections to devices.
  static Future restart() async {
    int exitCode = await exec(config.adbPath, ['kill-server'], canFail: false);

    if (exitCode != 0)
      throw 'Failed to kill ADB server';

    exitCode = await exec(config.adbPath, ['start-server'], canFail: false);

    if (exitCode != 0)
      throw 'Failed to start ADB server';
  }

  static Future<List<String>> get deviceIds async {
    List<String> output = (await eval(config.adbPath, ['devices', '-l'], canFail: false))
        .trim().split('\n');
    List<String> results = <String>[];
    for (String line in output) {
      // Skip lines like: * daemon started successfully *
      if (line.startsWith('* daemon '))
        continue;

      if (line.startsWith('List of devices'))
        continue;

      if (_kDeviceRegex.hasMatch(line)) {
        Match match = _kDeviceRegex.firstMatch(line);

        String deviceID = match[1];
        String deviceState = match[2];

        if (!const ['unauthorized', 'offline'].contains(deviceState)) {
          results.add(deviceID);
        }
      } else {
        throw 'Failed to parse device from adb output: $line';
      }
    }

    return results;
  }

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
    await exec(config.adbPath, ['shell', command]..addAll(arguments), env: env, canFail: false);
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) {
    return eval(config.adbPath, ['shell', command]..addAll(arguments), env: env, canFail: false);
  }
}
