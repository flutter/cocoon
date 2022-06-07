// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:process/process.dart';
import 'package:logging/logging.dart';

class DiagnoseCommand extends Command<bool> {
  DiagnoseCommand({
    this.processManager = const LocalProcessManager(),
    Logger? loggerOverride,
  }) : logger = loggerOverride ?? Logger.root;

  final Logger logger;

  final ProcessManager processManager;

  final String name = 'diagnose';
  final String description = 'Diagnose whether attached iOS devices have errors.';

  Future<bool> run() async {
    logger.info('Hi!');
    logger.info('Hi!');
    throw 'foo';
  }
}
