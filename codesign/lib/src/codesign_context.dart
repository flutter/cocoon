// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:file/local.dart';
import 'package:process/process.dart';
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';

class CodesignContext{
  CodesignContext({
    required binariesWithEntitlements,
    required binariesWithoutEntitlements,
    required this.codesignCertName,
    required this.codesignPrimaryBundleId,
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
    required this.codesignFilepath,
    required this.commitHash,
  });

  final String codesignCertName;
  final String codesignPrimaryBundleId;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final String codesignFilepath;
  final String commitHash;

  final ProcessManager processManager = LocalProcessManager();
  final FileSystem fileSystem = LocalFileSystem();
  final Stdio stdio = VerboseStdio(
    stdout: stdout,
    stderr: stderr,
    stdin: stdin,
  );

  bool checkXcodeVersion(){
    bool isNotaryTool = true;
    print('checking Xcode version...');
    final ProcessResult result = processManager.runSync(
      <String>[
        'xcodebuild',
        '-version',
      ],
    );
    final List<String> outArray = (result.stdout as String).split('\n');
    final int xcodeVersion = int.parse(outArray[0].split(' ')[1].split('.')[0]);
    if(xcodeVersion <= 12){
      isNotaryTool = false;
    }
        
    print('based on your xcode major version of $xcodeVersion, the decision to use notarytool is $isNotaryTool');
    return isNotaryTool;
  }

  Future<void> run() async {
    final bool isNotaryTool = checkXcodeVersion();
    // assume file path is passed in as connected by # sign. e.g. path1#path2#path3
    List<String> filepaths = codesignFilepath.split('#');
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
    final FileCodesignVisitor codesignVisitor = FileCodesignVisitor(
      tempDir: tempDir,
      processManager: processManager,
      codesignCertName: codesignCertName,
      codesignPrimaryBundleId: codesignPrimaryBundleId,
      codesignUserName: codesignUserName,
      commitHash: commitHash,
      appSpecificPassword: appSpecificPassword,
      stdio: stdio,
      codesignAppstoreId: codesignAppstoreId,
      codesignTeamId: codesignTeamId,
      isNotaryTool: isNotaryTool,
    );

    await codesignVisitor.validateAll(filepaths);
    stdio.printStatus('Codesigned all binaries in ${tempDir.path}');
  }
}