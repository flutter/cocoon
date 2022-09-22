// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:process/process.dart';

import './utils.dart';

/// A service to interact with google cloud storage through gsutil.
class GoogleCloudStorage {
  GoogleCloudStorage({
    required this.processManager,
    required this.rootDirectory,
    required this.commitHash,
  });

  ProcessManager processManager;
  Directory rootDirectory;
  String commitHash;
  String gsCloudBaseUrl = 'gs://flutter_infra_release';

  /// Function to upload code signed flutter engine artifact to google cloud bucket.
  Future<void> uploadEngineArtifact({
    required String localPath,
    required String remotePath,
  }) async {
    final String destinationUrl = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';

    final ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', localPath, destinationUrl],
    );

    if (result.exitCode != 0) {
      throw CodesignException('Failed to upload $localPath to $destinationUrl');
    }
  }

  /// Function to download flutter engine artifact from google cloud bucket.
  Future<File> downloadEngineArtifact({
    required String remotePath,
    required String localPath,
  }) async {
    final String sourceUrl = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    final ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', sourceUrl, localPath],
    );
    if (result.exitCode != 0) {
      throw CodesignException('Failed to download from $sourceUrl');
    }
    return rootDirectory.fileSystem.file(localPath);
  }
}
