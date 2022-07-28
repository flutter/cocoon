// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:logging/logging.dart';
import 'utils.dart';
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

final Logger log = Logger('codesign');

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
    required this.processManager,
    this.production = false,
  });

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  final Directory tempDir;
  final FileSystem fileSystem;
  final ProcessManager processManager;

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
  Set<String> directoriesVisited = <String>{};
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
    log.info('Codesigned all binaries in ${tempDir.path}');

    await tempDir.delete(recursive: true);
  }

  /// Visit a [Directory] type while examining the file system extracted from an artifact.
  Future<void> visitDirectory({
    required Directory directory,
    required String entitlementParentPath,
  }) async {
    log.info('Visiting directory ${directory.absolute.path}\n');
    if (directoriesVisited.contains(directory.absolute.path)) {
      throw CodesignException(
        'Error! You are visiting a directory that has been visited before, the directory is ${directory.absolute.path}',
      );
    }
    directoriesVisited.add(directory.absolute.path);
    final List<FileSystemEntity> entities = await directory.list().toList();
    for (FileSystemEntity entity in entities) {
      if (entity is io.Directory) {
        await visitDirectory(
          directory: directory.childDirectory(entity.basename),
          entitlementParentPath: entitlementParentPath,
        );
        continue;
      }
      final FileType childType = getFileType(
        entity.absolute.path,
        processManager,
      );
      if (childType == FileType.zip) {
        await visitEmbeddedZip(
          zipEntity: entity,
          entitlementParentPath: entitlementParentPath,
        );
      }
      log.info('Child file of direcotry ${directory.basename} is ${entity.basename}\n');
    }
  }

  /// Unzip an [EmbeddedZip] and visit its children.
  Future<void> visitEmbeddedZip({
    required FileSystemEntity zipEntity,
    required String entitlementParentPath,
  }) async {
    log.info('This embedded file is ${zipEntity.path} and entilementParentPath is $entitlementParentPath\n');
    final String currentFileName = zipEntity.path.split('/').last;
    final Directory newDir = tempDir.childDirectory('embedded_zip_$nextId');
    await unzip(
      inputZip: zipEntity,
      outDir: newDir,
      processManager: processManager,
    );

    // the virtual file path is advanced by the name of the embedded zip
    final String currentZipEntitlementPath = '$entitlementParentPath/$currentFileName';
    await visitDirectory(
      directory: newDir,
      entitlementParentPath: currentZipEntitlementPath,
    );
    await zipEntity.delete();
    await zip(
      inputDir: newDir,
      outputZip: zipEntity,
      processManager: processManager,
    );
  }
}
