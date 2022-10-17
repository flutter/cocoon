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
    required this.gCloudDownloadUploadPath,
  });

  final ProcessManager processManager;
  final Directory rootDirectory;
  final String gCloudDownloadUploadPath;
  final String bucketPrefix = 'gs://flutter_infra_release';

  /// Method to upload code signed flutter engine artifact to google cloud bucket.
  Future<void> uploadEngineArtifact({
    required String from,
  }) async {
    final String gCloudUploadPath = gCloudDownloadUploadPath.split("#").last;
    final String destinationUrl = '$bucketPrefix/$gCloudUploadPath';

    final ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', from, destinationUrl],
    );

    if (result.exitCode != 0) {
      throw CodesignException('Failed to upload $from to $destinationUrl');
    }
  }

  /// Method to download flutter engine artifact from google cloud bucket.
  Future<File> downloadEngineArtifact({
    required String destination,
  }) async {
    final String gCloudDownloadPath = gCloudDownloadUploadPath.split("#").first;
    final String sourceUrl = '$bucketPrefix/$gCloudDownloadPath';

    final ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', sourceUrl, destination],
    );
    if (result.exitCode != 0) {
      throw CodesignException('Failed to download from $sourceUrl');
    }
    return rootDirectory.fileSystem.file(destination);
  }
}
