// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:codesign/src/file_codesign_visitor.dart';
import 'package:process/process.dart';

/// helper function to generate unique next IDs.
int id = 0;
int get nextId {
  final int currentKey = id;
  id += 1;
  return currentKey;
}

enum FileType { folder, zip, binary, other }

Future<void> unzip(FileSystemEntity inputZip, Directory outDir, ProcessManager processManager) async {
  await processManager.run(
    <String>[
      'unzip',
      inputZip.absolute.path,
      '-d',
      outDir.absolute.path,
    ],
  );
  logger!.info('The downloaded file is unzipped from ${inputZip.absolute.path} to ${outDir.absolute.path}\n');
}

Future<void> zip(Directory inDir, FileSystemEntity outputZip, ProcessManager processManager) async {
  await processManager.run(
    <String>[
      'zip',
      '--symlinks',
      '--recurse-paths',
      outputZip.absolute.path,
      // use '.' so that the full absolute path is not encoded into the zip file
      '.',
      '--include',
      '*',
    ],
    workingDirectory: inDir.absolute.path,
  );
}

/// Check mime-type of file at [filePath] to determine if it is a directory.
FileType getFileType(String filePath, ProcessManager processManager) {
  final ProcessResult result = processManager.runSync(
    <String>[
      'file',
      '--mime-type',
      '-b', // is binary
      filePath,
    ],
  );
  String output = result.stdout as String;
  if (output.contains('inode/directory')) {
    return FileType.folder;
  } else if (output.contains('application/zip')) {
    return FileType.zip;
  } else if (output.contains('application/x-mach-binary')) {
    return FileType.binary;
  } else {
    return FileType.other;
  }
}

class CodesignException implements Exception {
  CodesignException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

/// Translate CLI arg names to env variable names.
///
/// For example, 'state-file' -> 'STATE_FILE'.
String fromArgToEnvName(String argName) {
  return argName.toUpperCase().replaceAll('-', '_');
}

/// Either return the value from [env] or fall back to [argResults].
///
/// If the key does not exist in either the environment or CLI args, throws a
/// [ConductorException].
///
/// The environment is favored over CLI args since the latter can have a default
/// value, which the environment should be able to override.
String? getValueFromEnvOrArgs(
  String name,
  ArgResults argResults,
  Map<String, String> env, {
  bool allowNull = false,
}) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null) {
    return env[envName];
  }
  final String? argValue = argResults[name] as String?;
  if (argValue != null) {
    return argValue;
  }

  if (allowNull) {
    return null;
  }
  throw CodesignException('Expected either the CLI arg --$name or the environment variable $envName '
      'to be provided!');
}
