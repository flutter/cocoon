// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';

import 'package:device_doctor/src/android_device.dart';

class FakeAndroidDeviceDiscovery extends AndroidDeviceDiscovery {
  FakeAndroidDeviceDiscovery() : super.testing();

  List<dynamic> _outputs;
  int _pos = 0;

  set outputs(List<dynamic> outputs) {
    _pos = 0;
    _outputs = outputs;
  }

  @override
  Future<String> deviceListOutput(Duration timeout) async {
    _pos++;
    if (_outputs[_pos - 1] is String) {
      return _outputs[_pos - 1] as String;
    } else {
      throw _outputs[_pos - 1];
    }
  }

  @override
  void killAdbServer() async {
    return;
  }
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
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) async {
    commandLog.add(CommandArgs(command: command, arguments: arguments, env: env));
    return output;
  }
}

CommandArgs cmd({String command, List<String> arguments, Map<String, String> env}) =>
    CommandArgs(command: command, arguments: arguments, env: env);

typedef dynamic ExitErrorFactory();

class CommandArgs {
  CommandArgs({this.command, this.arguments, this.env});

  final String command;
  final List<String> arguments;
  final Map<String, String> env;

  @override
  String toString() => 'CommandArgs(command: $command, arguments: $arguments, env: $env)';

  @override
  bool operator ==(Object other) {
    if (other is CommandArgs) {
      return other.command == this.command &&
          const ListEquality<String>().equals(other.arguments, this.arguments) &&
          const MapEquality<String, String>().equals(other.env, this.env);
    }
    return false;
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnv;

  int get _hashArguments => arguments != null ? const ListEquality<String>().hash(arguments) : null.hashCode;

  int get _hashEnv => env != null ? const MapEquality<String, String>().hash(env) : null.hashCode;
}
