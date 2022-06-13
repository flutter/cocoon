// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';
import 'package:archive/archive_io.dart' as package_arch;
import 'package:process/process.dart';

/// Interface for classes that interact with files nested inside of [RemoteZip]s.
abstract class FileVisitor {
  const FileVisitor();

  Future<void> visitEmbeddedZip(EmbeddedZip file, String parent, String entitlementParentPath);
  Future<void> visitRemoteZip(RemoteZip file, Directory parent);
  Future<void> visitBinaryFile(BinaryFile file, String entitlementParentPath);
}

enum NotaryStatus {
  pending,
  failed,
  succeeded,
}

/// Codesign and notarize all files within a [RemoteArchive].
class FileCodesignVisitor extends FileVisitor {
  FileCodesignVisitor(
      {required this.tempDir,
      required this.commitHash,
      required this.processManager,
      required this.codesignCertName,
      required this.codesignPrimaryBundleId,
      required this.codesignUserName,
      required this.appSpecificPassword,
      required this.codesignAppstoreId,
      required this.codesignTeamId,
      required this.stdio,
      required this.isNotaryTool,
      required this.filepaths,
      this.production = false});

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  final Directory tempDir;

  final String commitHash;
  final ProcessManager processManager;
  final String codesignCertName;
  final String codesignPrimaryBundleId;
  final String codesignUserName;
  final String appSpecificPassword;
  final String codesignAppstoreId;
  final String codesignTeamId;
  final Stdio stdio;
  final bool isNotaryTool;
  final bool production;
  final List<String> filepaths;
  // Utility utility = Utility();
  // TODO(xilaizhang): add back utitlity in later splits
  Set<String>? fileWithEntitlements;
  Set<String>? fileWithoutEntitlements;
  Set<String> fileConsumed = <String>{};

  late final File entitlementsFile = tempDir.childFile('Entitlements.plist')
    ..writeAsStringSync(_entitlementsFileContents);

  late final Directory remoteDownloadsDir = tempDir.childDirectory('downloads')..createSync();
  late final Directory codesignedZipsDir = tempDir.childDirectory('codesigned_zips')..createSync();

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
  Future<void> validateAll() async {
    return Future.value(null);
  }

  @override
  Future<void> visitBinaryFile(BinaryFile file, String entitlementParentPath) {
    throw UnimplementedError();
  }

  @override
  Future<void> visitEmbeddedZip(EmbeddedZip file, String parent, String entitlementParentPath) {
    throw UnimplementedError();
  }

  @override
  Future<void> visitRemoteZip(RemoteZip file, Directory parent) {
    throw UnimplementedError();
  }
}
