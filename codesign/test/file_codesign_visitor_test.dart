// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:codesign/codesign.dart' as cs;
import 'package:codesign/src/google_cloud_storage.dart';
import 'package:codesign/src/log.dart';
import 'package:codesign/src/utils.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import './src/fake_process_manager.dart';

void main() {
  const String randomString = 'abcd1234';
  const String appSpecificPasswordFilePath = '/tmp/passwords.txt';
  const String codesignAppstoreIDFilePath = '/tmp/appID.txt';
  const String codesignTeamIDFilePath = '/tmp/teamID.txt';
  final MemoryFileSystem fileSystem = MemoryFileSystem.test();
  final List<LogRecord> records = <LogRecord>[];

  late FakeProcessManager processManager;
  late GoogleCloudStorage googleCloudStorage;
  late cs.FileCodesignVisitor codesignVisitor;

  Directory rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');

  group('test reading in passwords: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        gcsDownloadPath: 'gs://flutter/$randomString/$randomString',
        gcsUploadPath: 'gs://flutter/$randomString/$randomString',
        notarizationTimerDuration: const Duration(seconds: 0),
        dryrun: false,
      );
      codesignVisitor.directoriesVisited.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('incorrectly formatted password file throws exception', () async {
      fileSystem.file(appSpecificPasswordFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'file_a',
          mode: FileMode.write,
          encoding: utf8,
        );

      expect(
        () async {
          await codesignVisitor.readPassword(appSpecificPasswordFilePath);
          fileSystem.file(appSpecificPasswordFilePath).deleteSync();
        },
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('unknown password name throws an exception', () async {
      fileSystem.file(codesignTeamIDFilePath)
        ..createSync(recursive: true, exclusive: true)
        ..writeAsStringSync(
          'dart:dart',
          mode: FileMode.write,
          encoding: utf8,
        );

      expect(
        () async {
          await codesignVisitor.readPassword(codesignTeamIDFilePath);
          await fileSystem.file(codesignTeamIDFilePath).delete();
        },
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('lacking required passwords throws exception', () async {
      codesignVisitor.availablePasswords = {
        'CODESIGN_APPSTORE_ID': '',
        'CODESIGN_TEAM_ID': '',
        'APP-SPECIFIC-PASSWORD': ''
      };
      fileSystem.file(codesignAppstoreIDFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'CODESIGN_APPSTORE_ID:123',
          mode: FileMode.write,
          encoding: utf8,
        );

      expect(
        () async {
          await codesignVisitor.validateAll();
          await fileSystem.file(codesignAppstoreIDFilePath).delete();
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
          'APP_SPECIFIC_PASSWORD:123',
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
      expect(joinEntitlementPaths("", randomString), randomString);
    });

    test('concat with slash', () async {
      expect(joinEntitlementPaths(randomString, randomString), '$randomString/$randomString');
    });
  });

  group('test google cloud storage and processRemoteZip workflow', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        gcsDownloadPath: 'gs://flutter/$randomString/$randomString',
        gcsUploadPath: 'gs://flutter/$randomString/$randomString',
        notarizationTimerDuration: const Duration(seconds: 0),
        dryrun: false,
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.directoriesVisited.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('download fails and upload succeeds throws exception', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            randomString,
            'gs://flutter/$randomString/$randomString',
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.uploadEngineArtifact(
          from: randomString,
          destination: codesignVisitor.gcsUploadPath,
        ),
        returnsNormally,
      );
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            'gs://flutter/$randomString/$randomString',
            randomString,
          ],
          exitCode: -1,
        ),
      ]);
      expect(
        () => googleCloudStorage.downloadEngineArtifact(
          destination: randomString,
          from: codesignVisitor.gcsDownloadPath,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('download succeeds and upload fails throws exception', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            'gs://flutter/$randomString/$randomString',
            randomString,
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.downloadEngineArtifact(
          destination: randomString,
          from: codesignVisitor.gcsDownloadPath,
        ),
        returnsNormally,
      );
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            randomString,
            'gs://flutter/$randomString/$randomString',
          ],
          exitCode: -1,
        ),
      ]);
      expect(
        () => googleCloudStorage.uploadEngineArtifact(
          from: randomString,
          destination: codesignVisitor.gcsUploadPath,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('download succeeds and upload succeeds returns normally', () async {
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            'gs://flutter/$randomString/$randomString',
            randomString,
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.downloadEngineArtifact(
          destination: randomString,
          from: codesignVisitor.gcsDownloadPath,
        ),
        returnsNormally,
      );
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            randomString,
            'gs://flutter/$randomString/$randomString',
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.uploadEngineArtifact(
          from: randomString,
          destination: codesignVisitor.gcsUploadPath,
        ),
        returnsNormally,
      );
    });

    test('procesRemotezip triggers correct workflow', () async {
      final String zipFileName = '${rootDirectory.path}/remote_zip_4/folder_1/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            'gs://flutter/$randomString/$randomString',
            '${rootDirectory.absolute.path}/downloads/remote_artifact.zip',
          ],
        ),
        FakeCommand(
          command: <String>[
            'unzip',
            '${rootDirectory.absolute.path}/downloads/remote_artifact.zip',
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
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
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
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: 'id: $randomString',
        ),
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
          stdout: 'status: Accepted',
        ),
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
            'gs://flutter/$randomString/$randomString',
          ],
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
          'The downloaded file is unzipped from ${rootDirectory.absolute.path}/downloads/remote_artifact.zip to ${rootDirectory.path}/single_artifact',
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
          'uploading xcrun notarytool submit ${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip --apple-id $randomString --password $randomString --team-id $randomString',
        ),
      );
      expect(
        messages,
        contains(
          'RequestUUID for ${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip is: $randomString',
        ),
      );
      expect(
        messages,
        contains(
          'checking notary status with xcrun notarytool info $randomString --password $randomString --apple-id $randomString --team-id $randomString',
        ),
      );
      expect(
        messages,
        contains('successfully notarized ${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip'),
      );
    });
  });

  group('visit directory/zip api calls: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        gcsDownloadPath: 'gs://flutter/$randomString/FILEPATH',
        gcsUploadPath: 'gs://flutter/$randomString/FILEPATH',
        notarizationTimerDuration: Duration.zero,
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.directoriesVisited.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
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
            '*'
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
            '*'
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

    test('visitBinary codesigns binary with / without entitlement', () async {
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        gcsDownloadPath: 'flutter/$randomString/FILEPATH',
        gcsUploadPath: 'flutter/$randomString/FILEPATH',
        dryrun: false,
        notarizationTimerDuration: const Duration(seconds: 0),
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.fileWithEntitlements = <String>{'root/folder_a/file_a'};
      codesignVisitor.fileWithoutEntitlements = <String>{'root/folder_b/file_b'};
      fileSystem
        ..file('${rootDirectory.path}/remote_zip_5/folder_a/file_a').createSync(recursive: true)
        ..file('${rootDirectory.path}/remote_zip_5/folder_b/file_b').createSync(recursive: true);
      final Directory testDirectory = fileSystem.directory('${rootDirectory.path}/remote_zip_5');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_5/folder_a/file_a',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '-f',
            '-s',
            randomString,
            '${rootDirectory.absolute.path}/remote_zip_5/folder_a/file_a',
            '--timestamp',
            '--options=runtime',
            '--entitlements',
            '${rootDirectory.absolute.path}/Entitlements.plist'
          ],
        ),
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_5/folder_b/file_b',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '-f',
            '-s',
            randomString,
            '${rootDirectory.absolute.path}/remote_zip_5/folder_b/file_b',
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
      expect(messages, contains('signing file at path ${rootDirectory.absolute.path}/remote_zip_5/folder_a/file_a'));
      expect(messages, contains('the virtual entitlement path associated with file is root/folder_a/file_a'));
      expect(messages, contains('the decision to sign with entitlement is true'));

      expect(messages, contains('signing file at path ${rootDirectory.absolute.path}/remote_zip_5/folder_b/file_b'));
      expect(messages, contains('the virtual entitlement path associated with file is root/folder_b/file_b'));
      expect(messages, contains('the decision to sign with entitlement is false'));
    });
  });

  group('parse entitlement configs: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        gcsDownloadPath: 'flutter/$randomString/FILEPATH',
        gcsUploadPath: 'flutter/$randomString/FILEPATH',
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.directoriesVisited.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
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

    test('throw exception when configuration file is missing', () async {
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
      expect(
        () => codesignVisitor.parseEntitlements(
          fileSystem.directory('/Users/xilaizhang/Desktop/test_entitlement_2'),
          false,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });
  });

  group('notarization tests: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        gcsDownloadPath: 'flutter/$randomString/FILEPATH',
        gcsUploadPath: 'flutter/$randomString/FILEPATH',
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
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
      fileSystem.file('${rootDirectory.absolute.path}/temp').createSync();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${rootDirectory.absolute.path}/temp',
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
            '${rootDirectory.absolute.path}/temp',
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
            '--apple-id abcd1234 --password abcd1234 --team-id abcd1234'),
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
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
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
            '${rootDirectory.absolute.path}/temp',
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
            '${rootDirectory.absolute.path}/temp',
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
      rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        gcsDownloadPath: 'gs://ios-usb-dependencies/unsigned/libimobiledevice/$randomString/libimobiledevice.zip',
        gcsUploadPath: 'gs://ios-usb-dependencies/libimobiledevice/$randomString/libimobiledevice.zip',
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.directoriesVisited.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
      fileSystem.file(codesignAppstoreIDFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('CODESIGN_APPSTORE_ID:$randomString');
      fileSystem.file(codesignTeamIDFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('CODESIGN_TEAM_ID:$randomString');
      fileSystem.file(appSpecificPasswordFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('APP_SPECIFIC_PASSWORD:$randomString');
    });

    test('codesign optional switches artifacts when dryrun is false', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            'gs://ios-usb-dependencies/unsigned/libimobiledevice/abcd1234/libimobiledevice.zip',
            '${rootDirectory.absolute.path}/downloads/remote_artifact.zip',
          ],
        ),
        FakeCommand(
          command: <String>[
            'unzip',
            '${rootDirectory.absolute.path}/downloads/remote_artifact.zip',
            '-d',
            '${rootDirectory.absolute.path}/single_artifact'
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
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
            '.',
            '--include',
            '*'
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${rootDirectory.absolute.path}/codesigned_zips/remote_zip',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: 'id: $randomString',
        ),
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
        contains('code signing dry run has completed, If you intend to upload the artifacts back to'
            ' google cloud storage, please use the --dryrun=false flag to run code signing script.'),
      );
      rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
    });

    test('upload optional switch artifacts when dryrun is true', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            'gs://ios-usb-dependencies/unsigned/libimobiledevice/abcd1234/libimobiledevice.zip',
            '${rootDirectory.absolute.path}/downloads/remote_artifact.zip',
          ],
        ),
        FakeCommand(
          command: <String>[
            'unzip',
            '${rootDirectory.absolute.path}/downloads/remote_artifact.zip',
            '-d',
            '${rootDirectory.absolute.path}/single_artifact'
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
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
            '.',
            '--include',
            '*'
          ],
        ),
        FakeCommand(
          command: <String>[
            'xcrun',
            'notarytool',
            'submit',
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
            '--apple-id',
            randomString,
            '--password',
            randomString,
            '--team-id',
            randomString,
          ],
          stdout: 'id: $randomString',
        ),
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
          stdout: 'status: Accepted',
        ),
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            '${rootDirectory.absolute.path}/codesigned_zips/remote_artifact.zip',
            'gs://ios-usb-dependencies/libimobiledevice/$randomString/libimobiledevice.zip',
          ],
        ),
      ]);
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        gcsDownloadPath: 'gs://ios-usb-dependencies/unsigned/libimobiledevice/$randomString/libimobiledevice.zip',
        gcsUploadPath: 'gs://ios-usb-dependencies/libimobiledevice/$randomString/libimobiledevice.zip',
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        appSpecificPasswordFilePath: appSpecificPasswordFilePath,
        codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
        codesignTeamIDFilePath: codesignTeamIDFilePath,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
        dryrun: false,
      );
      codesignVisitor.appSpecificPassword = randomString;
      codesignVisitor.codesignAppstoreId = randomString;
      codesignVisitor.codesignTeamId = randomString;
      codesignVisitor.directoriesVisited.clear();
      await codesignVisitor.validateAll();
      final Set<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toSet();
      expect(
        messages,
        isNot(
          contains('code signing dry run has completed, If you intend to upload the artifacts back to'
              ' google cloud storage, please use the --dryrun=false flag to run code signing script.'),
        ),
      );
      expect(
        messages,
        contains('Codesigned all binaries in ${rootDirectory.path}'),
      );
      rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
    });
  });
}
