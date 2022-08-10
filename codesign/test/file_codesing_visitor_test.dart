// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:codesign/codesign.dart' as cs;
import 'package:codesign/src/log.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import './src/fake_process_manager.dart';

void main() {
  const String randomString = 'abcd1234';
  final MemoryFileSystem fileSystem = MemoryFileSystem.test();
  const List<String> fakeFilepaths = <String>['a.zip', 'b.zip', 'c.zip'];

  late FakeProcessManager processManager;
  late Directory tempDir;
  late cs.FileCodesignVisitor codesignVisitor;
  final List<LogRecord> records = <LogRecord>[];

  group('visit directory/zip api calls: ', () {
    setUp(() {
      tempDir = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        codesignUserName: randomString,
        appSpecificPassword: randomString,
        codesignAppstoreId: randomString,
        codesignTeamId: randomString,
        codesignFilepaths: fakeFilepaths,
        commitHash: randomString,
        fileSystem: fileSystem,
        processManager: processManager,
        tempDir: tempDir,
      );
      codesignVisitor.directoriesVisited.clear();
      codesignVisitor.initialize();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('visitDirectory correctly list files', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_0/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_0/file_b').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_0/file_c').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_0/file_a',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_0/file_b',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_0/file_c',
          ],
          stdout: 'other_files',
        ),
      ]);
      final Directory testDirectory = fileSystem.directory('${tempDir.path}/remote_zip_0');
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        entitlementParentPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('Visiting directory ${tempDir.path}/remote_zip_0\n'));
      expect(messages, contains('Child file of direcotry remote_zip_0 is file_a\n'));
      expect(messages, contains('Child file of direcotry remote_zip_0 is file_b\n'));
      expect(messages, contains('Child file of direcotry remote_zip_0 is file_c\n'));
    });

    test('visitDirectory recursively visits directory', () async {
      fileSystem
        ..file('${tempDir.path}/remote_zip_1/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_1/folder_a/file_b').createSync(recursive: true);
      final Directory testDirectory = fileSystem.directory('${tempDir.path}/remote_zip_1');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_1/file_a',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_1/folder_a/file_b',
          ],
          stdout: 'other_files',
        ),
      ]);
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        entitlementParentPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('Visiting directory ${tempDir.path}/remote_zip_1\n'));
      expect(messages, contains('Visiting directory ${tempDir.path}/remote_zip_1/folder_a\n'));
      expect(messages, contains('Child file of direcotry remote_zip_1 is file_a\n'));
      expect(messages, contains('Child file of direcotry folder_a is file_b\n'));
    });

    test('visit directory inside a zip', () async {
      final String zipFileName = '${tempDir.path}/remote_zip_2/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
            command: <String>[
              'unzip',
              '${tempDir.absolute.path}/remote_zip_2/zip_1',
              '-d',
              '${tempDir.absolute.path}/embedded_zip_${zipFileName.hashCode}',
            ],
            onRun: () => fileSystem
              ..file('${tempDir.path}/embedded_zip_${zipFileName.hashCode}/file_1').createSync(recursive: true)
              ..file('${tempDir.path}/embedded_zip_${zipFileName.hashCode}/file_2').createSync(recursive: true)),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/embedded_zip_${zipFileName.hashCode}/file_1',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/embedded_zip_${zipFileName.hashCode}/file_2',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            '${tempDir.absolute.path}/remote_zip_2/zip_1',
            '.',
            '--include',
            '*'
          ],
          onRun: () => fileSystem.file('${tempDir.path}/remote_zip_2/zip_1').createSync(recursive: true),
        ),
      ]);

      await codesignVisitor.visitEmbeddedZip(
        zipEntity: fileSystem.file('${tempDir.path}/remote_zip_2/zip_1'),
        entitlementParentPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
          messages,
          contains(
              'The downloaded file is unzipped from ${tempDir.path}/remote_zip_2/zip_1 to ${tempDir.path}/embedded_zip_${zipFileName.hashCode}\n'));
      expect(messages, contains('Visiting directory ${tempDir.path}/embedded_zip_${zipFileName.hashCode}\n'));
      expect(messages, contains('Child file of direcotry embedded_zip_${zipFileName.hashCode} is file_1\n'));
      expect(messages, contains('Child file of direcotry embedded_zip_${zipFileName.hashCode} is file_2\n'));
    });

    test('visit zip inside a directory', () async {
      final String zipFileName = '${tempDir.path}/remote_zip_4/folder_1/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_4/folder_1/zip_1',
          ],
          stdout: 'application/zip',
        ),
        FakeCommand(
          command: <String>[
            'unzip',
            '${tempDir.absolute.path}/remote_zip_4/folder_1/zip_1',
            '-d',
            '${tempDir.absolute.path}/embedded_zip_${zipFileName.hashCode}',
          ],
          onRun: () =>
              fileSystem.directory('${tempDir.path}/embedded_zip_${zipFileName.hashCode}').createSync(recursive: true),
        ),
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

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${tempDir.path}/remote_zip_4'),
        entitlementParentPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('Visiting directory ${tempDir.absolute.path}/remote_zip_4\n'));
      expect(messages, contains('Visiting directory ${tempDir.absolute.path}/remote_zip_4/folder_1\n'));
      expect(
          messages,
          contains(
              'The downloaded file is unzipped from ${tempDir.path}/remote_zip_4/folder_1/zip_1 to ${tempDir.path}/embedded_zip_${zipFileName.hashCode}\n'));
      expect(messages, contains('Visiting directory ${tempDir.absolute.path}/embedded_zip_${zipFileName.hashCode}\n'));
    });

    test('throw exception when the same directory is visited', () async {
      fileSystem.file('${tempDir.path}/parent_1/child_1/file_1').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/parent_1/child_1/file_1',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/parent_1/child_1/file_1',
          ],
          stdout: 'other_files',
        ),
      ]);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${tempDir.path}/parent_1/child_1'),
        entitlementParentPath: 'a.zip',
      );
      List<String> warnings = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(warnings, isEmpty);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${tempDir.path}/parent_1'),
        entitlementParentPath: 'a.zip',
      );
      warnings = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
          warnings,
          contains(
              'Warning! You are visiting a directory that has been visited before, the directory is ${tempDir.path}/parent_1/child_1'));
    });

    test('visitBinary codesigns binary with / without entitlement', () async {
      codesignVisitor.fileWithEntitlements = <String>{'root/file_a'};
      codesignVisitor.fileWithoutEntitlements = <String>{'root/file_b'};
      fileSystem
        ..file('${tempDir.path}/remote_zip_1/file_a').createSync(recursive: true)
        ..file('${tempDir.path}/remote_zip_1/file_b').createSync(recursive: true);
      final Directory testDirectory = fileSystem.directory('${tempDir.path}/remote_zip_1');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_1/file_a',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            'ls',
            '-alhf',
            '${tempDir.absolute.path}/remote_zip_1/file_a',
          ],
          stdout: 'no_arrow_output',
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '-f',
            '-s',
            randomString,
            '${tempDir.absolute.path}/remote_zip_1/file_a',
            '--timestamp',
            '--options=runtime',
            '--entitlements',
            '${tempDir.absolute.path}/Entitlements.plist'
          ],
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${tempDir.absolute.path}/remote_zip_1/file_b',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            'ls',
            '-alhf',
            '${tempDir.absolute.path}/remote_zip_1/file_b',
          ],
          stdout: 'no_arrow_output',
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '-f',
            '-s',
            randomString,
            '${tempDir.absolute.path}/remote_zip_1/file_b',
            '--timestamp',
            '--options=runtime',
          ],
        ),
      ]);
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        entitlementParentPath: 'root',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('\n signing file at path ${tempDir.absolute.path}/remote_zip_1/file_a'));
      expect(messages, contains('\n the virtual entitlement path associated with file is root/file_a'));
      expect(messages, contains('\n the decision to sign with entitlement is true'));

      expect(messages, contains('\n signing file at path ${tempDir.absolute.path}/remote_zip_1/file_b'));
      expect(messages, contains('\n the virtual entitlement path associated with file is root/file_b'));
      expect(messages, contains('\n the decision to sign with entitlement is false'));
    });
  });
}
