// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    super.production = false,
  });

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

    // check on results
    Timer.periodic(
      Duration(milliseconds: 1),
      callback,
    );
    await completer.future;
  }
}

void main() {
  late MemoryFileSystem fileSystem;
  late TestStdio stdio;
  late FakeProcessManager processManager;
  late FakeCodesignContext codesignContext;
  late FakeCodesignVisitor codesignVisitor;
  late Directory tempDir;
  String engineRevision = 'afwe';
  const String revision = 'abcd1234';

  void createRunner({
    String operatingSystem = 'macos',
    List<FakeCommand>? commands,
  }) {
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
        codesignFilepath: revision,
        commitHash: revision);
    //initalize fake variables
    codesignContext.processManager = processManager;
    codesignContext.createTempDirectory();
    tempDir = codesignContext.tempDir!;
    codesignContext.stdio = stdio;

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
        filepaths: revision.split('#'),
        commitHash: revision,
        isNotaryTool: true);

    codesignContext.codesignVisitor = codesignVisitor;
  }

  group('codesign', () {
    test('basic simulation: codesign single folder', () async {
      createRunner();
      processManager.addCommands(<FakeCommand>[
        FakeCommand(command: <String>[
          'gsutil',
          'cp',
          'gs://flutter_infra_release/flutter/$revision/$revision',
          '${tempDir.absolute.path}/downloads/0_$revision',
        ]),
        FakeCommand(command: <String>[
          'unzip',
          '${tempDir.absolute.path}/downloads/0_$revision',
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
          '${tempDir.absolute.path}/codesigned_zips/0_$revision',
          '.',
          '--include',
          '*'
        ]),
        FakeCommand(command: <String>[
          'xcrun',
          'notarytool',
          'submit',
          '${tempDir.absolute.path}/codesigned_zips/0_$revision',
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
    });
  });
}
