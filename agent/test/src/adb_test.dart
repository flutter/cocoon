// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:collection/collection.dart';

import 'package:cocoon_agent/src/adb.dart';

void main() {
  group('device', () {
    Device device;

    setUp(() {
      FakeDevice.resetLog();
      device = null;
      device = new FakeDevice();
    });

    tearDown(() {
    });

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
  });
}

void expectLog(List<CommandArgs> log) {
  expect(FakeDevice.commandLog, log);
}

CommandArgs cmd({String command, List<String> arguments, Map<String, String> env}) => new CommandArgs(
  command: command,
  arguments: arguments,
  env: env
);

typedef dynamic ExitErrorFactory();

class CommandArgs {
  CommandArgs({this.command, this.arguments, this.env});

  final String command;
  final List<String> arguments;
  final Map<String, String> env;

  @override
  String toString() => 'CommandArgs(command: $command, arguments: $arguments, env: $env)';

  @override
  bool operator==(Object other) {
    if (other.runtimeType != CommandArgs)
      return false;

    CommandArgs otherCmd = other;
    return otherCmd.command == this.command &&
      const ListEquality().equals(otherCmd.arguments, this.arguments) &&
      const MapEquality().equals(otherCmd.env, this.env);
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnv;

  int get _hashArguments => arguments != null
    ? const ListEquality().hash(arguments)
    : null.hashCode;

  int get _hashEnv => env != null
    ? const MapEquality().hash(env)
    : null.hashCode;
}

class FakeDevice extends AndroidDevice {
  FakeDevice({String deviceId: null}) : super(deviceId: deviceId);

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

  @override
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) async {
    commandLog.add(new CommandArgs(
      command: command,
      arguments: arguments,
      env: env
    ));
    return output;
  }

  @override
  Future<Null> shellExec(String command, List<String> arguments, {Map<String, String> env}) async {
    commandLog.add(new CommandArgs(
      command: command,
      arguments: arguments,
      env: env
    ));
    dynamic exitError = exitErrorFactory();
    if (exitError != null)
      throw exitError;
  }
}
