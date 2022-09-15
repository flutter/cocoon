// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:process/process.dart';

import './utils.dart';

/// Utility function class to handle upload/download of files from/to google cloud.
class EngineArtifactTransfer {
  EngineArtifactTransfer({
    required this.gsCloudBaseUrl,
    this.uploadFunction,
    this.downloadFunction,
  }) {
    uploadFunction ??= defaultUploadFunction;
    downloadFunction ??= defaultDownloadFunction;
  }

  String gsCloudBaseUrl;
  Function? uploadFunction;
  Function? downloadFunction;

  /// Wrapper function to upload code signed flutter engine artifact to google cloud bucket.
  Future<void> uploadEngineArtifact({
    required String localPath,
    required String remotePath,
    required String commitHash,
    required ProcessManager processManager,
    int exitCode = 0,
  }) async {
    final String fullRemotePath = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    return await uploadFunction!(
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
    return await downloadFunction!(
      sourceUrl: sourceUrl,
      localPath: localPath,
      processManager: processManager,
      rootDirectory: rootDirectory,
      exitCode: exitCode,
    );
  }

  /// Utility function to upload a file to google cloud.
  Future<void> defaultUploadFunction({
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
  Future<File> defaultDownloadFunction({
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
}
