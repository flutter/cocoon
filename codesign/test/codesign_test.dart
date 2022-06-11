// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive_io.dart' as package_arch;
import 'package:codesign/codesign.dart' as cs;
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';

import 'package:file/memory.dart';
import 'dart:async';

import './src/common.dart';

class FakeCodesignContext extends cs.CodesignContext {
  FakeCodesignContext(
      {required super.codesignCertName,
      required super.codesignPrimaryBundleId,
      required super.codesignUserName,
      required super.appSpecificPassword,
      required super.codesignAppstoreId,
      required super.codesignTeamId,
      required super.codesignFilepath,
      required super.commitHash,
      super.production = false});

  @override
  bool checkXcodeVersion() => true;
}

/// A fake utitlity class for test environment.
///
/// Overrides file check functions and ls functions, to be based on filenames
/// of input directory.
class FakeUtility extends cs.Utility {
  FakeUtility({required this.tempDir, required this.rootDirectory});

  Directory tempDir;
  String rootDirectory;

  @override
  bool isBinary(String filePath, ProcessManager processManager) {
    String fileName = filePath.split('/').last;
    return fileName == 'binary';
  }

  @override
  FILETYPE checkFileType(String filePath, ProcessManager processManager) {
    String fileType = filePath.split('/').last.split('_').first;
    switch (fileType) {
      case 'binary':
        return FILETYPE.BINARY;
      case 'zip':
        return FILETYPE.ZIP;
      case 'folder':
        return FILETYPE.FOLDER;
    }
    return FILETYPE.FOLDER;
  }

  /// A helper function to list files of a directory under test environment.
  ///
  /// eg: a test directory with the name:
  /// folder_binary_[folder_zip_binary_[folder_binary]]_[folder_zip_binary]
  /// represents the structure of:
  ///
  ///             folder
  ///       __ /    |    \__________________
  ///     /         |                        \
  ///  binary      folder                   folder               -----level 1
  ///           ___/ |  \___               ___/ \___
  ///         /      |       \            /         \
  ///       zip    binary   folder      zip        binary        -----level 2
  ///                         |
  ///                       binary                               -----level 3
  ///
  /// Based on file structures embedded in input directory name, [listFiles]
  /// will list filenames and direcoty names in the current direcotry level,
  /// while maintaining the file structure.
  ///
  /// e.g. on level 1: listFiles will list the directory names as:
  /// [binary, folder_zip_binary_[folder_binary], folder_zip_binary]
  @override
  List<String> listFiles(String filePath, ProcessManager processManager) {
    String folderName = filePath.split('/').last;
    if (folderName == 'remote_zip_0') {
      folderName = rootDirectory;
    }
    int level = 0;
    int index = folderName.indexOf('[');
    if (index == -1) {
      return folderName.substring(folderName.indexOf('_')).split('_').where((String s) => s.trim().isNotEmpty).toList();
    }
    String flatNames = folderName.substring(folderName.indexOf('_') + 1, index);
    List<String> result = flatNames.split('_').where((String s) => s.trim().isNotEmpty).toList();

    int startIndex = -2;

    while (index < folderName.length) {
      if (folderName[index] == '[') {
        if (level == 0) {
          startIndex = index + 1;
        }
        level += 1;
      } else if (folderName[index] == ']') {
        if (level == 1) {
          String childName = folderName.substring(startIndex, index); // substring is [inclusive, exclusive)
          result.add(childName);
        }
        level -= 1;
      }
      index += 1;
    }
    return result;
  }

  @override
  Future<bool> isSymlink(String fileOrFolderPath, ProcessManager processManager) async {
    return false;
  }
}

/// A fake file visitor for testing purpose.
///
/// Upload for notarization is overriden, and the timer to check notarization
/// status is fired instantly.
class FakeCodesignVisitor extends cs.FileCodesignVisitor {
  FakeCodesignVisitor({
    required super.tempDir,
    required super.commitHash,
    required super.processManager,
    required super.codesignCertName,
    required super.codesignPrimaryBundleId,
    required super.codesignUserName,
    required super.appSpecificPassword,
    required super.codesignAppstoreId,
    required super.codesignTeamId,
    required super.stdio,
    required super.isNotaryTool,
    required super.filepaths,
    super.production,
    this.fakeArtifactPath = 'fakeCodesignVisitor_aritifact_path',
    this.fixitCheckMode = false,
  });

