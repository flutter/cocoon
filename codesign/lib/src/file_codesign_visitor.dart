// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:logging/logging.dart';
import 'dart:io' as io;

/// Statuses reported by Apple's Notary Server.
///
/// See more:
///   * https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
enum NotaryStatus {
  pending,
  failed,
  succeeded,
}

/// Visit a [Directory] type while examining the file system extracted from an
/// artifact.
Future<void> visitDirectory(Directory directory, String entitlementParentPath, Logger logger) async {
  logger.info('visiting directory ${directory.absolute.path}\n');
  final List<FileSystemEntity> entities = await directory.list().toList();
  for (FileSystemEntity entity in entities) {
    if (entity is io.Directory) {
      await visitDirectory(directory.childDirectory(entity.basename), entitlementParentPath, logger);
    }
    logger.info('child file of direcotry ${directory.basename} is ${entity.basename}\n');
  }
}

/// Codesign and notarize all files within a [RemoteArchive].
class FileCodesignVisitor {
  FileCodesignVisitor({
    required this.commitHash,
    required this.codesignCertName,
    required this.codesignUserName,
    required this.appSpecificPassword,
    required this.codesignAppstoreId,
    required this.codesignTeamId,
    required this.codesignFilepaths,
    required this.fileSystem,
    required this.tempDir,
    required this.logger,
    required this.processManager,
    required this.visitDirectory,
    this.production = false,
  });

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  final Directory tempDir;
  final FileSystem fileSystem;
  final Logger logger;
  final ProcessManager processManager;

  final String commitHash;
  final String codesignCertName;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final bool production;

  final Function visitDirectory;

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

  void _initialize() {
    entitlementsFile = tempDir.childFile('Entitlements.plist')..writeAsStringSync(_entitlementsFileContents);
    remoteDownloadsDir = tempDir.childDirectory('downloads')..createSync();
    codesignedZipsDir = tempDir.childDirectory('codesigned_zips')..createSync();
  }

  /// The entrance point of examining and code signing an engine artifact.
  Future<void> validateAll() async {
    _initialize();

    await Future.value(null);
    logger.info('Codesigned all binaries in ${tempDir.path}');

    await tempDir.delete(recursive: true);
  }
}
