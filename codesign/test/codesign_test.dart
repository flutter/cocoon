// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:codesign/codesign.dart' as cs;
import 'package:file/file.dart';
import 'package:file/memory.dart';
import './src/common.dart';

/// A fake file visitor for testing purpose.
///
/// Upload for notarization is overriden, and the timer to check notarization
/// status is fired instantly.
class FakeCodesignVisitor extends cs.FileCodesignVisitor {
  FakeCodesignVisitor({
    required super.commitHash,
    required super.codesignCertName,
    required super.codesignUserName,
    required super.appSpecificPassword,
    required super.codesignAppstoreId,
    required super.codesignTeamId,
    required super.codesignFilepaths,
    super.production,
    this.fixitCheckMode = false,
  });

  bool fixitCheckMode;
}

void main() {
  const String randomString = 'abcd1234';
  late MemoryFileSystem fileSystem;
  fileSystem = MemoryFileSystem.test();
  TestStdio stdio = TestStdio();
  List<String> fakeFilepaths = ['a.zip', 'b.zip', 'c.zip'];
  FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[]);
  late Directory tempDir;
  late FakeCodesignVisitor codesignVisitor;
  
  void createRunner(){
    tempDir = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
    codesignVisitor = FakeCodesignVisitor(
      codesignCertName: randomString,
      codesignUserName: randomString,
      appSpecificPassword: randomString,
      codesignAppstoreId: randomString,
      codesignTeamId: randomString,
      codesignFilepaths: fakeFilepaths,
      commitHash: randomString,
    );
    codesignVisitor.tempDir = tempDir;
    codesignVisitor.processManager = processManager;
    codesignVisitor.stdio = stdio;
  } 

  test('visit directory', () async {
    createRunner();
    fileSystem.file('${tempDir.path}/remote_zip_0/file_a').createSync(recursive: true);
    fileSystem.file('${tempDir.path}/remote_zip_0/file_b').createSync(recursive: true);
    fileSystem.file('${tempDir.path}/remote_zip_0/file_c').createSync(recursive: true);
    await codesignVisitor.visitDirectory(fileSystem.directory('${tempDir.path}/remote_zip_0'), '');
    expect(stdio.stdout, contains('visiting directory ${tempDir.path}/remote_zip_0'));
    expect(stdio.stdout, contains('child files of direcotry are file_a file_b file_c'));
  });
}
