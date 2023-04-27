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

// The minimum battery level to run a task with a scale of 100%.
const int _kBatteryMinLevel = 15;
// The maximum battery temprature to run a task with a Celsius degree.
const int _kBatteryMaxTemperatureInCelsius = 34;

class AndroidDeviceDiscovery implements DeviceDiscovery {
  factory AndroidDeviceDiscovery(File? output) {
    return _instance ??= AndroidDeviceDiscovery._(output);
  }

  final File? _outputFilePath;
  AndroidDeviceDiscovery._(this._outputFilePath);

  @visibleForTesting
  AndroidDeviceDiscovery.testing(this._outputFilePath);

  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = RegExp(r'^(\S+)\s+(\S+)(.*)');

  static AndroidDeviceDiscovery? _instance;

  Future<String> _deviceListOutput(Duration timeout, {ProcessManager? processManager}) async {
    return eval('adb', <String>['devices', '-l'], canFail: false, processManager: processManager).timeout(timeout);
  }

  Future<List<String>> _deviceListOutputWithRetries(Duration retryDuration, {ProcessManager? processManager}) async {
    const Duration deviceOutputTimeout = Duration(seconds: 15);
    final RetryOptions r = RetryOptions(
      maxAttempts: 3,
      delayFactor: retryDuration,
    );
    return r.retry(
      () async {
        final String result = await _deviceListOutput(deviceOutputTimeout, processManager: processManager);
        return result.trim().split('\n');
      },
      retryIf: (Exception e) => e is TimeoutException,
      onRetry: (Exception e) => _killAdbServer(processManager: processManager),
    );
  }

  void _killAdbServer({ProcessManager? processManager}) async {
    if (Platform.isWindows) {
      await killAllRunningProcessesOnWindows('adb', processManager: processManager);
    } else {
      await eval('adb', <String>['kill-server'], canFail: false, processManager: processManager);
    }
  }

  @override
  Future<List<AndroidDevice>> discoverDevices({
    Duration retryDuration = const Duration(seconds: 10),
    ProcessManager? processManager,
  }) async {
    processManager ??= LocalProcessManager();
    final List<String> output = await _deviceListOutputWithRetries(retryDuration, processManager: processManager);
    final List<String> results = <String>[];
    for (String line in output) {
      // Skip lines like: * daemon started successfully *
      if (line.startsWith('* daemon ')) continue;

      if (line.startsWith('List of devices')) continue;

      if (_kDeviceRegex.hasMatch(line)) {
        final Match? match = _kDeviceRegex.firstMatch(line);

        final String? deviceID = match?[1];
        final String? deviceState = match?[2];

        if (!const ['unauthorized', 'offline'].contains(deviceState)) {
          results.add(deviceID!);
        }
      } else {
        throw 'Failed to parse device from adb output: $line';
      }
    }
    return results.map((String id) => AndroidDevice(deviceId: id)).toList();
  }

  @override
  Future<Map<String, List<HealthCheckResult>>> checkDevices({ProcessManager? processManager}) async {
    processManager ??= LocalProcessManager();
    final List<HealthCheckResult> defaultChecks = <HealthCheckResult>[];
    defaultChecks.add(await killAdbServerCheck(processManager: processManager));
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (AndroidDevice device in await discoverDevices(processManager: processManager)) {
      final List<HealthCheckResult> checks = defaultChecks;
      checks.add(HealthCheckResult.success(kDeviceAccessCheckKey));
      checks.add(await adbPowerServiceCheck(processManager: processManager));
      checks.add(await developerModeCheck(processManager: processManager));
      checks.add(await screenOnCheck(processManager: processManager));
      checks.add(await screenSaverCheck(processManager: processManager));
      checks.add(await screenRotationCheck(processManager: processManager));
      checks.add(await batteryLevelCheck(processManager: processManager));
      checks.add(await batteryTemperatureCheck(processManager: processManager));
      if (Platform.isMacOS) {
        checks.add(await userAutoLoginCheck(processManager: processManager));
      }
      results['android-device-${device.deviceId}'] = checks;
    }
    final Map<String, Map<String, dynamic>> healthCheckMap = await healthcheck(results);
    writeToFile(json.encode(healthCheckMap), _outputFilePath!);
    return results;
  }

