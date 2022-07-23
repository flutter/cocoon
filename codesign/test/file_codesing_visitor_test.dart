// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:codesign/codesign.dart' as cs;
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import './src/fake_process_manager.dart';

/// An override of [cs.visitEmbeddedZip].
///
/// After extracting a folder from a zip file, (a fake unzip)
/// [visitEmbeddedZipTest] delegates the extracted folder to
/// [visitDirectoryPrintln], instead of the real [cs.visitDirectory] fucntion.
/// This override is used when we don't want to actually perform the
/// zip/unzip operations, but would like to verify the extracted folder.
Future<void> visitEmbeddedZipTest(FileSystemEntity file, String entitlementParentPath, Directory tempDir,
    ProcessManager processManager, Logger logger, Function visitDirectory) async {
  logger.info('this embedded file is ${file.path} and entitlementParentPath is $entitlementParentPath\n');
  String currentFileName = file.path.split('/').last;
  final Directory newDir = tempDir.childDirectory('embedded_zip_${cs.nextId}'); //..createSync();
  await cs.unzip(file, newDir, processManager, logger);

  // the virtual file path is advanced by the name of the embedded zip
  String currentZipEntitlementPath = '$entitlementParentPath/$currentFileName';
  await visitDirectoryPrintln(newDir, currentZipEntitlementPath, tempDir, logger, processManager, visitEmbeddedZipTest);
  await file.delete(recursive: true);
  await cs.zip(newDir, file, processManager, logger);
}

/// An override of [cs.visitDirectory].
///
/// Inside a directory, a child file is considered as a [cs.FILETYPE.ZIP] if its
/// name contains 'zip'. This helps us skip the mime type check.
Future<void> visitDirectoryTest(Directory directory, String entitlementParentPath, Directory tempDir, Logger logger,
    ProcessManager processManager, Function visitEmbeddedZip) async {
  logger.info('visiting directory ${directory.absolute.path}\n');
  final List<FileSystemEntity> entities = await directory.list().toList();
  for (FileSystemEntity entity in entities) {
    if (entity is io.Directory) {
      await visitDirectoryTest(directory.childDirectory(entity.basename), entitlementParentPath, tempDir, logger,
          processManager, visitEmbeddedZip);
    }

    if (entity.basename.contains('zip')) {
      await visitEmbeddedZip(entity, entitlementParentPath, tempDir, processManager, logger, visitDirectoryTest);
    }
    logger.info('child file of direcotry ${directory.basename} is ${entity.basename}\n');
  }
}

/// An override of [cs.visitDirectory].
///
/// Instead of recursively going down, [visitDirectoryPrintln] logs the current
/// directory.
Future<void> visitDirectoryPrintln(Directory directory, String entitlementParentPath, Directory tempDir, Logger logger,
    ProcessManager processManager, Function visitEmbeddedZip) async {
  logger.info('visiting a test directory ${directory.basename}');
}

void main() {
  const String randomString = 'abcd1234';
  late MemoryFileSystem fileSystem;
  fileSystem = MemoryFileSystem.test();
  Logger logger = Logger('codesign-test');
  const List<String> fakeFilepaths = ['a.zip', 'b.zip', 'c.zip'];
  FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[]);
  late Directory tempDir;
  late cs.FileCodesignVisitor codesignVisitor;
  final List<LogRecord> records = <LogRecord>[];

  group('visit directory/zip api calls: ', () {
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
        visitDirectory: visitDirectoryTest,
        visitEmbeddedZip: cs.visitEmbeddedZip,
        tempDir: tempDir,
      );
      records.clear();
      logger.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('visitDirectory correctly list files', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_0/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_0/file_b').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_0/file_c').createSync(recursive: true);
      Directory testDirectory = fileSystem.directory('${tempDir.path}/remote_zip_0');
      await codesignVisitor.visitDirectory(
          testDirectory, testDirectory.path, tempDir, logger, processManager, cs.visitEmbeddedZip);
      List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('visiting directory ${tempDir.path}/remote_zip_0\n'));
      expect(messages, contains('child file of direcotry remote_zip_0 is file_a\n'));
      expect(messages, contains('child file of direcotry remote_zip_0 is file_b\n'));
      expect(messages, contains('child file of direcotry remote_zip_0 is file_c\n'));
    });

    test('visitDirectory recursively visits directory', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_1/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_1/folder_a/file_b').createSync(recursive: true);
      Directory testDirectory = fileSystem.directory('${tempDir.path}/remote_zip_1');
      await codesignVisitor.visitDirectory(
          testDirectory, testDirectory.path, tempDir, logger, processManager, cs.visitEmbeddedZip);
      List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('visiting directory ${tempDir.path}/remote_zip_1\n'));
      expect(messages, contains('visiting directory ${tempDir.path}/remote_zip_1/folder_a\n'));
      expect(messages, contains('child file of direcotry remote_zip_1 is file_a\n'));
      expect(messages, contains('child file of direcotry folder_a is file_b\n'));
    });

    test('visit directory inside a zip', () async {
      codesignVisitor.visitEmbeddedZip = cs.visitEmbeddedZip;
      fileSystem.file('${tempDir.path}/remote_zip_2/zip_1').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/remote_zip_2',
          '-d',
          '${tempDir.absolute.path}/embedded_zip_0',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/remote_zip_2',
          '.',
          '--include',
          '*'
        ]),
      ]);

      await codesignVisitor.visitEmbeddedZip(
          fileSystem.file('${tempDir.path}/remote_zip_2'), '', tempDir, processManager, logger, visitDirectoryPrintln);
      List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
          messages,
          contains(
              'the downloaded file is unzipped from ${tempDir.path}/remote_zip_2 to ${tempDir.path}/embedded_zip_0\n'));
      expect(messages, contains('visiting a test directory embedded_zip_0'));
    });

    test('visit zip inside a directory', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_4/folder_1/zip_1').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_4/folder_1/other_1').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/remote_zip_4/folder_1/zip_1',
          '-d',
          '${tempDir.absolute.path}/embedded_zip_1',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/remote_zip_4/folder_1/zip_1',
          '.',
          '--include',
          '*'
        ]),
      ]);

      await codesignVisitor.visitDirectory(fileSystem.directory('${tempDir.path}/remote_zip_4'), '', tempDir, logger,
          processManager, visitEmbeddedZipTest);
      List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
          messages,
          contains(
              'the downloaded file is unzipped from ${tempDir.path}/remote_zip_4/folder_1/zip_1 to ${tempDir.path}/embedded_zip_1\n'));
      expect(messages, contains('visiting a test directory embedded_zip_1'));
    });
  });
}
