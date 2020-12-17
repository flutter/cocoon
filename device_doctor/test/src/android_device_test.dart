// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';

import 'package:device_doctor/src/android_device.dart';
import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/health.dart';

import 'fake_android_device.dart';

void main() {
  group('AndroidDeviceDiscovery', () {
    FakeAndroidDeviceDiscovery deviceDiscovery;

    setUp(() {
      deviceDiscovery = FakeAndroidDeviceDiscovery();
    });

    test('deviceDiscovery no retries', () async {
      deviceDiscovery.outputs = <dynamic>['List of devices attached'];
      expect(await deviceDiscovery.discoverDevices(), isEmpty);
      StringBuffer sb = new StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      deviceDiscovery.outputs = <dynamic>[sb.toString()];
      List<Device> devices = await deviceDiscovery.discoverDevices();
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('ZY223JQNMR'));
    });

    test('deviceDiscovery retries', () async {
      StringBuffer sb = new StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      deviceDiscovery.outputs = <dynamic>[new TimeoutException('a'), new TimeoutException('b'), sb.toString()];
      List<Device> devices = await deviceDiscovery.discoverDevices(retriesDelaySeconds: const Duration(seconds: 1));
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('ZY223JQNMR'));
    });

    test('deviceDiscovery fails', () async {
      deviceDiscovery.outputs = <dynamic>[
        new TimeoutException('a'),
        new TimeoutException('b'),
        new TimeoutException('c')
      ];
      expect(() => deviceDiscovery.discoverDevices(retriesDelaySeconds: const Duration(seconds: 1)),
          throwsA(TypeMatcher<TimeoutException>()));
    });
  });

  group('Android device', () {
    AndroidDevice device;

    setUp(() {
      FakeDevice.resetLog();
      device = null;
      device = FakeDevice();
    });

    tearDown(() {});

    group('isAwake/isAsleep', () {
      test('reads Awake', () async {
        FakeDevice.pretendAwake();
        expect(await device.isAwake(), isTrue);
        expect(await device.isAsleep(), isFalse);
      });

      test('reads Asleep', () async {
        FakeDevice.pretendAsleep();
        expect(await device.isAwake(), isFalse);
        expect(await device.isAsleep(), isTrue);
      });
    });

    group('battery health', () {
      test('battery health unknown', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_UNKNOWN);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isTrue);
        expect(batteryHealth.details, contains('unknown'));
      });

      test('battery health good', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_GOOD);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isTrue);
        expect(batteryHealth.details, isNull);
      });

      test('battery overheated', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_OVERHEAT);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isFalse);
        expect(batteryHealth.details, contains('overheat'));
      });

      test('battery dead', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_DEAD);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isFalse);
        expect(batteryHealth.details, contains('dead'));
      });

      test('battery over voltage', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_OVER_VOLTAGE);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isFalse);
        expect(batteryHealth.details, contains('over voltage'));
      });

      test('battery health unspecified failure', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_UNSPECIFIED_FAILURE);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isFalse);
        expect(batteryHealth.details, contains('Unspecified'));
      });

      test('battery cold', () async {
        FakeDevice.pretendBatteryHealth(AndroidBatteryHealth.BATTERY_HEALTH_COLD);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isFalse);
        expect(batteryHealth.details, contains('cold'));
      });

      test('battery health value not recognized', () async {
        FakeDevice.pretendBatteryHealth(42);
        final HealthCheckResult batteryHealth = await device.batteryHealth();
        expect(batteryHealth.succeeded, isTrue);
        expect(batteryHealth.details, contains('42'));
      });
    });
  });
}