  /// Checks and returns the device properties, like manufacturer, base_buildid, etc.
  ///
  /// It supports multiple devices, but here we are assuming only one device is attached.
  @override
  Future<Map<String, String>> deviceProperties({ProcessManager? processManager}) async {
    final List<AndroidDevice> devices = await discoverDevices(processManager: processManager);
    Map<String, String> properties = <String, String>{};
    if (devices.isEmpty) {
      writeToFile(json.encode(properties), _outputFilePath!);
      stdout.writeln('No devices available.');
      return properties;
    }
    properties = await getDeviceProperties(devices[0], processManager: processManager);
    final String propertiesJson = json.encode(properties);

    writeToFile(propertiesJson, _outputFilePath!);
    stdout.writeln('Properties for deviceID ${devices[0].deviceId}: $propertiesJson');
    return properties;
  }

  /// Gets android device properties based on swarming bot configuration.
  ///
  /// Refer function `get_dimensions` from
  /// https://source.chromium.org/chromium/infra/infra/+/master:luci/appengine/swarming/swarming_bot/api/platforms/android.py
  Future<Map<String, String>> getDeviceProperties(AndroidDevice device, {ProcessManager? processManager}) async {
    processManager ??= LocalProcessManager();
    final Map<String, String> deviceProperties = <String, String>{};
    final Map<String, String> propertyMap = <String, String>{};
    LineSplitter.split(
      await eval('adb', <String>['-s', device.deviceId!, 'shell', 'getprop'], processManager: processManager),
    ).forEach((String property) {
      final List<String> propertyList = property.replaceAll('[', '').replaceAll(']', '').split(': ');

      /// Deal with entries spanning only one line.
      ///
      /// This is to skip unused entries spanninning multiple lines.
      /// For example:
      ///   [persist.sys.boot.reason.history]: [reboot,ota,1613677289
      ///   reboot,userrequested,1613677269
      ///   reboot,userrequested,1613508544]
      if (propertyList.length == 2) {
        propertyMap[propertyList[0].trim()] = propertyList[1].trim();
      }
    });

    deviceProperties['product_brand'] = propertyMap['ro.product.brand']!;
    deviceProperties['build_id'] = propertyMap['ro.build.id']!;
    deviceProperties['build_type'] = propertyMap['ro.build.type']!;
    deviceProperties['product_model'] = propertyMap['ro.product.model']!;
    deviceProperties['product_board'] = propertyMap['ro.product.board']!;
    return deviceProperties;
  }

  @override
  Future<void> recoverDevices() async {
    for (Device device in await discoverDevices()) {
      await device.recover();
    }
  }

