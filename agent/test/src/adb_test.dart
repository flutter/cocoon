// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:collection/collection.dart';

import 'package:cocoon_agent/src/adb.dart';
import 'package:cocoon_agent/src/utils.dart';

void main() {
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

    group('togglePower', () {
      test('sends power event', () async {
        await device.togglePower();
        expectLog([
          cmd(command: 'input', arguments: ['keyevent', '26']),
        ]);
      });
    });

    group('wakeUp', () {
      test('when awake', () async {
        FakeDevice.pretendAwake();
        await device.wakeUp();
        expectLog([
          cmd(command: 'dumpsys', arguments: ['power']),
        ]);
      });

      test('when asleep', () async {
        FakeDevice.pretendAsleep();
        await device.wakeUp();
        expectLog([
          cmd(command: 'dumpsys', arguments: ['power']),
          cmd(command: 'input', arguments: ['keyevent', '26']),
        ]);
      });
    });

    group('sendToSleep', () {
      test('when asleep', () async {
        FakeDevice.pretendAsleep();
        await device.sendToSleep();
        expectLog([
          cmd(command: 'dumpsys', arguments: ['power']),
        ]);
      });

      test('when awake', () async {
        FakeDevice.pretendAwake();
        await device.sendToSleep();
        expectLog([
          cmd(command: 'dumpsys', arguments: ['power']),
          cmd(command: 'input', arguments: ['keyevent', '26']),
        ]);
      });
    });

    group('unlock', () {
      test('sends unlock event', () async {
        FakeDevice.pretendAwake();
        await device.unlock();
        expectLog([
          cmd(command: 'dumpsys', arguments: ['power']),
          cmd(command: 'input', arguments: ['keyevent', '82']),
        ]);
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

void expectLog(List<CommandArgs> log) {
  expect(FakeDevice.commandLog, log);
}

CommandArgs cmd(
        {String command, List<String> arguments, Map<String, String> env}) =>
    CommandArgs(command: command, arguments: arguments, env: env);

typedef dynamic ExitErrorFactory();

class CommandArgs {
  CommandArgs({this.command, this.arguments, this.env});

  final String command;
  final List<String> arguments;
  final Map<String, String> env;

  @override
  String toString() =>
      'CommandArgs(command: $command, arguments: $arguments, env: $env)';

  @override
  bool operator ==(Object other) {
    if (other is CommandArgs) {
      return other.command == this.command
        && const ListEquality<String>().equals(other.arguments, this.arguments)
        && const MapEquality<String, String>().equals(other.env, this.env);
    }
    return false;
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnv;

  int get _hashArguments =>
      arguments != null ? const ListEquality<String>().hash(arguments) : null.hashCode;

  int get _hashEnv =>
      env != null ? const MapEquality<String, String>().hash(env) : null.hashCode;
}

class FakeDevice extends AndroidDevice {
  FakeDevice({String deviceId}) : super(deviceId: deviceId);

  static String output = '';
  static ExitErrorFactory exitErrorFactory = () => null;

  static List<CommandArgs> commandLog = <CommandArgs>[];

  static void resetLog() {
    commandLog.clear();
  }

  static void pretendAwake() {
    output = '''
      mWakefulness=Awake
    ''';
  }

  static void pretendAsleep() {
    output = '''
      mWakefulness=Asleep
    ''';
  }

  static void pretendBatteryHealth(int batteryHealth) {
    output = '''
  health: $batteryHealth
    ''';
  }

  @override
  Future<String> shellEval(String command, List<String> arguments,
      {Map<String, String> env}) async {
    commandLog
        .add(CommandArgs(command: command, arguments: arguments, env: env));
    return output;
  }

  @override
  Future<Null> shellExec(String command, List<String> arguments,
      {Map<String, String> env}) async {
    commandLog
        .add(CommandArgs(command: command, arguments: arguments, env: env));
    dynamic exitError = exitErrorFactory();
    if (exitError != null) throw exitError;
  }
}
