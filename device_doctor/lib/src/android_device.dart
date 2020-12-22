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
import 'utils.dart';

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
  Future<Map<String, List<HealthCheckResult>>> checkDevices() async {
    final Map<String, List<HealthCheckResult>> results = <String, List<HealthCheckResult>>{};
    for (AndroidDevice device in await discoverDevices()) {
      final List<HealthCheckResult> checks = <HealthCheckResult>[];
      checks.add(HealthCheckResult.success('device_access'));
      results['android-device-${device.deviceId}'] = checks;
    }
    return results;
  }

  /// Checks and returns the device properties, like manufacturer, base_buildid, etc.
  ///
  /// It supports multiple devices, but here we are assuming only one device is attached.
  @override
  Future<Map<String, List<String>>> checkDeviceProperties() async {
    final List<AndroidDevice> devices = await discoverDevices();
    if (devices.isEmpty) {
      return <String, List<String>>{};
    }
    final Map<String, List<String>> properties = await getDeviceProperties(devices[0]);
    stdout.write(json.encode(properties));
    return properties;
  }

  /// Gets android device properties based on swarming bot configuration.
  ///
  /// Refer function `get_dimensions` from
  /// https://source.chromium.org/chromium/infra/infra/+/master:luci/appengine/swarming/swarming_bot/api/platforms/android.py
  Future<Map<String, List<String>>> getDeviceProperties(AndroidDevice device, {ProcessManager processManager}) async {
    processManager ??= LocalProcessManager();
    final Map<String, List<String>> properties = <String, List<String>>{};
    properties['device_os_flavor'] = <String>[
      await device.shellEval('getprop', <String>['ro.product.brand'], processManager: processManager)
    ];
    final String device_os = await device.shellEval('getprop', <String>['ro.build.id'], processManager: processManager);
    properties['device_os'] = <String>[device_os[0], device_os];
    properties['device_os_type'] = <String>[
      await device.shellEval('getprop', <String>['ro.build.type'], processManager: processManager)
    ];

    properties['device_type'] = <String>[
      await device.shellEval('getprop', <String>['ro.product.model'], processManager: processManager),
      await device.shellEval('getprop', <String>['ro.product.board'], processManager: processManager)
    ];
    return properties;
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

  @override
  Future<void> recover() async {
    await eval('adb', <String>['-s', deviceId, 'reboot'], canFail: false);
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments,
      {Map<String, String> env, ProcessManager processManager}) {
    return eval('adb', ['-s', deviceId, 'shell', command]..addAll(arguments),
        env: env, canFail: false, processManager: processManager);
  }
}
