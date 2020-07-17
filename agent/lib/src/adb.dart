// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter;
import 'dart:io';

import 'package:meta/meta.dart';

import 'utils.dart';

/// The root of the API for controlling devices.
DeviceDiscovery get devices => DeviceDiscovery();

/// Operating system on the devices that this agent is configured to test.
enum HostType { vm, physical }

/// Operating system on the devices that this agent is configured to test.
enum DeviceOperatingSystem { android, ios, none }

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery() {
    switch (config.deviceOperatingSystem) {
      case DeviceOperatingSystem.android:
        return AndroidDeviceDiscovery();
      case DeviceOperatingSystem.ios:
        return IosDeviceDiscovery();
      case DeviceOperatingSystem.none:
        return NoOpDeviceDiscovery();
      default:
        throw StateError('Unsupported device operating system: {config.deviceOperatingSystem}');
    }
  }

  /// Lists all available devices' IDs.
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000});

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

/// Constant battery health values returned from Android Battery Manager.
///
/// https://developer.android.com/reference/android/os/BatteryManager.html
class AndroidBatteryHealth {
  // Match SCREAMING_CAPS to Android constants.
  static const BATTERY_HEALTH_UNKNOWN = 1;
  static const BATTERY_HEALTH_GOOD = 2;
  static const BATTERY_HEALTH_OVERHEAT = 3;
  static const BATTERY_HEALTH_DEAD = 4;
  static const BATTERY_HEALTH_OVER_VOLTAGE = 5;
  static const BATTERY_HEALTH_UNSPECIFIED_FAILURE = 6;
  static const BATTERY_HEALTH_COLD = 7;
}

class AndroidDeviceDiscovery implements DeviceDiscovery {
  factory AndroidDeviceDiscovery() {
    return _instance ??= AndroidDeviceDiscovery._();
  }
  AndroidDeviceDiscovery._();

  @visibleForTesting
  AndroidDeviceDiscovery.testing();

  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = RegExp(r'^(\S+)\s+(\S+)(.*)');

  static AndroidDeviceDiscovery _instance;

  Future<String> deviceListOutput() async {
    return eval(config.adbPath, <String>['devices', '-l'], canFail: false).timeout(Duration(seconds: 15));
  }

  Future<List<String>> deviceListOutputWithRetries(int retriesDelayMs) async {
    int retry = 0;
    while (true) {
      try {
        String result = await deviceListOutput();
        return result.trim().split('\n');
      } on TimeoutException {
        retry++;
        if (retry >= 3) {
          throw new TimeoutException('Can not get devices data');
        }
        killAdbServer();
        await Future<void>.delayed(Duration(milliseconds: retriesDelayMs));
      }
    }
  }

  void killAdbServer() async {
    if (Platform.isWindows) {
      await killAllRunningProcessesOnWindows('adb');
    } else {
      await exec(config.adbPath, <String>['kill-server'], canFail: false);
    }
  }

  @override
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000}) async {
    List<String> output = await deviceListOutputWithRetries(retriesDelayMs);
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
    for (Device device in await discoverDevices()) {
      final String deviceResultKey = 'android-device-${device.deviceId}';
      if (device is AndroidDevice) {
        try {
          // Just a smoke test that we can read wakefulness state
          await device._getWakefulness();
          results[deviceResultKey] = await device.batteryHealth();
        } catch (e, s) {
          results[deviceResultKey] = HealthCheckResult.error(e, s);
        }
      }
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Checks required for the agent to start.
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
    await shellExec('settings', ['put', 'secure', 'enabled_accessibility_services', 'null']);
  }

  /// Retrieves device's wakefulness state.
  ///
  /// See: https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/PowerManagerInternal.java
  Future<String> _getWakefulness() async {
    String powerInfo = await shellEval('dumpsys', ['power']);
    String wakefulness = grep('mWakefulness=', from: powerInfo).single.split('=')[1].trim();
    return wakefulness;
  }

  /// Retrieves battery health reported from dumpsys battery.
  Future<HealthCheckResult> batteryHealth() async {
    try {
      String batteryInfo = await shellEval('dumpsys', ['battery']);
      String batteryTemperatureString = grep('health: ', from: batteryInfo).single.split(': ')[1].trim();
      int batteryHeath = int.parse(batteryTemperatureString);
      switch (batteryHeath) {
        case AndroidBatteryHealth.BATTERY_HEALTH_OVERHEAT:
          return HealthCheckResult.failure('Battery overheated');
        case AndroidBatteryHealth.BATTERY_HEALTH_DEAD:
          return HealthCheckResult.failure('Battery dead');
        case AndroidBatteryHealth.BATTERY_HEALTH_OVER_VOLTAGE:
          return HealthCheckResult.failure('Battery over voltage');
        case AndroidBatteryHealth.BATTERY_HEALTH_UNSPECIFIED_FAILURE:
          return HealthCheckResult.failure('Unspecified battery failure');
        case AndroidBatteryHealth.BATTERY_HEALTH_COLD:
          return HealthCheckResult.failure('Battery cold');
        case AndroidBatteryHealth.BATTERY_HEALTH_UNKNOWN:
          return HealthCheckResult.success('Battery health unknown');
        case AndroidBatteryHealth.BATTERY_HEALTH_GOOD:
          return HealthCheckResult.success();
        default:
          // Unknown code.
          return HealthCheckResult.success('Unknown battery health value $batteryHeath');
      }
    } catch (e) {
      // dumpsys battery not supported.
      return HealthCheckResult.success('Unknown battery health');
    }
  }

  /// Executes [command] on `adb shell` and returns its exit code.
  Future<void> shellExec(String command, List<String> arguments, {Map<String, String> env}) async {
    await exec(config.adbPath, ['shell', command]..addAll(arguments), env: env, canFail: false);
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) {
    return eval(config.adbPath, ['shell', command]..addAll(arguments), env: env, canFail: false);
  }
}

class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery() {
    return _instance ??= IosDeviceDiscovery._();
  }

  IosDeviceDiscovery._();

  static IosDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000}) async {
    List<String> iosDeviceIds = LineSplitter.split(await eval('idevice_id', ['-l'])).toList();
    if (iosDeviceIds.isEmpty) throw 'No connected iOS devices found.';
    return iosDeviceIds.map((String id) => IosDevice(deviceId: id)).toList();
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (Device device in await discoverDevices()) {
      // TODO: do a more meaningful connectivity check than just recording the ID
      results['ios-device-${device.deviceId}'] = HealthCheckResult.success();
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Currently we do not have preflight tasks for iOS.
    return null;
  }
}

class NoOpDeviceDiscovery implements DeviceDiscovery {
  factory NoOpDeviceDiscovery() {
    return _instance ??= NoOpDeviceDiscovery._();
  }

  NoOpDeviceDiscovery._();

  static NoOpDeviceDiscovery _instance;

  @override
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000}) async {
    return [];
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    results['no-device'] = HealthCheckResult.success();
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Currently we do not have preflight tasks for hosts without attached devices.
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
