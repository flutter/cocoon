// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:codesign/verify.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  final logger = Logger('root');
  logger.onRecord.listen((LogRecord record) {
    io.stdout.writeln(record.message);
  });
  if (args.length != 1) {
    logger.info('Usage: dart verify.dart [FILE]');
    io.exit(1);
  }
  if (!io.Platform.isMacOS) {
    logger.severe('This tool must be run from macOS.');
    io.exit(1);
  }
  final inputFile = args[0];
  final result =
      await VerificationService(binaryPath: inputFile, logger: logger).run();
  io.exit(result == VerificationResult.codesignedAndNotarized ? 0 : 1);
}
