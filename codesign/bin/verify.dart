// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:codesign/verify.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  final Logger logger = Logger('root');
  logger.onRecord.listen((LogRecord record) {
    io.stdout.writeln(record.message);
  });
  final argResults = _parseArgs(args, logger);
  final VerificationResult result = await VerificationService(
    binaryPath: argResults['input-file'],
    logger: logger,
  ).run();
  io.exit(result == VerificationResult.codesignedAndNotarized ? 0 : 1);
}

ArgResults _parseArgs(List<String> args, Logger logger) {
  final parser = ArgParser()
    ..addOption(
      'input-file',
      abbr: 'i',
      mandatory: true,
      help:
          'The input binary file whose code signature and notarization status '
          'will be verified.',
      valueHelp: 'path to binary file',
    );
  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (exception) {
    logger.severe(exception);
    logger.info(parser.usage);
    io.exit(1);
  }
  return results;
}
