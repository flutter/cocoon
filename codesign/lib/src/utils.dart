// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:process/process.dart';

import 'log.dart';

/// Utility function to upload a file to google cloud.
Future<void> uploadFunction({
  required String localPath,
  required String destinationUrl,
  required ProcessManager processManager,
}) async {
  final ProcessResult result = await processManager.run(
    <String>['gsutil', 'cp', localPath, destinationUrl],
  );
  if (result.exitCode != 0) {
    throw Exception('Failed to upload $localPath to $destinationUrl');
  }
}

/// Utility function to download a file from google cloud.
Future<File> downloadFunction({
  required String sourceUrl,
  required String localPath,
  required ProcessManager processManager,
  required Directory rootDirectory,
}) async {
  final ProcessResult result = await processManager.run(
    <String>['gsutil', 'cp', sourceUrl, localPath],
  );
  if (result.exitCode != 0) {
    throw CodesignException('Failed to download from $sourceUrl');
  }
  return rootDirectory.fileSystem.file(localPath);
}

/// Utility function class to handle upload/download of files from/to google cloud.
class EngineArtifactTransfer {
  EngineArtifactTransfer({
    required this.gsCloudBaseUrl,
    required this.uploadFunction,
    required this.downloadFunction,
  });

  String gsCloudBaseUrl;
  Function uploadFunction;
  Function downloadFunction;

  /// Wrapper function to upload code signed flutter engine artifact to google cloud bucket.
  Future<void> uploadEngineArtifact({
    required String localPath,
    required String remotePath,
    required String commitHash,
    required ProcessManager processManager,
    int exitCode = 0,
  }) async {
    final String fullRemotePath = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    return await uploadFunction(
      localPath: localPath,
      destinationUrl: fullRemotePath,
      processManager: processManager,
      exitCode: exitCode,
    );
  }

  /// Wrapper function to download flutter engine artifact from google cloud bucket.
  Future<File> downloadEngineArtifact({
    required String remotePath,
    required String localPath,
    required String commitHash,
    required ProcessManager processManager,
    required Directory rootDirectory,
    int exitCode = 0,
  }) async {
    final String sourceUrl = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    return await downloadFunction(
      sourceUrl: sourceUrl,
      localPath: localPath,
      processManager: processManager,
      rootDirectory: rootDirectory,
      exitCode: exitCode,
    );
  }
}

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
  log.info('The downloaded file is unzipped from ${inputZip.absolute.path} to ${outDir.absolute.path}');
}

Future<void> zip({
  required Directory inputDir,
  required FileSystemEntity outputZip,
  required ProcessManager processManager,
}) async {
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
    workingDirectory: inputDir.absolute.path,
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
  final String output = result.stdout as String;
  return FileType.fromMimeType(output);
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
