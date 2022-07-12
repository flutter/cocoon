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
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
    required this.commitHash,
    required this.codesignFilepaths,
    this.production = false,
  });

  final String codesignCertName;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final String commitHash;
  final bool production;
  List<String> codesignFilepaths;
  Directory? tempDir;
  FileCodesignVisitor? codesignVisitor;

  ProcessManager processManager = LocalProcessManager();
  FileSystem fileSystem = LocalFileSystem();
  Stdio stdio = VerboseStdio(
    stdout: stdout,
    stderr: stderr,
    stdin: stdin,
  );

  Future<void> run() async {
    tempDir ??= fileSystem.systemTempDirectory.createTempSync('conductor_codesign');

    codesignVisitor ??= FileCodesignVisitor(
      tempDir: tempDir!,
      processManager: processManager,
      codesignCertName: codesignCertName,
      codesignUserName: codesignUserName,
      commitHash: commitHash,
      appSpecificPassword: appSpecificPassword,
      stdio: stdio,
      codesignAppstoreId: codesignAppstoreId,
      codesignTeamId: codesignTeamId,
      codesignFilepaths: codesignFilepaths,
      production: production,
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
