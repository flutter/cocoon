// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/android_device.dart';

import 'utils.dart';

void main() {
  group('AndroidDeviceDiscovery', () {
    AndroidDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    List<List<int>> output;
    Process process;

    setUp(() {
      deviceDiscovery = AndroidDeviceDiscovery();
      processManager = MockProcessManager();
    });

    test('deviceDiscovery no retries', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = new StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);

      List<Device> devices = await deviceDiscovery.discoverDevices(
          retryDuration: const Duration(seconds: 0), processManager: processManager);
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('ZY223JQNMR'));
    });

    test('deviceDiscovery fails', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => throw TimeoutException('test'));
      expect(deviceDiscovery.discoverDevices(retryDuration: const Duration(seconds: 0), processManager: processManager),
          throwsA(TypeMatcher<TimeoutException>()));
    });
  });

  group('AndroidDeviceProperties', () {
    AndroidDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process device_os_flavor_process;
    Process device_os_process;
    Process device_os_type_process;
    Process device_type_model_process;
    Process device_type_board_process;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery = AndroidDeviceDiscovery();
      processManager = MockProcessManager();
    });

    test('returns empty when no device is attached', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      
      StringBuffer sb = new StringBuffer();
      sb.writeln('List of devices attached');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);

      expect(await deviceDiscovery.checkDeviceProperties(processManager: processManager),
          equals(<String, List<String>>{}));
    });

    test('get device properties', () async {
      when(processManager.start(<dynamic>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop', 'ro.product.brand'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(device_os_flavor_process));
      when(processManager.start(<dynamic>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop', 'ro.build.id'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(device_os_process));
      when(processManager.start(<dynamic>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop', 'ro.build.type'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(device_os_type_process));
      when(processManager.start(<dynamic>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop', 'ro.product.model'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(device_type_model_process));
      when(processManager.start(<dynamic>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop', 'ro.product.board'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(device_type_board_process));

      device_os_flavor_process = FakeProcess(0, out: <List<int>>[utf8.encode('motorola')]);
      device_os_process = FakeProcess(0, out: <List<int>>[utf8.encode('NPJS25.93-14-18')]);
      device_os_type_process = FakeProcess(0, out: <List<int>>[utf8.encode('user')]);
      device_type_model_process = FakeProcess(0, out: <List<int>>[utf8.encode('Moto G (4)')]);
      device_type_board_process = FakeProcess(0, out: <List<int>>[utf8.encode('msm8952')]);

      Map<String, List<String>> deviceProperties = await deviceDiscovery
          .getDeviceProperties(AndroidDevice(deviceId: 'ZY223JQNMR'), processManager: processManager);

      const Map<String, List<String>> expectedProperties = <String, List<String>>{
        'device_os_flavor': <String>['motorola'],
        'device_os': <String>['N', 'NPJS25.93-14-18'],
        'device_os_type': <String>['user'],
        'device_type': <String>['Moto G (4)', 'msm8952']
      };
      expect(deviceProperties, equals(expectedProperties));
    });
  });
}
