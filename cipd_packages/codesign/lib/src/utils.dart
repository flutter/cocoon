// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:process/process.dart';

import 'log.dart';

enum FileType {
  folder,
  zip,
  binary,
  other;

  // Artifact files have many different types. Codesign would be no-op when encoutering non typical types such as application/octet-stream.
  factory FileType.fromMimeType(String mimeType) {
    if (mimeType.contains('inode/directory')) {
      return FileType.folder;
    } else if (mimeType.contains('application/zip')) {
      return FileType.zip;
    } else if (mimeType.contains('application/x-mach-binary')) {
      return FileType.binary;
    } else {
      return FileType.other;
    }
  }
}

Future<void> unzip({
  required FileSystemEntity inputZip,
  required Directory outDir,
  required ProcessManager processManager,
}) async {
  await processManager.run(
    <String>[
      'unzip',
      inputZip.absolute.path,
      '-d',
      outDir.absolute.path,
    ],
  );
  outDir.listSync(recursive: true).forEach((entity) {
    if (entity.basename.toLowerCase() == '.ds_store') {
      try {
        entity.deleteSync();
        log.info('Deleted ${entity.path}.');
      } catch (err) {
        log.severe('Error while trying to delete ${entity.path}');
        rethrow;
      }
    }
  });
  log.info(
      'The downloaded file is unzipped from ${inputZip.absolute.path} to ${outDir.absolute.path}');
}

Future<void> zip({
  required Directory inputDir,
  required String outputZipPath,
  required ProcessManager processManager,
}) async {
  await processManager.run(
    <String>[
      'zip',
      '--symlinks',
      '--recurse-paths',
      outputZipPath,
      // use '.' so that the full absolute path is not encoded into the zip file
      '.',
      '--include',
      '*',
    ],
    workingDirectory: inputDir.absolute.path,
  );
}

/// Check mime-type of file at [filePath] to determine if it is a directory.
FileType getFileType(String filePath, ProcessManager processManager) {
  final result = processManager.runSync(
    <String>[
      'file',
      '--mime-type',
      '-b', // is binary
      filePath,
    ],
  );
  final output = result.stdout as String;
  return FileType.fromMimeType(output);
}

class CodesignException implements Exception {
  CodesignException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

/// Return the command line argument by parsing [argResults].
///
/// If the key does not exist in CLI args, throws a [CodesignException].
String? getValueFromArgs(
  String name,
  ArgResults argResults, {
  bool allowNull = false,
}) {
  final argValue = argResults[name] as String?;
  if (argValue != null) {
    return argValue;
  }
  if (allowNull) {
    return null;
  }
  throw CodesignException('Expected either the CLI arg --$name '
      'to be provided!');
}

String joinEntitlementPaths(String entitlementParentPath, String pathToJoin) {
  if (entitlementParentPath == '') {
    return pathToJoin;
  } else {
    return '$entitlementParentPath/$pathToJoin';
  }
}
