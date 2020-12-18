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
}