  @visibleForTesting
  Future<HealthCheckResult> adbPowerServiceCheck({ProcessManager? processManager}) async {
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

  /// The health check for Android device screen on.
  ///
  /// An Android device screen is on when both `mHoldingWakeLockSuspendBlocker` and
  /// `mHoldingDisplaySuspendBlocker` are true.
  Future<HealthCheckResult> screenOnCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String result = await eval(
        'adb',
        <String>['shell', 'dumpsys', 'power', '|', 'grep', 'mHoldingDisplaySuspendBlocker'],
        processManager: processManager,
      );
      if (result.trim() == 'mHoldingDisplaySuspendBlocker=true') {
        healthCheckResult = HealthCheckResult.success(kScreenOnCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(kScreenOnCheckKey, 'screen is off');
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kScreenOnCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting

  /// The health check for Android device adb kill server.
  ///
  /// Kill adb server before running any health check to avoid device quarantine:
  /// https://github.com/flutter/flutter/issues/93075.
  Future<HealthCheckResult> killAdbServerCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      await eval('adb', <String>['kill-server'], processManager: processManager);
      healthCheckResult = HealthCheckResult.success(kKillAdbServerCheckKey);
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kKillAdbServerCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @visibleForTesting

  /// The health check for Android device developer mode.
  ///
  /// Developer mode `on` is expected for a healthy Android device.
  Future<HealthCheckResult> developerModeCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String result = await eval(
        'adb',
        <String>['shell', 'settings', 'get', 'global', 'development_settings_enabled'],
        processManager: processManager,
      );
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

  /// The health check to validate screen rotation is off.
  ///
  /// Screen rotation is expected disabled for a healthy Android device.
  Future<HealthCheckResult> screenRotationCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String result = await eval(
        'adb',
        <String>['shell', 'settings', 'get', 'system', 'accelerometer_rotation'],
        processManager: processManager,
      );
      // The output of `screensaver_enabled` is `0` when screensaver mode is off.
      if (result == '0') {
        healthCheckResult = HealthCheckResult.success(kScreenRotationCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(kScreenRotationCheckKey, 'Screen rotation is enabled');
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kScreenRotationCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  /// The health check to validate screensaver is off.
  ///
  /// Screensaver`off` is expected for a healthy Android device.
  Future<HealthCheckResult> screenSaverCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      final String result = await eval(
        'adb',
        <String>['shell', 'settings', 'get', 'secure', 'screensaver_enabled'],
        processManager: processManager,
      );
      // The output of `screensaver_enabled` is `0` when screensaver mode is off.
      if (result == '0') {
        healthCheckResult = HealthCheckResult.success(kScreenSaverCheckKey);
      } else {
        healthCheckResult = HealthCheckResult.failure(kScreenSaverCheckKey, 'Screensaver is on');
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kScreenSaverCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  /// The health check for battery level.
  Future<HealthCheckResult> batteryLevelCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      // The battery level returns two rows. For example:
      //   level: 100
      //   mod level: -1
      final String levelResults = await eval(
        'adb',
        <String>['shell', 'dumpsys', 'battery', '|', 'grep', 'level'],
        processManager: processManager,
      );
      final RegExp levelRegExp = RegExp('level: (?<level>.+)');
      final RegExpMatch? match = levelRegExp.firstMatch(levelResults);
      final int level = int.parse(match!.namedGroup('level')!);
      if (level < _kBatteryMinLevel) {
        healthCheckResult =
            HealthCheckResult.failure(kBatteryLevelCheckKey, 'Battery level ($level) is below $_kBatteryMinLevel');
      } else {
        healthCheckResult = HealthCheckResult.success(kBatteryLevelCheckKey);
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kScreenSaverCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  /// The health check for battery temperature.
  Future<HealthCheckResult> batteryTemperatureCheck({ProcessManager? processManager}) async {
    HealthCheckResult healthCheckResult;
    try {
      // The battery temperature returns one row. For example:
      //  temperature: 240
      // It means 24°C.
      final String tempResult = await eval(
        'adb',
        <String>['shell', 'dumpsys', 'battery', '|', 'grep', 'temperature'],
        processManager: processManager,
      );
      final RegExp? tempRegExp = RegExp('temperature: (?<temperature>.+)');
      final RegExpMatch match = tempRegExp!.firstMatch(tempResult)!;
      final int temperature = int.parse(match.namedGroup('temperature')!);
      if (temperature > _kBatteryMaxTemperatureInCelsius * 10) {
        healthCheckResult = HealthCheckResult.failure(
          kBatteryTemperatureCheckKey,
          'Battery temperature (${(temperature * 0.1).toInt()}°C) is over $_kBatteryMaxTemperatureInCelsius°C',
        );
      } else {
        healthCheckResult = HealthCheckResult.success(kBatteryTemperatureCheckKey);
      }
    } on BuildFailedError catch (error) {
      healthCheckResult = HealthCheckResult.failure(kBatteryTemperatureCheckKey, error.toString());
    }
    return healthCheckResult;
  }

  @override
  Future<void> prepareDevices() async {
    for (Device device in await discoverDevices()) {
      await device.prepare();
    }
  }
}

class AndroidDevice implements Device {
  AndroidDevice({@required this.deviceId});

  @override
  final String? deviceId;

  @override
  Future<void> recover() async {
    await eval('adb', <String>['-s', deviceId!, 'reboot'], canFail: false);
  }

  @override
  Future<void> prepare() async {
    await killProcesses();
  }

  /// Kill top running process if existing.
  @visibleForTesting
  Future<bool> killProcesses({ProcessManager? processManager}) async {
    processManager ??= LocalProcessManager();
    String result;
    result = await eval(
      'adb',
      <String>['shell', 'dumpsys', 'activity', '|', 'grep', 'top-activity'],
      canFail: true,
      processManager: processManager,
    );

    // Skip uninstalling process when no device is available or no application exists.
    if (result == 'adb: no devices/emulators found' || result.isEmpty) {
      stdout.write('no process is running');
      return true;
    }
    final List<String> results = result.trim().split('\n');
    // Example result:
    //
    // Proc # 0: fore  T/A/T  trm: 0 4544:com.google.android.googlequicksearchbox/u0a66 (top-activity)
    final List<String> processes =
        results.map((result) => result.substring(result.lastIndexOf(':') + 1, result.lastIndexOf('/'))).toList();
    try {
      for (String process in processes) {
        await eval('adb', <String>['shell', 'am', 'force-stop', process], processManager: processManager);
        stdout.write('adb stop process: $process');
      }
    } on BuildFailedError catch (error) {
      stderr.write('uninstall applications fails: $error');
      return false;
    }
    return true;
  }
}
