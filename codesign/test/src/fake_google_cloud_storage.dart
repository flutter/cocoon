// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:codesign/codesign.dart';
import 'package:file/file.dart';
import 'package:process/process.dart';

/// Utility function class to handle upload/download of files from/to google cloud.
class FakeGoogleCloudStorage extends GoogleCloudStorage {
  FakeGoogleCloudStorage();

  /// Wrapper function to upload code signed flutter engine artifact to google cloud bucket.
  @override
  Future<void> uploadEngineArtifact({
    required String localPath,
    required String remotePath,
    required String commitHash,
    required ProcessManager processManager,
    int exitCode = 0,
  }) async {
    final String fullRemotePath = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    return await fakeUploadFunction(
      localPath: localPath,
      destinationUrl: fullRemotePath,
      processManager: processManager,
      exitCode: exitCode,
    );
  }

  /// Wrapper function to download flutter engine artifact from google cloud bucket.
  @override
  Future<File> downloadEngineArtifact({
    required String remotePath,
    required String localPath,
    required String commitHash,
    required ProcessManager processManager,
    required Directory rootDirectory,
    int exitCode = 0,
  }) async {
    final String sourceUrl = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    return await fakeDownloadFunction(
      sourceUrl: sourceUrl,
      localPath: localPath,
      processManager: processManager,
      rootDirectory: rootDirectory,
      exitCode: exitCode,
    );
  }

  Future<void> fakeUploadFunction({
    required String localPath,
    required String destinationUrl,
    required ProcessManager processManager,
    int exitCode = 0,
  }) async {
    if (exitCode != 0) {
      throw CodesignException('Failed to upload $localPath to $destinationUrl');
    }
    return;
  }

  Future<File> fakeDownloadFunction({
    required String sourceUrl,
    required String localPath,
    required ProcessManager processManager,
    required Directory rootDirectory,
    int exitCode = 0,
  }) async {
    if (exitCode != 0) {
      throw CodesignException('Failed to download from $sourceUrl');
    }
    return rootDirectory.fileSystem.file(localPath);
  }
}
