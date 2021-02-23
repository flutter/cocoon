// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:retry/retry.dart';

import 'device.dart';
import 'health.dart';
import 'host_utils.dart';
import 'mac.dart';
import 'utils.dart';

class AndroidDeviceDiscovery implements DeviceDiscovery {
  factory AndroidDeviceDiscovery(String output) {
    return _instance ??= AndroidDeviceDiscovery._(output);
  }

  final String _outputFilePath;
  AndroidDeviceDiscovery._(this._outputFilePath);

  @visibleForTesting
  AndroidDeviceDiscovery.testing(this._outputFilePath);

  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = RegExp(r'^(\S+)\s+(\S+)(.*)');

  static AndroidDeviceDiscovery _instance;

  Future<String> _deviceListOutput(Duration timeout, {ProcessManager processManager}) async {
    return eval('adb', <String>['devices', '-l'], canFail: false, processManager: processManager).timeout(timeout);
  }

  Future<List<String>> _deviceListOutputWithRetries(Duration retryDuration, {ProcessManager processManager}) async {
    const Duration deviceOutputTimeout = Duration(seconds: 15);
    RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: retryDuration,
    );
    return await r.retry(
      () async {
        String result = await _deviceListOutput(deviceOutputTimeout, processManager: processManager);
        return result.trim().split('\n');
      },
      retryIf: (Exception e) => e is TimeoutException,
      onRetry: (Exception e) => _killAdbServer(processManager: processManager),
    );
  }

  void _killAdbServer({ProcessManager processManager}) async {
    if (Platform.isWindows) {
      await killAllRunningProcessesOnWindows('adb', processManager: processManager);
    } else {
      await eval('adb', <String>['kill-server'], canFail: false, processManager: processManager);
    }
  }

  @override
  Future<List<AndroidDevice>> discoverDevices(
      {Duration retryDuration = const Duration(seconds: 10), ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    List<String> output = await _deviceListOutputWithRetries(retryDuration, processManager: processManager);
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
  Future<Map<String, List<HealthCheckResult>>> checkDevices({ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (AndroidDevice device in await discoverDevices(processManager: processManager)) {
      final List<HealthCheckResult> checks = <HealthCheckResult>[];
      checks.add(HealthCheckResult.success('device_access'));
      checks.add(await adbPowerServiceCheck(processManager: processManager));
      checks.add(await developerModeCheck(processManager: processManager));
      if (Platform.isMacOS) {
        checks.add(await userAutoLoginCheck(processManager: processManager));
      }
      results['android-device-${device.deviceId}'] = checks;
    }
    final Map<String, Map<String, dynamic>> healthCheckMap = await healthcheck(results);
    await writeToFile(json.encode(healthCheckMap), _outputFilePath);
    return results;
  }

  /// Checks and returns the device properties, like manufacturer, base_buildid, etc.
  ///
  /// It supports multiple devices, but here we are assuming only one device is attached.
  @override
  Future<Map<String, String>> deviceProperties({ProcessManager processManager}) async {
    final List<AndroidDevice> devices = await discoverDevices(processManager: processManager);
    Map<String, String> properties = <String, String>{};
    if (devices.isEmpty) {
      await writeToFile(json.encode(properties), _outputFilePath);
      return properties;
    }
    properties = await getDeviceProperties(devices[0], processManager: processManager);
    final String propertiesJson = json.encode(properties);

    await writeToFile(propertiesJson, _outputFilePath);
    stdout.write(propertiesJson);
    return properties;
  }

  /// Gets android device properties based on swarming bot configuration.
  ///
  /// Refer function `get_dimensions` from
  /// https://source.chromium.org/chromium/infra/infra/+/master:luci/appengine/swarming/swarming_bot/api/platforms/android.py
  Future<Map<String, String>> getDeviceProperties(AndroidDevice device, {ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    final Map<String, String> deviceProperties = <String, String>{};
    final Map<String, String> propertyMap = <String, String>{};
    LineSplitter.split(
            await eval('adb', <String>['-s', device.deviceId, 'shell', 'getprop'], processManager: processManager))
        .forEach((String property) {
      final List<String> propertyList = property.replaceAll('[', '').replaceAll(']', '').split(': ');
      propertyMap[propertyList[0].trim()] = propertyList[1].trim();
    });

    deviceProperties['product_brand'] = propertyMap['ro.product.brand'];
    deviceProperties['build_id'] = propertyMap['ro.build.id'];
    deviceProperties['build_type'] = propertyMap['ro.build.type'];
    deviceProperties['product_model'] = propertyMap['ro.product.model'];
    deviceProperties['product_board'] = propertyMap['ro.product.board'];
    return deviceProperties;
  }

  @override
  Future<void> recoverDevices() async {
    for (Device device in await discoverDevices()) {
      await device.recover();
    }
  }

  @visibleForTesting
  Future<HealthCheckResult> adbPowerServiceCheck({ProcessManager processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      await eval('adb', <String>['shell', 'dumpsys', 'power'], processManager: processManager);
      healthCheckResult = HealthCheckResult.success(kAdbPowerServiceCheckKey);
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kAdbPowerServiceCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting

  /// The health check for Android device developer mode.
  ///
  /// Developer mode `on` is expected for a healthy Android device.
  Future<HealthCheckResult> developerModeCheck({ProcessManager processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String result = await eval(
          'adb', <String>['shell', 'settings', 'get', 'global', 'development_settings_enabled'],
          processManager: processManager);
      // The output of `development_settings_enabled` is `1` when developer mode is on.
      if (result == '1') {
        healthCheckResult = HealthCheckResult.success(kDeveloperModeCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(kDeveloperModeCheckKey, 'developer mode is off');
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kDeveloperModeCheckKey, error.toString());
    }
    return healthCheckResult;
  }
}

class AndroidDevice implements Device {
  AndroidDevice({@required this.deviceId});

  @override
  final String deviceId;

  @override
  Future<void> recover() async {
    await eval('adb', <String>['-s', deviceId, 'reboot'], canFail: false);
  }
}
