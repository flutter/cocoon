// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:file/local.dart';
import 'package:process/process.dart';
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';

class CodesignContext {
  CodesignContext({
    required this.codesignCertName,
    required this.codesignPrimaryBundleId,
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
    required this.codesignFilepaths,
    required this.commitHash,
    this.production = false,
  });

  final String codesignCertName;
  final String codesignPrimaryBundleId;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final List<String> codesignFilepaths;
  final String commitHash;
  final bool production;
  Directory? tempDir;
  FileCodesignVisitor? codesignVisitor;

  ProcessManager processManager = LocalProcessManager();
  FileSystem fileSystem = LocalFileSystem();
  Stdio stdio = VerboseStdio(
    stdout: stdout,
    stderr: stderr,
    stdin: stdin,
  );

  void createTempDirectory() {
    tempDir ??= fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
  }

  Future<void> run() async {
    createTempDirectory();

    codesignVisitor ??= FileCodesignVisitor(
      tempDir: tempDir!,
      processManager: processManager,
      codesignCertName: codesignCertName,
      codesignPrimaryBundleId: codesignPrimaryBundleId,
      codesignUserName: codesignUserName,
      commitHash: commitHash,
      appSpecificPassword: appSpecificPassword,
      stdio: stdio,
      codesignAppstoreId: codesignAppstoreId,
      codesignTeamId: codesignTeamId,
      production: production,
      filepaths: codesignFilepaths,
    );

    try {
      await codesignVisitor!.validateAll();
      stdio.printStatus('Codesigned all binaries in ${tempDir!.path}');
    } finally {
      if (production) {
        await tempDir?.delete(recursive: true);
      } else {
        stdio.printStatus('Codesign test run finished. You can examine files at ${tempDir!.path}');
      }
    }
  }
}
