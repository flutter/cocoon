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
  final MemoryFileSystem fileSystem = MemoryFileSystem.test();
  const List<String> fakeFilepaths = <String>['a.zip', 'b.zip', 'c.zip'];
  final Directory rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');

  late FakeProcessManager processManager;
  late GoogleCloudStorage googleCloudStorage;
  late cs.FileCodesignVisitor codesignVisitor;
  final List<LogRecord> records = <LogRecord>[];

  group('test google cloud storage and processRemoteZip workflow', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
        commitHash: randomString,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        codesignUserName: randomString,
        appSpecificPassword: randomString,
        codesignAppstoreId: randomString,
        codesignTeamId: randomString,
        codesignFilepaths: fakeFilepaths,
        commitHash: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
      );
      codesignVisitor.directoriesVisited.clear();
      records.clear();
      log.onRecord.listen((LogRecord record) => records.add(record));
    });

    test('download fails and upload succeeds throws exception', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            randomString,
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$randomString',
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.uploadEngineArtifact(
          remotePath: randomString,
          localPath: randomString,
        ),
        returnsNormally,
      );
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$randomString',
            randomString,
          ],
          exitCode: -1,
        ),
      ]);
      expect(
        () => googleCloudStorage.downloadEngineArtifact(
          remotePath: randomString,
          localPath: randomString,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('download succeeds and upload fails throws exception', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$randomString',
            randomString,
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.downloadEngineArtifact(
          remotePath: randomString,
          localPath: randomString,
        ),
        returnsNormally,
      );
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            randomString,
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$randomString',
          ],
          exitCode: -1,
        ),
      ]);
      expect(
        () => googleCloudStorage.uploadEngineArtifact(
          remotePath: randomString,
          localPath: randomString,
        ),
        throwsA(
          isA<CodesignException>(),
        ),
      );
    });

    test('download succeeds and upload succeeds returns normally', () async {
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$randomString',
            randomString,
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.downloadEngineArtifact(
          remotePath: randomString,
          localPath: randomString,
        ),
        returnsNormally,
      );
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            randomString,
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$randomString',
          ],
          exitCode: 0,
        ),
      ]);
      expect(
        () => googleCloudStorage.uploadEngineArtifact(
          remotePath: randomString,
          localPath: randomString,
        ),
        returnsNormally,
      );
    });

    test('procesRemotezip triggers correct workflow', () async {
      final String zipFileName = '${rootDirectory.path}/remote_zip_4/folder_1/zip_1';
      fileSystem.file(zipFileName).createSync(recursive: true);
      const String artifactFilePath = 'my/artifacts.zip';
      final String artifactBaseName = rootDirectory.fileSystem.path.basename(artifactFilePath);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'gsutil',
            'cp',
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$artifactFilePath',
            '${rootDirectory.absolute.path}/downloads/${artifactFilePath.hashCode}_$artifactBaseName',
          ],
        ),
        FakeCommand(
          command: <String>[
            'unzip',
            '${rootDirectory.absolute.path}/downloads/${artifactFilePath.hashCode}_$artifactBaseName',
            '-d',
            '${rootDirectory.absolute.path}/remote_zip_${artifactFilePath.hashCode}_$artifactBaseName',
          ],
          onRun: () => fileSystem
            ..file('${rootDirectory.path}/remote_zip_${artifactFilePath.hashCode}_$artifactBaseName/entitlements.txt')
                .createSync(recursive: true)
            ..file('${rootDirectory.path}/remote_zip_${artifactFilePath.hashCode}_$artifactBaseName/without_entitlements.txt')
                .createSync(recursive: true),
        ),
        FakeCommand(
          command: <String>[
            'zip',
            '--symlinks',
            '--recurse-paths',
            '${rootDirectory.absolute.path}/codesigned_zips/${artifactFilePath.hashCode}_$artifactBaseName',
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
            '${rootDirectory.absolute.path}/codesigned_zips/${artifactFilePath.hashCode}_$artifactBaseName',
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
            '${rootDirectory.absolute.path}/codesigned_zips/${artifactFilePath.hashCode}_$artifactBaseName',
            '${googleCloudStorage.gsCloudBaseUrl}/flutter/$randomString/$artifactFilePath',
          ],
        ),
      ]);

      await codesignVisitor.processRemoteZip(
        artifactFilePath: artifactFilePath,
        parentDirectory: rootDirectory.childDirectory('remote_zip_${artifactFilePath.hashCode}_$artifactBaseName'),
      );
      final Set<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toSet();
      expect(
        messages,
        contains(
            'The downloaded file is unzipped from ${rootDirectory.absolute.path}/downloads/${artifactFilePath.hashCode}_$artifactBaseName to ${rootDirectory.path}/remote_zip_${artifactFilePath.hashCode}_$artifactBaseName'),
      );
      expect(
        messages,
        contains(
            'Visiting directory ${rootDirectory.absolute.path}/remote_zip_${artifactFilePath.hashCode}_$artifactBaseName'),
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
            'uploading xcrun notarytool submit ${rootDirectory.absolute.path}/codesigned_zips/${artifactFilePath.hashCode}_$artifactBaseName --apple-id $randomString --password $randomString --team-id $randomString'),
      );
      expect(
        messages,
        contains(
            'RequestUUID for ${rootDirectory.absolute.path}/codesigned_zips/${artifactFilePath.hashCode}_$artifactBaseName is: $randomString'),
      );
      expect(
        messages,
        contains(
            'checking notary status with xcrun notarytool info $randomString --password $randomString --apple-id $randomString --team-id $randomString'),
      );
      expect(
        messages,
        contains(
            'successfully notarized ${rootDirectory.absolute.path}/codesigned_zips/${artifactFilePath.hashCode}_$artifactBaseName'),
      );
    });
  });

  group('visit directory/zip api calls: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
        commitHash: randomString,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        codesignUserName: randomString,
        appSpecificPassword: randomString,
        codesignAppstoreId: randomString,
        codesignTeamId: randomString,
        codesignFilepaths: fakeFilepaths,
        commitHash: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        processManager: processManager,
        rootDirectory: rootDirectory,
        notarizationTimerDuration: const Duration(seconds: 0),
      );
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
        entitlementParentPath: 'a.zip',
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
        entitlementParentPath: 'a.zip',
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
              ..file('${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}/file_2').createSync(recursive: true)),
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
        entitlementParentPath: 'a.zip',
      );
      final List<String> messages = records
          .where((LogRecord record) => record.level == Level.INFO)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
          messages,
          contains(
              'The downloaded file is unzipped from ${rootDirectory.path}/remote_zip_2/zip_1 to ${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}'));
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
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${rootDirectory.absolute.path}/remote_zip_4/folder_1/zip_1',
          '.',
          '--include',
          '*'
        ]),
      ]);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${rootDirectory.path}/remote_zip_4'),
        entitlementParentPath: 'a.zip',
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
              'The downloaded file is unzipped from ${rootDirectory.path}/remote_zip_4/folder_1/zip_1 to ${rootDirectory.path}/embedded_zip_${zipFileName.hashCode}'));
      expect(
          messages, contains('Visiting directory ${rootDirectory.absolute.path}/embedded_zip_${zipFileName.hashCode}'));
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
        entitlementParentPath: 'a.zip',
      );
      List<String> warnings = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(warnings, isEmpty);

      await codesignVisitor.visitDirectory(
        directory: fileSystem.directory('${rootDirectory.path}/parent_1'),
        entitlementParentPath: 'a.zip',
      );
      warnings = records
          .where((LogRecord record) => record.level == Level.WARNING)
          .map((LogRecord record) => record.message)
          .toList();
      expect(
          warnings,
          contains(
              'Warning! You are visiting a directory that has been visited before, the directory is ${rootDirectory.path}/parent_1/child_1'));
    });

    test('visitBinary codesigns binary with / without entitlement', () async {
      codesignVisitor.fileWithEntitlements = <String>{'root/file_a'};
      codesignVisitor.fileWithoutEntitlements = <String>{'root/file_b'};
      fileSystem
        ..file('${rootDirectory.path}/remote_zip_5/file_a').createSync(recursive: true)
        ..file('${rootDirectory.path}/remote_zip_5/file_b').createSync(recursive: true);
      final Directory testDirectory = fileSystem.directory('${rootDirectory.path}/remote_zip_5');
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'file',
            '--mime-type',
            '-b',
            '${rootDirectory.absolute.path}/remote_zip_5/file_a',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '-f',
            '-s',
            randomString,
            '${rootDirectory.absolute.path}/remote_zip_5/file_a',
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
            '${rootDirectory.absolute.path}/remote_zip_5/file_b',
          ],
          stdout: 'application/x-mach-binary',
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '-f',
            '-s',
            randomString,
            '${rootDirectory.absolute.path}/remote_zip_5/file_b',
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
      expect(messages, contains('signing file at path ${rootDirectory.absolute.path}/remote_zip_5/file_a'));
      expect(messages, contains('the virtual entitlement path associated with file is root/file_a'));
      expect(messages, contains('the decision to sign with entitlement is true'));

      expect(messages, contains('signing file at path ${rootDirectory.absolute.path}/remote_zip_5/file_b'));
      expect(messages, contains('the virtual entitlement path associated with file is root/file_b'));
      expect(messages, contains('the decision to sign with entitlement is false'));
    });
  });

  group('parse entitlement configs: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
        commitHash: randomString,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        codesignUserName: randomString,
        appSpecificPassword: randomString,
        codesignAppstoreId: randomString,
        codesignTeamId: randomString,
        codesignFilepaths: fakeFilepaths,
        commitHash: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        processManager: processManager,
        rootDirectory: rootDirectory,
      );
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
          ]));
      expect(
          () => codesignVisitor.parseEntitlements(
                fileSystem.directory('/Users/xilaizhang/Desktop/test_entitlement_2'),
                false,
              ),
          throwsA(
            isA<CodesignException>(),
          ));
    });
  });

  group('notarization tests: ', () {
    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      googleCloudStorage = GoogleCloudStorage(
        processManager: processManager,
        rootDirectory: rootDirectory,
        commitHash: randomString,
      );
      codesignVisitor = cs.FileCodesignVisitor(
        codesignCertName: randomString,
        codesignUserName: randomString,
        appSpecificPassword: randomString,
        codesignAppstoreId: randomString,
        codesignTeamId: randomString,
        codesignFilepaths: fakeFilepaths,
        commitHash: randomString,
        googleCloudStorage: googleCloudStorage,
        fileSystem: fileSystem,
        processManager: processManager,
        rootDirectory: rootDirectory,
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
}
