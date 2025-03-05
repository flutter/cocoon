// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

const String kNotNotarizedMessage =
    'test-requirement: code failed to satisfy specified code requirement(s)';

enum VerificationResult { unsigned, codesignedOnly, codesignedAndNotarized }

class VerificationService {
  VerificationService({
    required this.binaryPath,
    required this.logger,
    this.fs = const LocalFileSystem(),
    this.pm = const LocalProcessManager(),
  }) {
    if (!fs.file(binaryPath).existsSync()) {
      throw Exception(
        'Input file `$binaryPath` does not exist--please provide the path to a '
        'valid binary to verify.',
      );
    }
    if (!pm.canRun('codesign')) {
      throw Exception(
        'The binary `codesign` is required to run this tool. Do you have '
        'Xcode installed?',
      );
    }
  }

  final Logger logger;
  final String binaryPath;
  final FileSystem fs;
  final ProcessManager pm;

  late final String _codesignTimestamp;
  late final String _format;
  late final String _signatureSize;
  late final String _codesignId;
  bool? _notarizationStatus;

  Future<VerificationResult> run() async {
    if (!await _codesignDisplay()) {
      return VerificationResult.unsigned;
    }
    await _notarization();
    logger.info(present());
    return _notarizationStatus!
        ? VerificationResult.codesignedAndNotarized
        : VerificationResult.codesignedOnly;
  }

  Future<void> _notarization() async {
    final command = <String>[
      'codesign',
      '--verify',
      '-v',
      // force online notarization check
      '-R=notarized',
      '--check-notarization',
      binaryPath,
    ];
    final result = await pm.run(command);

    // This usually means it does not satisfy notarization requirement
    if (result.exitCode == 3 &&
        (result.stderr as String).contains(kNotNotarizedMessage)) {
      _notarizationStatus = false;
      return;
    }
    if (result.exitCode != 0) {
      throw Exception('''
Command `${command.join(' ')}` failed with code ${result.exitCode}

${result.stderr}
''');
    }
    final stderr = result.stderr as String;
    if (stderr.contains('explicit requirement satisfied')) {
      _notarizationStatus = true;
      return;
    }
    throw UnimplementedError(
      'Failed parsing the output of `${command.join(' ')}`:\n\n$stderr',
    );
  }

  String present() {
    return '''
Authority:      $_codesignId
Time stamp:     $_codesignTimestamp
Format:         $_format
Signature size: $_signatureSize
Notarization:   $_notarizationStatus
''';
  }

  /// Display overall information, intended to be machine parseable
  ///
  /// Output is of the format:
  ///
  /// Executable=/Users/developer/Downloads/mybinary
  /// Identifier=mybinary
  /// Format=Mach-O thin (x86_64)
  /// CodeDirectory v=20500 size=38000 flags=0x10000(runtime) hashes=1177+7 location=embedded
  /// Signature size=8979
  /// Authority=Developer ID Application: Dev Shop ABC (ABCC0VV123)
  /// Authority=Developer ID Certification Authority
  /// Authority=Apple Root CA
  /// Timestamp=Jan 9, 2023 at 9:39:07 AM
  /// Info.plist=not bound
  /// TeamIdentifier=ABCC0VV123
  /// Runtime Version=13.1.0
  /// Sealed Resources=none
  /// Internal requirements count=1 size=164
  Future<bool> _codesignDisplay() async {
    final command = <String>['codesign', '--display', '-vv', binaryPath];
    final result = await pm.run(command);

    if (result.exitCode == 1) {
      logger.severe('''
File $binaryPath is not codesigned. To manually verify, run:

codesign --display -vv $binaryPath
''');
      return false;
    } else if (result.exitCode != 0) {
      throw Exception(
        'Command `${command.join(' ')}` failed with code ${result.exitCode}\n\n'
        '${result.stderr}',
      );
    }

    final lines = result.stderr.toString().trim().split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      final segments = line.split('=');
      final name = segments.first;

      switch (name) {
        case 'Executable':
        case 'Identifier':
        case 'CodeDirectory v':
        case 'Info.plist':
        // TeamIdentifier is redundant with the Authority field
        case 'TeamIdentifier':
        case 'Runtime Version':
        case 'Sealed Resources':
        case 'Internal requirements count':
          break;
        case 'Signature size':
          _signatureSize = segments.sublist(1).join();
          break;
        case 'Authority':
          if (segments[1].startsWith('Developer ID Application')) {
            _codesignId = segments[1];
          }
          break;
        case 'Timestamp':
          _codesignTimestamp = segments[1];
          break;
        case 'Format':
          _format = segments.sublist(1).join();
          break;
        default:
          logger.warning(
            'Do not know how to parse a $name, skipping this field.',
          );
      }
    }
    return true;
  }
}
