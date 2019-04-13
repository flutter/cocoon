// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter;

import 'package:meta/meta.dart';

import 'utils.dart';

/// The root of the API for controlling devices.
DeviceDiscovery get devices => DeviceDiscovery();

/// Operating system on the devices that this agent is configured to test.
enum DeviceOperatingSystem { android, ios }

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery() {
    switch (config.deviceOperatingSystem) {
      case DeviceOperatingSystem.android:
        return AndroidDeviceDiscovery();
      case DeviceOperatingSystem.ios:
        return IosDeviceDiscovery();
      default:
        throw StateError(
            'Unsupported device operating system: {config.deviceOperatingSystem}');
    }
  }

  /// Lists all available devices' IDs.
  Future<List<Device>> discoverDevices();

  /// Checks the health of the available devices.
  Future<Map<String, HealthCheckResult>> checkDevices();

  /// Prepares the system to run tasks.
  Future<void> performPreflightTasks();
}

/// A proxy for one specific device.
abstract class Device {
  /// A unique device identifier.
  String get deviceId;

  /// Whether the device is awake.
  Future<bool> isAwake();

  /// Whether the device is asleep.
  Future<bool> isAsleep();

  /// Wake up the device if it is not awake.
  Future<void> wakeUp();

  /// Send the device to sleep mode.
  Future<void> sendToSleep();

  /// Emulates pressing the power button, toggling the device's on/off state.
  Future<void> togglePower();

  /// Turns off TalkBack on Android devices, does nothing on iOS devices.
  Future<void> disableAccessibility();

  /// Unlocks the device.
  ///
  /// Assumes the device doesn't have a secure unlock pattern.
  Future<void> unlock();
}

class AndroidDeviceDiscovery implements DeviceDiscovery {
  factory AndroidDeviceDiscovery() {
    return _instance ??= AndroidDeviceDiscovery._();
  }
  AndroidDeviceDiscovery._();

  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = RegExp(r'^(\S+)\s+(\S+)(.*)');

  static AndroidDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices() async {
    List<String> output =
        (await eval(config.adbPath, ['devices', '-l'], canFail: false))
            .trim()
            .split('\n');
    List<String> results = <String>[];
    for (String line in output) {
      // Skip lines like: * daemon started successfully *
      if (line.startsWith('* daemon ')) continue;

      if (line.startsWith('List of devices')) continue;

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

    return results.map((String id) => AndroidDevice(deviceId: id)).toList();
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (AndroidDevice device in await discoverDevices()) {
      try {
        // Just a smoke test that we can read wakefulness state
        // TODO(yjbanov): check battery level
        await device._getWakefulness();
        results['android-device-${device.deviceId}'] =
            HealthCheckResult.success();
      } catch (e, s) {
        results['android-device-${device.deviceId}'] =
            HealthCheckResult.error(e, s);
      }
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Kills the `adb` server causing it to start a new instance upon next
    // command.
    //
    // Restarting `adb` helps with keeping device connections alive. When `adb`
    // runs non-stop for too long it loses connections to devices. There may be
    // a better method, but so far that's the best one I've found.
    await exec(config.adbPath, <String>['kill-server'], canFail: false);

    // Immediately after killing the `adb` server, the server may deny connections.
    // So we wait until first successful `adb devices -l`.
    int retry = 0;
    bool adbOk = false;
    do {
      retry++;
      await Future<void>.delayed(const Duration(seconds: 1));
      adbOk = await exec(config.adbPath, <String>['devices', '-l'],
              canFail: true) ==
          0;
    } while (!adbOk && retry < 3);
  }
}

class AndroidDevice implements Device {
  AndroidDevice({@required this.deviceId});

  @override
  final String deviceId;

  /// Whether the device is awake.
  @override
  Future<bool> isAwake() async {
    return await _getWakefulness() == 'Awake';
  }

  /// Whether the device is asleep.
  @override
  Future<bool> isAsleep() async {
    return await _getWakefulness() == 'Asleep';
  }

  /// Wake up the device if it is not awake using [togglePower].
  @override
  Future<void> wakeUp() async {
    if (!(await isAwake())) await togglePower();
  }

  /// Send the device to sleep mode if it is not asleep using [togglePower].
  @override
  Future<void> sendToSleep() async {
    if (!(await isAsleep())) await togglePower();
  }

  /// Sends `KEYCODE_POWER` (26), which causes the device to toggle its mode
  /// between awake and asleep.
  @override
  Future<void> togglePower() async {
    await shellExec('input', const ['keyevent', '26']);
  }

  /// Unlocks the device by sending `KEYCODE_MENU` (82).
  ///
  /// This only works when the device doesn't have a secure unlock pattern.
  @override
  Future<void> unlock() async {
    await wakeUp();
    await shellExec('input', const ['keyevent', '82']);
  }

  @override
  Future<void> disableAccessibility() async {
    await shellExec('settings',
        ['put', 'secure', 'enabled_accessibility_services', 'null']);
  }

  /// Retrieves device's wakefulness state.
  ///
  /// See: https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/PowerManagerInternal.java
  Future<String> _getWakefulness() async {
    String powerInfo = await shellEval('dumpsys', ['power']);
    String wakefulness =
        grep('mWakefulness=', from: powerInfo).single.split('=')[1].trim();
    return wakefulness;
  }

  /// Executes [command] on `adb shell` and returns its exit code.
  Future<void> shellExec(String command, List<String> arguments,
      {Map<String, String> env}) async {
    await exec(config.adbPath, ['shell', command]..addAll(arguments),
        env: env, canFail: false);
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments,
      {Map<String, String> env}) {
    return eval(config.adbPath, ['shell', command]..addAll(arguments),
        env: env, canFail: false);
  }
}

class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery() {
    return _instance ??= IosDeviceDiscovery._();
  }

  IosDeviceDiscovery._();

  static IosDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices() async {
    List<String> iosDeviceIds =
        LineSplitter.split(await eval('idevice_id', ['-l']));
    if (iosDeviceIds.isEmpty) throw 'No connected iOS devices found.';
    return iosDeviceIds
        .map((String id) => IosDevice(deviceId: id))
        .toList();
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (Device device in await discoverDevices()) {
      // TODO: do a more meaningful connectivity check than just recording the ID
      results['ios-device-${device.deviceId}'] =
          HealthCheckResult.success();
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Currently we do not have preflight tasks for iOS.
    return null;
  }
}

/// iOS device.
class IosDevice implements Device {
  const IosDevice({@required this.deviceId});

  @override
  final String deviceId;

  // The methods below are stubs for now. They will need to be expanded.
  // We currently do not have a way to lock/unlock iOS devices. So we assume the
  // devices are already unlocked. For now we'll just keep them at minimum
  // screen brightness so they don't drain battery too fast.

  @override
  Future<bool> isAwake() async => true;

  @override
  Future<bool> isAsleep() async => false;

  @override
  Future<void> wakeUp() async {}

  @override
  Future<void> sendToSleep() async {}

  @override
  Future<void> togglePower() async {}

  @override
  Future<void> unlock() async {}

  @override
  Future<void> disableAccessibility() async {}
}