  String fakeArtifactPath;
  bool fixitCheckMode;

  @override
  Future<void> validateAll() async {
    List<RemoteZip> codesignZipfiles = filepaths.map((String path) => RemoteZip(path: path)).toList();

    final Iterable<Future<void>> futures = codesignZipfiles.map((RemoteZip archive) {
      final Directory outDir = tempDir.childDirectory('remote_zip_$nextId');
      return archive.visit(this, outDir);
    });
    await Future.wait(
      futures,
      eagerError: true,
    );

    if (!production) {
      stdio.printStatus('\ncode signing simulation has completed, If you intend to upload the artifacts back to'
          ' google cloud storage, please use the --production=true flag when running code signing script.\n'
          'thanks for understanding the security concerns!\n');
    }
  }

  @override
  Future<void> notarize(File file) async {
    final Completer<void> completer = Completer<void>();
    final String uuid = super.uploadZipToNotary(file);

    Future<void> callback(Timer timer) async {
      final bool notaryFinished = checkNotaryJobFinished(uuid);
      if (notaryFinished) {
        timer.cancel();
        stdio.printStatus('successfully notarized ${file.path}');
        completer.complete();
      }
    }

    Timer.periodic(
      Duration(milliseconds: 1),
      callback,
    );
    await completer.future;
  }

  @override
  Future<Set<String>> parseEntitlements(Directory parent, bool entitlements) async {
    return <String>{'$fakeArtifactPath/binary'};
  }

  @override
  Future<void> visitBinaryFile(BinaryFile file, String entitlementParentPath) async {
    if (fixitCheckMode) {
      await super.visitBinaryFile(file, entitlementParentPath); //for exception testings
    }
    stdio.printStatus(
        'the virtual entitlement path associated with file is $entitlementParentPath/${file.path.split('/').last}');
    print('the virtual entitlement path associated with file is $entitlementParentPath/${file.path.split('/').last}');
    return;
  }
}

class ZipCodesignVisitor extends FakeCodesignVisitor {
  ZipCodesignVisitor({
    required super.tempDir,
    required super.commitHash,
    required super.processManager,
    required super.codesignCertName,
    required super.codesignPrimaryBundleId,
    required super.codesignUserName,
    required super.appSpecificPassword,
    required super.codesignAppstoreId,
    required super.codesignTeamId,
    required super.stdio,
    required super.isNotaryTool,
    required super.filepaths,
    super.production = false,
  });

  MemoryFileSystem? fileSystem;

  @override
  Future<package_arch.Archive?> unzip(File inputZip, Directory outDir) async {
    fileSystem!.directory(outDir.path).createSync(recursive: true);
    return null;
  }

  @override
  Future<void> visitEmbeddedZip(EmbeddedZip file, String parentPath, String entitlementParentPath) async {
    String currentFileName = file.path.split('/').last;
    final File localFile = (await validateFileExists(file))!;
    final Directory newDir = tempDir.childDirectory(currentFileName);

    String absoluteDirectoryPath = newDir.absolute.path;
    // the virtual file path is advanced by the name of the embedded zip
    String currentZipEntitlementPath = '$entitlementParentPath/$currentFileName';
    await visitDirectory(absoluteDirectoryPath, currentZipEntitlementPath);
    await localFile.delete();
  }
}

