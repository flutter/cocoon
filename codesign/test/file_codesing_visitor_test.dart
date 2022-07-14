// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:codesign/codesign.dart' as cs;
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import './src/fake_process_manager.dart';
import './utils/test_logger.dart';

void main() {
  const String randomString = 'abcd1234';
  late MemoryFileSystem fileSystem;
  fileSystem = MemoryFileSystem.test();
  TestLogger logger = TestLogger();
  const List<String> fakeFilepaths = ['a.zip', 'b.zip', 'c.zip'];
  FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[]);
  late Directory tempDir;
  late cs.FileCodesignVisitor codesignVisitor;

  group('visit directory', () {
    setUp(() {
      tempDir = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        codesignUserName: randomString,
        appSpecificPassword: randomString,
        codesignAppstoreId: randomString,
        codesignTeamId: randomString,
        codesignFilepaths: fakeFilepaths,
        commitHash: randomString,
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        visitDirectory: cs.visitDirectory,
        tempDir: tempDir,
      );
    });

    test('list files', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_0/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_0/file_b').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_0/file_c').createSync(recursive: true);
      await codesignVisitor.visitDirectory(fileSystem.directory('${tempDir.path}/remote_zip_0'), '', logger);
      expect(logger.logs[Level.INFO], contains('visiting directory ${tempDir.path}/remote_zip_0\n'));
      expect(logger.logs[Level.INFO], contains('child file of direcotry remote_zip_0 is file_a\n'));
      expect(logger.logs[Level.INFO], contains('child file of direcotry remote_zip_0 is file_b\n'));
      expect(logger.logs[Level.INFO], contains('child file of direcotry remote_zip_0 is file_c\n'));
    });

    test('recursively visit directory', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_1/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_1/folder_a/file_b').createSync(recursive: true);
      await codesignVisitor.visitDirectory(fileSystem.directory('${tempDir.path}/remote_zip_1'), '', logger);
      expect(logger.logs[Level.INFO], contains('visiting directory ${tempDir.path}/remote_zip_1\n'));
      expect(logger.logs[Level.INFO], contains('visiting directory ${tempDir.path}/remote_zip_1/folder_a\n'));
      expect(logger.logs[Level.INFO], contains('child file of direcotry remote_zip_1 is file_a\n'));
      expect(logger.logs[Level.INFO], contains('child file of direcotry folder_a is file_b\n'));
    });
  });
}
