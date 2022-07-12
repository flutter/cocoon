// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:file/local.dart';
import 'dart:io' as io;

/// Interface for classes that interact with files nested inside of [RemoteZip]s.
abstract class FileVisitor {
  const FileVisitor();

  // TODO(xilaizhang): add back the visit interfaces
}

enum NotaryStatus {
  pending,
  failed,
  succeeded,
}

/// Codesign and notarize all files within a [RemoteArchive].
class FileCodesignVisitor extends FileVisitor {
  FileCodesignVisitor({
    required this.commitHash,
    required this.codesignCertName,
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
    required this.codesignFilepaths,
    this.production = false,
  });

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  Directory? tempDir;
  FileSystem? fileSystem;
  Stdio? stdio;
  ProcessManager? processManager;

  final String commitHash;
  final String codesignCertName;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final bool production;

  // TODO(xilaizhang): add back utitlity in later splits
  Set<String> fileWithEntitlements = <String>{};
  Set<String> fileWithoutEntitlements = <String>{};
  Set<String> fileConsumed = <String>{};
  List<String> codesignFilepaths;

  late final File entitlementsFile;
  late final Directory remoteDownloadsDir;
  late final Directory codesignedZipsDir;

  int _remoteDownloadIndex = 0;
  int get remoteDownloadIndex => _remoteDownloadIndex++;

  static const String _entitlementsFileContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>com.apple.security.cs.allow-jit</key>
        <true/>
        <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
        <true/>
        <key>com.apple.security.cs.allow-dyld-environment-variables</key>
        <true/>
        <key>com.apple.security.network.client</key>
        <true/>
        <key>com.apple.security.network.server</key>
        <true/>
        <key>com.apple.security.cs.disable-library-validation</key>
        <true/>
    </dict>
</plist>
''';

  void initialize() {
    fileSystem ??= LocalFileSystem();
    tempDir ??= fileSystem!.systemTempDirectory.createTempSync('conductor_codesign');
    stdio ??= VerboseStdio(
      stdout: io.stdout,
      stderr: io.stderr,
      stdin: io.stdin,
    );
    processManager ??= LocalProcessManager();
    entitlementsFile = tempDir!.childFile('Entitlements.plist')..writeAsStringSync(_entitlementsFileContents);
    remoteDownloadsDir = tempDir!.childDirectory('downloads')..createSync();
    codesignedZipsDir = tempDir!.childDirectory('codesigned_zips')..createSync();
  }

  Future<void> validateAll() async {
    initialize();

    try {
      await Future.value(null);
      stdio!.printStatus('Codesigned all binaries in ${tempDir!.path}');
    } finally {
      if (production) {
        await tempDir?.delete(recursive: true);
      } else {
        stdio!.printStatus('Codesign test run finished. You can examine files at ${tempDir!.path}');
      }
    }
  }

  Future<void> visitDirectory(Directory directory, String entitlementParentPath) async {
    stdio!.printStatus('visiting directory ${directory.absolute.path}\n');
    final List<FileSystemEntity> entities = await directory.list().toList();
    String childnames = "";
    for (FileSystemEntity entity in entities) {
      if (entity is io.Directory) {
        continue; // TODO(xilaizhang): fill up logic to recursively visit directory
      }
      childnames += ' ${entity.basename}';
    }
    stdio!.printStatus('child files of direcotry are$childnames\n');
  }
}