void main() {
  late MemoryFileSystem fileSystem;
  late TestStdio stdio;
  late FakeProcessManager processManager;
  late FakeCodesignContext codesignContext;
  FakeCodesignVisitor? codesignVisitor;
  ZipCodesignVisitor? zipCodesignVisitor;
  late Directory tempDir;
  late FakeUtility utility;
  String engineRevision = 'fake_engine_revision';
  String fakeAritifactPath = 'darwin-x64';
  const String revision = 'abcd1234';

  void createRunner({String operatingSystem = 'macos', List<FakeCommand>? commands, bool zipVisitor = false}) {
    stdio = TestStdio();
    fileSystem = MemoryFileSystem.test();
    // create engine version hash
    fileSystem.file('flutter/bin/internal/engine.version')
      ..createSync(recursive: true)
      ..writeAsStringSync(engineRevision);
    processManager = FakeProcessManager.list(commands ?? <FakeCommand>[]);
    codesignContext = FakeCodesignContext(
        codesignCertName: revision,
        codesignPrimaryBundleId: revision,
        codesignUserName: revision,
        appSpecificPassword: revision,
        codesignAppstoreId: revision,
        codesignTeamId: revision,
        codesignFilepath: fakeAritifactPath,
        commitHash: revision);

    //initalize fake variables
    codesignContext.fileSystem = fileSystem;
    codesignContext.processManager = processManager;
    codesignContext.createTempDirectory();
    tempDir = codesignContext.tempDir!;
    codesignContext.stdio = stdio;

    if (!zipVisitor) {
      codesignVisitor = FakeCodesignVisitor(
          codesignCertName: revision,
          tempDir: codesignContext.tempDir!,
          processManager: processManager,
          stdio: stdio,
          codesignPrimaryBundleId: revision,
          codesignUserName: revision,
          appSpecificPassword: revision,
          codesignAppstoreId: revision,
          codesignTeamId: revision,
          filepaths: fakeAritifactPath.split('#'),
          commitHash: revision,
          isNotaryTool: true);

      codesignContext.codesignVisitor = codesignVisitor;
    } else {
      zipCodesignVisitor = ZipCodesignVisitor(
          codesignCertName: revision,
          tempDir: codesignContext.tempDir!,
          processManager: processManager,
          stdio: stdio,
          codesignPrimaryBundleId: revision,
          codesignUserName: revision,
          appSpecificPassword: revision,
          codesignAppstoreId: revision,
          codesignTeamId: revision,
          filepaths: fakeAritifactPath.split('#'),
          commitHash: revision,
          isNotaryTool: true);

      codesignContext.codesignVisitor = zipCodesignVisitor;
    }
  } // end of create runner

  group('check commands and flags: ', () {
    test('sequence of commands triggered, and check flag protection', () async {
      createRunner();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$fakeAritifactPath',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
        ]),
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
          '-d',
          '${tempDir.absolute.path}/remote_zip_0',
        ]),
        FakeCommand(command: <String>[
          'ls',
          '-alhf',
          '${tempDir.absolute.path}/remote_zip_0',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '.',
          '--include',
          '*'
        ]),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'submit',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '--apple-id',
          revision,
          '--password',
          revision,
          '--team-id',
          revision,
        ], stdout: 'id: abc12345)'),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'info',
          'abc12345',
          '--password',
          revision,
          '--apple-id',
          revision,
          '--team-id',
          revision
        ], stdout: ' status: Accepted'),
      ]);

      await codesignContext.run();
      expect(processManager, hasNoRemainingExpectations);
      expect(stdio.stdout, contains('Codesigned all binaries in ${tempDir.path}'));
      expect(
          stdio.stdout,
          contains(
              ' If you intend to upload the artifacts back to google cloud storage, please use the --production=true flag when running code signing script.'));
    });
  });

  group('file system structure and virtual entitlement paths: ', () {
    test('should throw fix it exception when file paths do not match', () async {
      createRunner();
      utility = FakeUtility(tempDir: tempDir, rootDirectory: 'folder_[folder_binary]');
      codesignVisitor!.utility = utility;
      codesignVisitor!.fakeArtifactPath = fakeAritifactPath;
      codesignVisitor!.fixitCheckMode = true;
      // structure: folder_binary_[folder_binary]
      fileSystem.file('${tempDir.path}/remote_zip_0/folder_binary/binary').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$fakeAritifactPath',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
        ]),
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
          '-d',
          '${tempDir.absolute.path}/remote_zip_0',
        ]),
      ]);

      expect(() => codesignContext.run(), throwsA(isA<Exception>()));
    });

    test('should not throw fix it exception when file names match', () async {
      createRunner();
      utility = FakeUtility(tempDir: tempDir, rootDirectory: 'folder_binary');
      codesignVisitor!.utility = utility;
      codesignVisitor!.fakeArtifactPath = fakeAritifactPath;
      codesignVisitor!.fixitCheckMode = true;
      // structure: folder_binary_[folder_binary]
      fileSystem.file('${tempDir.path}/remote_zip_0/binary').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$fakeAritifactPath',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
        ]),
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
          '-d',
          '${tempDir.absolute.path}/remote_zip_0',
        ]),
        FakeCommand(command: <String>[
          'codesign',
          '-f',
          '-s',
          'abcd1234',
          '/.tmp_rand0/conductor_codesignrand0/remote_zip_0/binary',
          '--timestamp',
          '--options=runtime',
          '--entitlements',
          '/.tmp_rand0/conductor_codesignrand0/Entitlements.plist',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '.',
          '--include',
          '*'
        ]),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'submit',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '--apple-id',
          revision,
          '--password',
          revision,
          '--team-id',
          revision,
        ], stdout: 'id: abc12345)'),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'info',
          'abc12345',
          '--password',
          revision,
          '--apple-id',
          revision,
          '--team-id',
          revision
        ], stdout: ' status: Accepted'),
      ]);

      expect(() => codesignContext.run(), returnsNormally);
    });

    test('recursively visit folder-bianry structure: folder_binary_[folder_binary]', () async {
      createRunner();
      utility = FakeUtility(tempDir: tempDir, rootDirectory: 'folder_binary_[folder_binary]');
      codesignVisitor!.utility = utility;
      // structure: folder_binary_[folder_binary]
      fileSystem.file('${tempDir.path}/remote_zip_0/binary').createSync(recursive: true);
      fileSystem.file('${tempDir.path}/remote_zip_0/folder_binary/binary').createSync(recursive: true);
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$fakeAritifactPath',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
        ]),
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
          '-d',
          '${tempDir.absolute.path}/remote_zip_0',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '.',
          '--include',
          '*'
        ]),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'submit',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '--apple-id',
          revision,
          '--password',
          revision,
          '--team-id',
          revision,
        ], stdout: 'id: abc12345)'),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'info',
          'abc12345',
          '--password',
          revision,
          '--apple-id',
          revision,
          '--team-id',
          revision
        ], stdout: ' status: Accepted'),
      ]);

      await codesignContext.run();
      expect(processManager, hasNoRemainingExpectations);
      expect(stdio.stdout, contains('visiting directory ${tempDir.path}/remote_zip_0'));
      expect(stdio.stdout, contains('files are [binary, folder_binary]'));
      expect(stdio.stdout, contains('visiting directory ${tempDir.path}/remote_zip_0/folder_binary'));
      expect(stdio.stdout, contains('files are [binary]'));
    });

    test('recursively visit folder-zip structure: folder_binary_[zip_binary]_[folder_binary]', () async {
      createRunner(zipVisitor: true);

      zipCodesignVisitor!.fileSystem = fileSystem;
      codesignContext.codesignVisitor = zipCodesignVisitor;

      utility = FakeUtility(tempDir: tempDir, rootDirectory: 'folder_binary_[zip_binary]_[folder_binary]');
      zipCodesignVisitor!.utility = utility;
      // structure: folder_binary_[folder_binary]
      fileSystem.file('${tempDir.path}/remote_zip_0/binary').createSync(recursive: true);
      fileSystem.file('${tempDir.path}/remote_zip_0/zip_binary').createSync(recursive: true);
      fileSystem.file('${tempDir.path}/remote_zip_0/folder_binary/binary').createSync(recursive: true);
      fileSystem
          .file('${tempDir.path}/zip_binary/binary')
          .createSync(recursive: true); //solved: mismatch of filesystem and tempdir filesystem

      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$fakeAritifactPath',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '.',
          '--include',
          '*'
        ]),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'submit',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '--apple-id',
          revision,
          '--password',
          revision,
          '--team-id',
          revision,
        ], stdout: 'id: abc12345)'),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'info',
          'abc12345',
          '--password',
          revision,
          '--apple-id',
          revision,
          '--team-id',
          revision
        ], stdout: ' status: Accepted'),
      ]);

      await codesignContext.run();
      expect(processManager, hasNoRemainingExpectations);
      expect(stdio.stdout, contains('visiting directory ${tempDir.path}/remote_zip_0'));
      expect(stdio.stdout, contains('files are [binary, zip_binary, folder_binary]'));
      //the extracted folder
      expect(stdio.stdout, contains('the virtual entitlement path associated with file is $fakeAritifactPath/binary'));
      expect(stdio.stdout, contains('visiting directory ${tempDir.path}/zip_binary'));
      expect(stdio.stdout, contains('files are [binary]'));
      expect(stdio.stdout,
          contains('the virtual entitlement path associated with file is $fakeAritifactPath/zip_binary/binary'));
      expect(stdio.stdout, contains('visiting directory ${tempDir.path}/remote_zip_0/folder_binary'));
      expect(stdio.stdout, contains('files are [binary]'));
      expect(stdio.stdout,
          contains('the virtual entitlement path associated with file is $fakeAritifactPath/folder_binary/binary'));
      expect(stdio.stdout, contains('successfully notarized ${tempDir.path}/codesigned_zips/0_$fakeAritifactPath'));
    });

    test('complex, nested and mixed file structure: folder_[zip_[folder_[zip_binary]]]_[folder_[zip_binary]_binary]',
        () async {
      createRunner(zipVisitor: true);

      zipCodesignVisitor!.fileSystem = fileSystem;
      codesignContext.codesignVisitor = zipCodesignVisitor;

      utility = FakeUtility(
          tempDir: tempDir, rootDirectory: 'folder_[zip_[folder_[zip_binary]]]_[folder_binary_[zip_binary]]');
      zipCodesignVisitor!.utility = utility;
      // structure: folder_[zip_[folder_[zip_binary]]]_[folder_[zip_binary]_binary]
      fileSystem.file('${tempDir.path}/remote_zip_0/zip_[folder_[zip_binary]]').createSync(recursive: true);
      fileSystem
          .file('${tempDir.path}/zip_[folder_[zip_binary]]/folder_[zip_binary]/zip_binary')
          .createSync(recursive: true);
      fileSystem.file('${tempDir.path}/zip_binary/binary').createSync(recursive: true);

      fileSystem.file('${tempDir.path}/remote_zip_0/folder_binary_[zip_binary]/zip_binary').createSync(recursive: true);

      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$fakeAritifactPath',
          '${tempDir.absolute.path}/downloads/0_$fakeAritifactPath',
        ]),
        FakeCommand(command: <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '.',
          '--include',
          '*'
        ]),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'submit',
          '${tempDir.absolute.path}/codesigned_zips/0_$fakeAritifactPath',
          '--apple-id',
          revision,
          '--password',
          revision,
          '--team-id',
          revision,
        ], stdout: 'id: abc12345)'),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'info',
          'abc12345',
          '--password',
          revision,
          '--apple-id',
          revision,
          '--team-id',
          revision
        ], stdout: ' status: Accepted'),
      ]);

      await codesignContext.run();
      expect(processManager, hasNoRemainingExpectations);
      expect(
          stdio.stdout,
          contains(
              'the virtual entitlement path associated with file is $fakeAritifactPath/zip_[folder_[zip_binary]]/folder_[zip_binary]/zip_binary/binary'));
      expect(
        stdio.stdout,
        contains(
            'the virtual entitlement path associated with file is $fakeAritifactPath/folder_binary_[zip_binary]/binary'),
      );
      expect(
        stdio.stdout,
        contains(
            'the virtual entitlement path associated with file is $fakeAritifactPath/folder_binary_[zip_binary]/zip_binary/binary'),
      );
    });
  });
}
