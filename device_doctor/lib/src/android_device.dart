// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import 'device.dart';
import 'process_helper.dart';
import 'health.dart';
import 'utils.dart';

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
    return eval(properties['adb'], <String>['devices', '-l'], canFail: false).timeout(Duration(seconds: 15));
  }

  Future<List<String>> deviceListOutputWithRetries(Duration retriesDelayMs) async {
    RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: retriesDelayMs,
    );
    return await r.retry(
      () async {
        String result = await deviceListOutput();
        return result.trim().split('\n');
      },
      retryIf: (Exception e) => e is TimeoutException,
      //onRetry: (Exception e) => killAdbServer(),
    );
  }

  void killAdbServer() async {
    if (Platform.isWindows) {
      await killAllRunningProcessesOnWindows('adb');
    } else {
      await eval(properties['adb'], <String>['kill-server'], canFail: false);
    }
  }

  @override
  Future<List<Device>> discoverDevices({Duration retriesDelayMs = const Duration(seconds: 10)}) async {
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
  Future<Map<String, List<HealthCheckResult>>> checkDevices() async {
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (AndroidDevice device in await discoverDevices()) {
      final List<HealthCheckResult> checks = <HealthCheckResult>[];
      checks.add(HealthCheckResult.success('device_access'));
      HealthCheckResult check;
      try {
        // Just a smoke test that we can read wakefulness state
        await device._getWakefulness();
        check = await device.batteryHealth();
      } catch (e, s) {
        check = HealthCheckResult.error('battery_health', e, s);
      }
      checks.add(check);
      results['android-device-${device.deviceId}'] = checks;
    }
    return results;
  }

  @override
  Future<void> recoverDevices() async {
    for (Device device in await discoverDevices()) {
      await device.recover();
    }
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

  @override
  Future<void> recover() async {
    await eval(properties['adb'], <String>['reboot'], canFail: false);
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
      const String batteryHealthName = 'battery_health';
      String batteryInfo = await shellEval('dumpsys', ['battery']);
      String batteryTemperatureString = grep('health: ', from: batteryInfo).single.split(': ')[1].trim();
      int batteryHeath = int.parse(batteryTemperatureString);
      switch (batteryHeath) {
        case AndroidBatteryHealth.BATTERY_HEALTH_OVERHEAT:
          return HealthCheckResult.failure(batteryHealthName, 'Battery overheated');
        case AndroidBatteryHealth.BATTERY_HEALTH_DEAD:
          return HealthCheckResult.failure(batteryHealthName, 'Battery dead');
        case AndroidBatteryHealth.BATTERY_HEALTH_OVER_VOLTAGE:
          return HealthCheckResult.failure(batteryHealthName, 'Battery over voltage');
        case AndroidBatteryHealth.BATTERY_HEALTH_UNSPECIFIED_FAILURE:
          return HealthCheckResult.failure(batteryHealthName, 'Unspecified battery failure');
        case AndroidBatteryHealth.BATTERY_HEALTH_COLD:
          return HealthCheckResult.failure(batteryHealthName, 'Battery cold');
        case AndroidBatteryHealth.BATTERY_HEALTH_UNKNOWN:
          return HealthCheckResult.success(batteryHealthName, 'Battery health unknown');
        case AndroidBatteryHealth.BATTERY_HEALTH_GOOD:
          return HealthCheckResult.success(batteryHealthName);
        default:
          // Unknown code.
          return HealthCheckResult.success('Unknown', 'Unknown battery health value $batteryHeath');
      }
    } catch (e) {
      // dumpsys battery not supported.
      return HealthCheckResult.success('Unknown', 'Unknown battery health');
    }
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) {
    return eval(properties['adb'], ['shell', command]..addAll(arguments), env: env, canFail: false);
  }
}
