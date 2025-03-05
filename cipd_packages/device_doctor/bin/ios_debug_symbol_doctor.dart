// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is not a part of the main Device Doctor because it depends on Xcode
// being installed and set up in the environment, while the main iOS Device
// Doctor workflow runs before Xcode is provisioned.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:device_doctor/device_doctor.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  // Write logs to stdout
  Logger.root.onRecord.listen((LogRecord record) {
    stdout.writeln(record.toString());
  });

  final runner = CommandRunner<bool>(
    'ios-debug-symbol-doctor',
    'Tool for diagnosing and recovering from iOS debug symbols not synched with the host by Xcode',
  )
    ..addCommand(DiagnoseCommand())
    ..addCommand(RecoverCommand());

  final success = await runner.run(args);
  exit(success == true ? 0 : 1);
}
