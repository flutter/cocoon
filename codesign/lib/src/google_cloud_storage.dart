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
  });

  final ProcessManager processManager;
  final Directory rootDirectory;

  /// Method to upload code signed flutter engine artifact to google cloud bucket.
  Future<void> uploadEngineArtifact({
    required String from,
    required String destination,
  }) async {
    final ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', from, destination],
    );

    if (result.exitCode != 0) {
      throw CodesignException('Failed to upload $from to $destination');
    }
  }

  /// Method to download flutter engine artifact from google cloud bucket.
  Future<File> downloadEngineArtifact({
    required String from,
    required String destination,
  }) async {
    final ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', from, destination],
    );
    if (result.exitCode != 0) {
      throw CodesignException('Failed to download from $from');
    }
    return rootDirectory.fileSystem.file(destination);
  }
}
