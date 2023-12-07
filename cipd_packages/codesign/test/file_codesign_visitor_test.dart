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
  const String fakeAppleID = 'flutter-appleID';
  const String fakePassword = 'flutter-password';
  const String fakeTeamID = 'flutter-teamID';
  const String uuid = 'uuid';
  const String appSpecificPasswordFilePath = '/tmp/passwords.txt';
  const String codesignAppstoreIDFilePath = '/tmp/appID.txt';
  const String codesignTeamIDFilePath = '/tmp/teamID.txt';
  const String inputZipPath = '/tmp/input.zip';
  const String outputZipPath = '/tmp/output.zip';
  final List<LogRecord> records = <LogRecord>[];

  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late cs.FileCodesignVisitor codesignVisitor;
  late Directory rootDirectory;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    records.clear();
    log.onRecord.listen((LogRecord record) => records.add(record));
  });

  group('test reading in passwords: ', () {
    setUp(() {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        notarizationTimerDuration: const Duration(seconds: 0),
        dryrun: false,
      );
      codesignVisitor.directoriesVisited.clear();
    });

    test('lacking password file throws exception', () async {
      expect(
        () async {
          await codesignVisitor.readPassword(appSpecificPasswordFilePath);
        },
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('providing correctly formatted password returns normally', () async {
      fileSystem.file(appSpecificPasswordFilePath)
        ..createSync(recursive: true, exclusive: true)
        ..writeAsStringSync(
          '123',
          mode: FileMode.write,
          encoding: utf8,
        );

      expect(
        () async {
          await codesignVisitor.readPassword(appSpecificPasswordFilePath);
          await fileSystem.file(appSpecificPasswordFilePath).delete();
        },
        returnsNormally,
      );
    });
  });

  group('test utils function to join virtual entitlement path: ', () {
    test('omits slash for the first path', () async {
      expect(joinEntitlementPaths('', randomString), randomString);
    });

    test('concat with slash', () async {
      expect(joinEntitlementPaths(randomString, randomString), '$randomString/$randomString');
    });
  });

  group('test google cloud storage and processRemoteZip workflow', () {
    setUp(() {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
        dryrun: false,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
      );
      codesignVisitor.directoriesVisited.clear();
      codesignVisitor.appSpecificPassword = fakePassword;
      codesignVisitor.codesignAppstoreId = fakeAppleID;
      codesignVisitor.codesignTeamId = fakeTeamID;
    });

    test('procesRemotezip triggers correct workflow', () async {
      final String zipFileName = '${rootDirectory.path}/remote_zip_4/folder_1/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'unzip',
            codesignVisitor.inputZipPath,
            '-d',
            '${rootDirectory.absolute.path}/single_artifact',
          ],
          onRun: () => fileSystem
            ..file('${rootDirectory.path}/single_artifact/entitlements.txt').createSync(recursive: true)
            ..file('${rootDirectory.path}/single_artifact/without_entitlements.txt').createSync(recursive: true),
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            codesignVisitor.outputZipPath,
            '.',
            '--include',
            '*',
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            codesignVisitor.outputZipPath,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
          ],
          stdout: 'id: $uuid',
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
          ],
          stdout: 'status: Accepted',
        ),
      ]);

      await codesignVisitor.processRemoteZip();
      final Set<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toSet();
      expect(
        messages,
        contains(
          'The downloaded file is unzipped from ${codesignVisitor.inputZipPath} to ${rootDirectory.path}/single_artifact',
        ),
      );
      expect(
        messages,
        contains('Visiting directory ${rootDirectory.absolute.path}/single_artifact'),
      );
      expect(
        messages,
        contains('parsed binaries with entitlements are {}'),
      );
      expect(
        messages,
        contains('parsed binaries without entitlements are {}'),
      );
      expect(
        messages,
        contains(
          'uploading to notary: xcrun notarytool submit ${codesignVisitor.outputZipPath} --apple-id <appleID> --password <appSpecificPassword> '
          '--team-id <teamID> --verbose',
        ),
      );
      expect(
        messages,
        contains('RequestUUID for ${codesignVisitor.outputZipPath} is: $uuid'),
      );
      expect(
        messages,
        contains(
          'checking notary info: xcrun notarytool info $uuid --apple-id <appleID> --password <appSpecificPassword> '
          '--team-id <teamID>',
        ),
      );
      expect(
        messages,
        contains('successfully notarized ${codesignVisitor.outputZipPath}'),
      );
    });
  });

  group('visit directory/zip api calls: ', () {
    setUp(() {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        notarizationTimerDuration: Duration.zero,
      );
      codesignVisitor.directoriesVisited.clear();
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
    });

    test('visitDirectory correctly list files', () async {
      fileSystem
        ..file('${rootDirectory.path}/remote_zip_0/file_a').createSync(recursive: true)
        ..file('${rootDirectory.path}/remote_zip_0/file_b').createSync(recursive: true)
        ..file('${rootDirectory.path}/remote_zip_0/file_c').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_0/file_a',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_0/file_b',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_0/file_c',
          ],
          stdout: 'other_files',
        ),
      ]);
      final Directory testDirectory = fileSystem.directory('${rootDirectory.path}/remote_zip_0');
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        parentVirtualPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('Visiting directory ${rootDirectory.path}/remote_zip_0'));
      expect(messages, contains('Child file of directory remote_zip_0 is file_a'));
      expect(messages, contains('Child file of directory remote_zip_0 is file_b'));
      expect(messages, contains('Child file of directory remote_zip_0 is file_c'));
    });

    test('visitDirectory recursively visits directory', () async {
      fileSystem
        ..file('${rootDirectory.path}/remote_zip_1/file_a').createSync(recursive: true)
        ..file('${rootDirectory.path}/remote_zip_1/folder_a/file_b').createSync(recursive: true);
      final Directory testDirectory = fileSystem.directory('${rootDirectory.path}/remote_zip_1');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_1/file_a',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_1/folder_a/file_b',
          ],
          stdout: 'other_files',
        ),
      ]);
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        parentVirtualPath: '',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('Visiting directory ${rootDirectory.path}/remote_zip_1'));
      expect(messages, contains('Visiting directory ${rootDirectory.path}/remote_zip_1/folder_a'));
      expect(messages, contains('Child file of directory remote_zip_1 is file_a'));
      expect(messages, contains('Child file of directory folder_a is file_b'));
    });

    test('visit directory inside a zip', () async {
      final String zipFileName = '${rootDirectory.path}/remote_zip_2/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'unzip',
            '${rootDirectory.absolute.path}/remote_zip_2/zip_1',
            '-d',
            '${rootDirectory.absolute.path}/embedded_zip_${zipFileName.hashCode}',
          ],
          onRun: () => fileSystem
            ..file('${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}/file_1').createSync(recursive: true)
            ..file('${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}/file_2').createSync(recursive: true),
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/embedded_zip_${zipFileName.hashCode}/file_1',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/embedded_zip_${zipFileName.hashCode}/file_2',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            '${rootDirectory.absolute.path}/remote_zip_2/zip_1',
            '.',
            '--include',
            '*',
          ],
          onRun: () => fileSystem.file('${rootDirectory.path}/remote_zip_2/zip_1').createSync(recursive: true),
        ),
      ]);

      await codesignVisitor.visitEmbeddedZip(
        zipEntity: fileSystem.file('${rootDirectory.path}/remote_zip_2/zip_1'),
        parentVirtualPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
        messages,
        contains(
          'The downloaded file is unzipped from ${rootDirectory.path}/remote_zip_2/zip_1 to ${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}',
        ),
      );
      expect(messages, contains('Visiting directory ${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}'));
      expect(messages, contains('Child file of directory embedded_zip_${zipFileName.hashCode} is file_1'));
      expect(messages, contains('Child file of directory embedded_zip_${zipFileName.hashCode} is file_2'));
    });

    test('visit zip inside a directory', () async {
      final String zipFileName = '${rootDirectory.path}/remote_zip_4/folder_1/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_4/folder_1/zip_1',
          ],
          stdout: 'application/zip',
        ),
        FakeCommand(
          command: <String>[
            'unzip',
            '${rootDirectory.absolute.path}/remote_zip_4/folder_1/zip_1',
            '-d',
            '${rootDirectory.absolute.path}/embedded_zip_${zipFileName.hashCode}',
          ],
          onRun: () => fileSystem
              .directory('${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}')
              .createSync(recursive: true),
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            '${rootDirectory.absolute.path}/remote_zip_4/folder_1/zip_1',
            '.',
            '--include',
            '*',
          ],
        ),
      ]);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${rootDirectory.path}/remote_zip_4'),
        parentVirtualPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('Visiting directory ${rootDirectory.absolute.path}/remote_zip_4'));
      expect(messages, contains('Visiting directory ${rootDirectory.absolute.path}/remote_zip_4/folder_1'));
      expect(
        messages,
        contains(
          'The downloaded file is unzipped from ${rootDirectory.path}/remote_zip_4/folder_1/zip_1 to ${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}',
        ),
      );
      expect(
        messages,
        contains('Visiting directory ${rootDirectory.absolute.path}/embedded_zip_${zipFileName.hashCode}'),
      );
    });

    test('throw exception when the same directory is visited', () async {
      fileSystem.file('${rootDirectory.path}/parent_1/child_1/file_1').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/parent_1/child_1/file_1',
          ],
          stdout: 'other_files',
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/parent_1/child_1/file_1',
          ],
          stdout: 'other_files',
        ),
      ]);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${rootDirectory.path}/parent_1/child_1'),
        parentVirtualPath: 'a.zip',
      );
      List<String> warnings = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(warnings, isEmpty);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${rootDirectory.path}/parent_1'),
        parentVirtualPath: 'a.zip',
      );
      warnings = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
        warnings,
        contains(
          'Warning! You are visiting a directory that has been visited before, the directory is ${rootDirectory.path}/parent_1/child_1',
        ),
      );
    });

    test('visitDirectory skips file or directory that is a symlink', () async {
      fileSystem
        ..file('${rootDirectory.path}/remote_zip_5/target_dir/file_b').createSync(recursive: true)
        ..directory('${rootDirectory.path}/remote_zip_5/symlink_dir').createSync(recursive: true)
        ..link('${rootDirectory.path}/remote_zip_5/symlink_dir/file_a')
            .createSync('${rootDirectory.path}/remote_zip_5/target_dir/file_b')
        ..link('${rootDirectory.path}/remote_zip_5/symlink_dir_2')
            .createSync('${rootDirectory.path}/remote_zip_5/target_dir');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_5/target_dir/file_b',
          ],
          stdout: 'other_files',
        ),
      ]);
      final Directory testDirectory = fileSystem.directory('${rootDirectory.path}/remote_zip_5');
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        parentVirtualPath: 'a.zip',
      );
      final Set<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toSet();
      expect(messages, contains('Visiting directory ${rootDirectory.path}/remote_zip_5/target_dir'));
      expect(messages, contains('Child file of directory target_dir is file_b'));

      // Skip code signing a file that is a symlink.
      expect(messages, contains('Visiting directory ${rootDirectory.path}/remote_zip_5/symlink_dir'));
      expect(
        messages,
        contains('current file or direcotry ${rootDirectory.path}/remote_zip_5/symlink_dir/file_a is a symlink to '
            '${rootDirectory.path}/remote_zip_5/target_dir/file_b, codesign is therefore skipped for the current file or directory.'),
      );
      expect(messages, isNot(contains('Child file of directory symlink_dir is file_a')));

      // Skip code signing a directory that is a symlink.
      expect(
        messages,
        contains('current file or direcotry ${rootDirectory.path}/remote_zip_5/symlink_dir_2 is a symlink to '
            '${rootDirectory.path}/remote_zip_5/target_dir, codesign is therefore skipped for the current file or directory.'),
      );
    });

    test('visitBinary codesigns binary with / without entitlement', () async {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        dryrun: false,
        notarizationTimerDuration: const Duration(seconds: 0),
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.fileWithEntitlements = <String>{'root/folder_a/file_a'};
      codesignVisitor.fileWithoutEntitlements = <String>{'root/folder_b/file_b'};
      fileSystem
        ..file('${rootDirectory.path}/remote_zip_6/folder_a/file_a').createSync(recursive: true)
        ..file('${rootDirectory.path}/remote_zip_6/folder_b/file_b').createSync(recursive: true);
      final Directory testDirectory = fileSystem.directory('${rootDirectory.path}/remote_zip_6');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_6/folder_a/file_a',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            '/usr/bin/codesign',
            '--keychain',
            'build.keychain',
            '-f',
            '-s',
            randomString,
            '${rootDirectory.absolute.path}/remote_zip_6/folder_a/file_a',
            '--timestamp',
            '--options=runtime',
            '--entitlements',
            '${rootDirectory.absolute.path}/Entitlements.plist',
          ],
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_6/folder_b/file_b',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            '/usr/bin/codesign',
            '--keychain',
            'build.keychain',
            '-f',
            '-s',
            randomString,
            '${rootDirectory.absolute.path}/remote_zip_6/folder_b/file_b',
            '--timestamp',
            '--options=runtime',
          ],
        ),
      ]);
      await codesignVisitor.visitDirectory(
        directory: testDirectory,
        parentVirtualPath: 'root',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(messages, contains('signing file at path ${rootDirectory.absolute.path}/remote_zip_6/folder_a/file_a'));
      expect(messages, contains('the virtual entitlement path associated with file is root/folder_a/file_a'));
      expect(messages, contains('the decision to sign with entitlement is true'));

      expect(messages, contains('signing file at path ${rootDirectory.absolute.path}/remote_zip_6/folder_b/file_b'));
      expect(messages, contains('the virtual entitlement path associated with file is root/folder_b/file_b'));
      expect(messages, contains('the decision to sign with entitlement is false'));
    });
  });

  group('parse entitlement configs: ', () {
    setUp(() {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor.directoriesVisited.clear();
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
    });

    test('correctly store file paths', () async {
      fileSystem.file('${rootDirectory.absolute.path}/test_entitlement/entitlements.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''file_a
file_b
file_c''',
          mode: FileMode.append,
          encoding: utf8,
        );

      fileSystem.file('${rootDirectory.absolute.path}/test_entitlement/without_entitlements.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''file_d
file_e''',
          mode: FileMode.append,
          encoding: utf8,
        );
      final Set<String> fileWithEntitlements = await codesignVisitor.parseEntitlements(
        fileSystem.directory('${rootDirectory.absolute.path}/test_entitlement'),
        true,
      );
      final Set<String> fileWithoutEntitlements = await codesignVisitor.parseEntitlements(
        fileSystem.directory('${rootDirectory.absolute.path}/test_entitlement'),
        false,
      );
      expect(fileWithEntitlements.length, 3);
      expect(
        fileWithEntitlements,
        containsAll(<String>[
          'file_a',
          'file_b',
          'file_c',
        ]),
      );
      expect(fileWithoutEntitlements.length, 2);
      expect(
        fileWithoutEntitlements,
        containsAll(<String>[
          'file_d',
          'file_e',
        ]),
      );
    });

    test('log warnings when configuration file is missing', () async {
      fileSystem.file('${rootDirectory.absolute.path}/test_entitlement_2/entitlements.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '''file_a
file_b
file_c''',
          mode: FileMode.append,
          encoding: utf8,
        );

      final Set<String> fileWithEntitlements = await codesignVisitor.parseEntitlements(
        fileSystem.directory('${rootDirectory.absolute.path}/test_entitlement_2'),
        true,
      );
      expect(fileWithEntitlements.length, 3);
      expect(
        fileWithEntitlements,
        containsAll(<String>[
          'file_a',
          'file_b',
          'file_c',
        ]),
      );
      await codesignVisitor.parseEntitlements(
        fileSystem.directory('${rootDirectory.absolute.path}/test_entitlement_2'),
        false,
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
        messages,
        contains('${rootDirectory.absolute.path}/test_entitlement_2/without_entitlements.txt not found. '
            'by default, system will assume there is no without_entitlements file. '
            'As a result, no binary will be codesigned.'
            'if this is not intended, please provide them along with the engine artifacts.'),
      );
    });
  });

  group('notarization tests: ', () {
    setUp(() {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor.directoriesVisited.clear();
      codesignVisitor.appSpecificPassword = fakePassword;
      codesignVisitor.codesignAppstoreId = fakeAppleID;
      codesignVisitor.codesignTeamId = fakeTeamID;
    });

    test('successful notarization check returns true', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
          ],
          stdout: '''createdDate: 2021-04-29T01:38:09.498Z
id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
name: OvernightTextEditor_11.6.8.zip
status: Accepted''',
        ),
      ]);

      expect(
        codesignVisitor.checkNotaryJobFinished(uuid),
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
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
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
        () => codesignVisitor.checkNotaryJobFinished(uuid),
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
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
          ],
          stdout: '''createdDate: 2021-04-29T01:38:09.498Z
id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
name: OvernightTextEditor_11.6.8.zip
status: In Progress''',
        ),
      ]);

      expect(
        codesignVisitor.checkNotaryJobFinished(uuid),
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
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
          ],
          stdout: '''createdDate: 2021-04-29T01:38:09.498Z
id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
name: OvernightTextEditor_11.6.8.zip
status: Invalid''',
        ),
      ]);

      expect(
        () => codesignVisitor.checkNotaryJobFinished(uuid),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('upload notary retries upon failure', () async {
      fileSystem.file('${rootDirectory.absolute.path}/temp').createSync();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${rootDirectory.absolute.path}/temp',
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
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
            '${rootDirectory.absolute.path}/temp',
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
          ],
          stdout: '''Successfully uploaded file.
 id: 2efe2717-52ef-43a5-96dc-0797e4ca1041
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
      ]);

      final String uuid = codesignVisitor.uploadZipToNotary(
        fileSystem.file('${rootDirectory.absolute.path}/temp'),
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
            'xcrun notarytool submit ${rootDirectory.absolute.path}/temp '
            '--apple-id <appleID> --password <appSpecificPassword> --team-id <teamID> '
            '--verbose'),
      );
      expect(
        messages,
        contains('Trying again 2 more times...'),
      );
    });

    test('upload notary throws exception if exit code is unnormal', () async {
      fileSystem.file('${rootDirectory.absolute.path}/temp').createSync();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${rootDirectory.absolute.path}/temp',
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
          ],
          stdout: '''Error uploading file.
 Id: something that causes failure
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
          exitCode: -1,
        ),
      ]);

      expect(
        () => codesignVisitor.uploadZipToNotary(
          fileSystem.file('${rootDirectory.absolute.path}/temp'),
          1,
          0,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('upload notary throws exception after 3 default tries', () async {
      fileSystem.file('${rootDirectory.absolute.path}/temp').createSync();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${rootDirectory.absolute.path}/temp',
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
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
            '${rootDirectory.absolute.path}/temp',
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
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
            '${rootDirectory.absolute.path}/temp',
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
          ],
          stdout: '''Error uploading file.
 Id: something that causes failure
 path: /Users/flutter/Desktop/OvernightTextEditor_11.6.8.zip''',
        ),
      ]);

      expect(
        () => codesignVisitor.uploadZipToNotary(
          fileSystem.file('${rootDirectory.absolute.path}/temp'),
          3,
          0,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
        messages,
        contains('The upload to notary service failed after retries, and'
            '  the output format does not match the current notary tool version.'
            ' If after inspecting the output, you believe the process finished '
            'successfully but was not detected, please contact flutter release engineers'),
      );
    });
  });

  group('support optional switches and dryrun :', () {
    setUp(() {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
      );
      codesignVisitor.directoriesVisited.clear();
      codesignVisitor.appSpecificPassword = fakePassword;
      codesignVisitor.codesignAppstoreId = fakeAppleID;
      codesignVisitor.codesignTeamId = fakeTeamID;
      fileSystem.file(codesignAppstoreIDFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(fakeAppleID);
      fileSystem.file(codesignTeamIDFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(fakeTeamID);
      fileSystem.file(appSpecificPasswordFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(fakePassword);
    });

    test('codesign optional switches artifacts when dryrun is true', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'unzip',
            codesignVisitor.inputZipPath,
            '-d',
            '${rootDirectory.absolute.path}/single_artifact',
          ],
          onRun: () => fileSystem
            ..file('${rootDirectory.path}/single_artifact/entitlements.txt').createSync(recursive: true)
            ..file('${rootDirectory.path}/single_artifact/without_entitlements.txt').createSync(recursive: true),
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            codesignVisitor.outputZipPath,
            '.',
            '--include',
            '*',
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            codesignVisitor.outputZipPath,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
          ],
          stdout: 'id: $uuid',
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
          ],
          stdout: 'status: Accepted',
        ),
      ]);
      await codesignVisitor.validateAll();
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
        messages,
        contains('code signing dry run has completed, this is a quick sanity check without'
            'going through the notary service. To run the full codesign process, use --no-dryrun flag.'),
      );
    });

    test('upload optional switch artifacts when dryrun is false', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'unzip',
            codesignVisitor.inputZipPath,
            '-d',
            '${rootDirectory.absolute.path}/single_artifact',
          ],
          onRun: () => fileSystem
            ..file('${rootDirectory.path}/single_artifact/entitlements.txt').createSync(recursive: true)
            ..file('${rootDirectory.path}/single_artifact/without_entitlements.txt').createSync(recursive: true),
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            codesignVisitor.outputZipPath,
            '.',
            '--include',
            '*',
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            codesignVisitor.outputZipPath,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
            '--verbose',
          ],
          stdout: 'id: $uuid',
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'info',
            uuid,
            '--apple-id',
            fakeAppleID,
            '--password',
            fakePassword,
            '--team-id',
            fakeTeamID,
          ],
          stdout: 'status: Accepted',
        ),
      ]);
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        inputZipPath: inputZipPath,
        outputZipPath: outputZipPath,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
        dryrun: false,
      );
      codesignVisitor.appSpecificPassword = fakePassword;
      codesignVisitor.codesignAppstoreId = fakeAppleID;
      codesignVisitor.codesignTeamId = fakeTeamID;
      codesignVisitor.directoriesVisited.clear();
      await codesignVisitor.validateAll();
      final Set<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toSet();
      expect(
        messages,
        contains('Codesign completed. Codesigned zip is located at ${codesignVisitor.outputZipPath}.'
            'If you have uploaded the artifacts back to google cloud storage, please delete'
            ' the folder ${codesignVisitor.outputZipPath} and ${codesignVisitor.inputZipPath}.'),
      );
      expect(
        messages,
        isNot(
          contains('code signing dry run has completed, this is a quick sanity check without'
              'going through the notary service. To run the full codesign process, use --no-dryrun flag.'),
        ),
      );
    });
  });
}
