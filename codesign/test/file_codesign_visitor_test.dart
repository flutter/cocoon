// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:codesign/codesign.dart' as cs;
import 'package:codesign/src/log.dart';
import 'package:codesign/src/utils.dart';
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
      expect(messages, contains('Visiting directory ${tempDir.path}/remote_zip_0'));
      expect(messages, contains('Child file of directory remote_zip_0 is file_a'));
      expect(messages, contains('Child file of directory remote_zip_0 is file_b'));
      expect(messages, contains('Child file of directory remote_zip_0 is file_c'));
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
      expect(messages, contains('Visiting directory ${tempDir.path}/remote_zip_1'));
      expect(messages, contains('Visiting directory ${tempDir.path}/remote_zip_1/folder_a'));
      expect(messages, contains('Child file of directory remote_zip_1 is file_a'));
      expect(messages, contains('Child file of directory folder_a is file_b'));
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
              'The downloaded file is unzipped from ${tempDir.path}/remote_zip_2/zip_1 to ${tempDir.path}/embedded_zip_${zipFileName.hashCode}'));
      expect(messages, contains('Visiting directory ${tempDir.path}/embedded_zip_${zipFileName.hashCode}'));
      expect(messages, contains('Child file of directory embedded_zip_${zipFileName.hashCode} is file_1'));
      expect(messages, contains('Child file of directory embedded_zip_${zipFileName.hashCode} is file_2'));
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
      expect(messages, contains('Visiting directory ${tempDir.absolute.path}/remote_zip_4'));
      expect(messages, contains('Visiting directory ${tempDir.absolute.path}/remote_zip_4/folder_1'));
      expect(
          messages,
          contains(
              'The downloaded file is unzipped from ${tempDir.path}/remote_zip_4/folder_1/zip_1 to ${tempDir.path}/embedded_zip_${zipFileName.hashCode}'));
      expect(messages, contains('Visiting directory ${tempDir.absolute.path}/embedded_zip_${zipFileName.hashCode}'));
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
      expect(messages, contains('signing file at path ${tempDir.absolute.path}/remote_zip_1/file_a'));
      expect(messages, contains('the virtual entitlement path associated with file is root/file_a'));
      expect(messages, contains('the decision to sign with entitlement is true'));

      expect(messages, contains('signing file at path ${tempDir.absolute.path}/remote_zip_1/file_b'));
      expect(messages, contains('the virtual entitlement path associated with file is root/file_b'));
      expect(messages, contains('the decision to sign with entitlement is false'));
    });
  });

  group('parse entitlement configs: ', () {
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
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('correctly store file paths', () async {
      fileSystem.file('${tempDir.absolute.path}/test_entitlement/entitlements.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''file_a
file_b
file_c''',
          mode: FileMode.append,
          encoding: utf8,
        );

      fileSystem.file('${tempDir.absolute.path}/test_entitlement/without_entitlements.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''file_d
file_e''',
          mode: FileMode.append,
          encoding: utf8,
        );
      final Set<String> fileWithEntitlements = await codesignVisitor.parseEntitlements(
        fileSystem.directory('${tempDir.absolute.path}/test_entitlement'),
        true,
      );
      final Set<String> fileWithoutEntitlements = await codesignVisitor.parseEntitlements(
        fileSystem.directory('${tempDir.absolute.path}/test_entitlement'),
        false,
      );
      expect(fileWithEntitlements.length, 3);
      expect(
          fileWithEntitlements,
          containsAll(<String>[
            'file_a',
            'file_b',
            'file_c',
          ]));
      expect(fileWithoutEntitlements.length, 2);
      expect(
          fileWithoutEntitlements,
          containsAll(<String>[
            'file_d',
            'file_e',
          ]));
    });

    test('throw exception when configuration file is missing', () async {
      fileSystem.file('${tempDir.absolute.path}/test_entitlement/entitlements.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''file_a
file_b
file_c''',
          mode: FileMode.append,
          encoding: utf8,
        );

      final Set<String> fileWithEntitlements = await codesignVisitor.parseEntitlements(
        fileSystem.directory('${tempDir.absolute.path}/test_entitlement'),
        true,
      );
      expect(fileWithEntitlements.length, 3);
      expect(
          fileWithEntitlements,
          containsAll(<String>[
            'file_a',
            'file_b',
            'file_c',
          ]));
      expect(
          () => codesignVisitor.parseEntitlements(
                fileSystem.directory('/Users/xilaizhang/Desktop/test_entitlement'),
                false,
              ),
          throwsA(
            isA<CodesignException>(),
          ));
    });
  });

  group('notarization tests: ', () {
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
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('successful notarization check returns true', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            randomString,
            '--password',
            randomString,
            '--apple-id',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''createdDate: 2021-04-29T01:38:09.498Z
id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
name: OvernightTextEditor_11.6.8.zip
status: Accepted''',
        ),
      ]);

      expect(
        codesignVisitor.checkNotaryJobFinished(randomString),
        true,
      );
    });

    test('wrong format (such as altool) check throws exception', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            randomString,
            '--password',
            randomString,
            '--apple-id',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''RequestUUID: 2EFE2717-52EF-43A5-96DC-0797E4CA1041
Date: 2021-07-02 20:32:01 +0000
Status: invalid
LogFileURL: https://osxapps.itunes.apple.com/...
Status Code: 2
Status Message: Package Invalid''',
        ),
      ]);

      expect(
        () => codesignVisitor.checkNotaryJobFinished(randomString),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('in progress notarization check returns false', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            randomString,
            '--password',
            randomString,
            '--apple-id',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''createdDate: 2021-04-29T01:38:09.498Z
id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
name: OvernightTextEditor_11.6.8.zip
status: In Progress''',
        ),
      ]);

      expect(
        codesignVisitor.checkNotaryJobFinished(randomString),
        false,
      );
    });

    test('invalid status check throws exception', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            randomString,
            '--password',
            randomString,
            '--apple-id',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''createdDate: 2021-04-29T01:38:09.498Z
id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
name: OvernightTextEditor_11.6.8.zip
status: Invalid''',
        ),
      ]);

      expect(
        () => codesignVisitor.checkNotaryJobFinished(randomString),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('upload notary retries upon failure', () async {
      fileSystem.file('${tempDir.absolute.path}/temp').createSync();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${tempDir.absolute.path}/temp',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''Error uploading file. 
 Id: something that causes failure
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${tempDir.absolute.path}/temp',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''Successfully uploaded file. 
 id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
      ]);

      final String uuid = codesignVisitor.uploadZipToNotary(
        fileSystem.file('${tempDir.absolute.path}/temp'),
        3,
        0,
      );
      expect(uuid, '2efe2717-52ef-43a5-96dc-0797e4ca1041');
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
        messages,
        contains('Failed to upload to the notary service with args: '
            'xcrun notarytool submit ${tempDir.absolute.path}/temp '
            '--apple-id abcd1234 --password abcd1234 --team-id abcd1234'),
      );
      expect(
        messages,
        contains('Trying again 2 more times...'),
      );
    });

    test('upload notary throws exception after 3 default tries', () async {
      fileSystem.file('${tempDir.absolute.path}/temp').createSync();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${tempDir.absolute.path}/temp',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''Error uploading file. 
 Id: something that causes failure
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${tempDir.absolute.path}/temp',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''Error uploading file. 
 Id: something that causes failure
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${tempDir.absolute.path}/temp',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: '''Error uploading file. 
 Id: something that causes failure
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
      ]);

      expect(
        () => codesignVisitor.uploadZipToNotary(
          fileSystem.file('${tempDir.absolute.path}/temp'),
          3,
          0,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });
  });
}
