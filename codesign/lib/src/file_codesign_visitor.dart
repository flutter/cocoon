// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:process/process.dart';

import 'log.dart';
import 'utils.dart';

/// Statuses reported by Apple's Notary Server.
///
/// See more:
///   * https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
enum NotaryStatus {
  pending,
  failed,
  succeeded,
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
    required this.processManager,
    this.production = false,
  }) {
    entitlementsFile = tempDir.childFile('Entitlements.plist')..writeAsStringSync(_entitlementsFileContents);
    remoteDownloadsDir = tempDir.childDirectory('downloads')..createSync();
    codesignedZipsDir = tempDir.childDirectory('codesigned_zips')..createSync();
  }

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
  static const Duration _notarizationTimerDuration = Duration(seconds: 45);
  static final RegExp _notarytoolStatusCheckPattern = RegExp(r'[ ]*status: ([a-zA-z ]+)');
  static final RegExp _notarytoolRequestPattern = RegExp(r'id: ([a-z0-9-]+)');

  static const String fixItInstructions = '''
Codesign test failed.

We compared binary files in engine artifacts with those listed in
entitlement.txt and withoutEntitlements.txt, and the binary files do not match.
*entitlements.txt is the configuartion file encoded in engine artifact zip,
built by BUILD.gn and Ninja, to detail the list of entitlement files.
Either an expected file was not found in *entitlements.txt, or an unexpected
file was found in entitlements.txt.

This usually happens during an engine roll.
If this is a valid change, then BUILD.gn needs to be changed.
Binaries that will run on a macOS host require entitlements, and
binaries that run on an iOS device must NOT have entitlements.
For example, if this is a new binary that runs on macOS host, add it
to [entitlements.txt] file inside the zip artifact produced by BUILD.gn.
If this is a new binary that needs to be run on iOS device, add it
to [withoutEntitlements.txt].
If there are obsolete binaries in entitlements configuration files, please delete or
update these file paths accordingly.
''';

  /// The entrance point of examining and code signing an engine artifact.
  Future<void> validateAll() async {
    await Future<void>.value(null);
    log.info('Codesigned all binaries in ${tempDir.path}');

    await tempDir.delete(recursive: true);
  }

  /// Visit a [Directory] type while examining the file system extracted from an artifact.
  Future<void> visitDirectory({
    required Directory directory,
    required String entitlementParentPath,
  }) async {
    log.info('Visiting directory ${directory.absolute.path}');
    if (directoriesVisited.contains(directory.absolute.path)) {
      log.warning(
          'Warning! You are visiting a directory that has been visited before, the directory is ${directory.absolute.path}');
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
      } else if (childType == FileType.binary) {
        await visitBinaryFile(binaryFile: entity as File, entitlementParentPath: entitlementParentPath);
      }
      log.info('Child file of directory ${directory.basename} is ${entity.basename}');
    }
  }

  /// Unzip an [EmbeddedZip] and visit its children.
  Future<void> visitEmbeddedZip({
    required FileSystemEntity zipEntity,
    required String entitlementParentPath,
  }) async {
    log.info('This embedded file is ${zipEntity.path} and entitlementParentPath is $entitlementParentPath');
    final String currentFileName = zipEntity.basename;
    final Directory newDir = tempDir.childDirectory('embedded_zip_${zipEntity.absolute.path.hashCode}');
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

  /// Visit and codesign a binary with / without entitlement.
  ///
  /// At this stage, the virtual [entitlementCurrentPath] accumulated through the recursive visit, is compared
  /// against the paths extracted from [fileWithEntitlements], to help determine if this file should be signed
  /// with entitlements.
  Future<void> visitBinaryFile({required File binaryFile, required String entitlementParentPath}) async {
    final String currentFileName = binaryFile.basename;
    final String entitlementCurrentPath = '$entitlementParentPath/$currentFileName';

    if (!fileWithEntitlements.contains(entitlementCurrentPath) &&
        !fileWithoutEntitlements.contains(entitlementCurrentPath)) {
      log.severe('The system has detected a binary file at $entitlementCurrentPath.'
          'but it is not in the entitlements configuartion files you provided.'
          'if this is a new engine artifact, please add it to one of the entitlements.txt files');
      throw CodesignException(fixItInstructions);
    }
    log.info('signing file at path ${binaryFile.absolute.path}');
    log.info('the virtual entitlement path associated with file is $entitlementCurrentPath');
    log.info('the decision to sign with entitlement is ${fileWithEntitlements.contains(entitlementCurrentPath)}');
    final List<String> args = <String>[
      'codesign',
      '-f', // force
      '-s', // use the cert provided by next argument
      codesignCertName,
      binaryFile.absolute.path,
      '--timestamp', // add a secure timestamp
      '--options=runtime', // hardened runtime
      if (fileWithEntitlements.contains(entitlementCurrentPath)) ...<String>[
        '--entitlements',
        entitlementsFile.absolute.path
      ],
    ];
    final io.ProcessResult result = await processManager.run(args);
    if (result.exitCode != 0) {
      throw CodesignException(
        'Failed to codesign ${binaryFile.absolute.path} with args: ${args.join(' ')}\n'
        'stdout:\n${(result.stdout as String).trim()}'
        'stderr:\n${(result.stderr as String).trim()}',
      );
    }
    fileConsumed.add(entitlementCurrentPath);
  }

  /// Extract entitlements configurations from downloaded zip files.
  ///
  /// Parse and store codesign configurations detailed in configuration files.
  /// File paths of entilement files and non entitlement files will be parsed and stored in [fileWithEntitlements].
  Future<Set<String>> parseEntitlements(Directory parent, bool entitlements) async {
    final String entitlementFilePath = entitlements
        ? fileSystem.path.join(parent.path, 'entitlements.txt')
        : fileSystem.path.join(parent.path, 'without_entitlements.txt');
    if (!(await fileSystem.file(entitlementFilePath).exists())) {
      throw CodesignException('$entitlementFilePath not found \n'
          'make sure you have provided them along with the engine artifacts \n');
    }

    final Set<String> fileWithEntitlements = <String>{};
    fileWithEntitlements.addAll(await fileSystem.file(entitlementFilePath).readAsLines());
    return fileWithEntitlements;
  }

  /// Upload a zip archive to the notary service and verify the build succeeded.
  ///
  /// The apple notarization service will unzip the artifact, validate all
  /// binaries are properly codesigned, and notarize the entire archive.
  Future<void> notarize(File file) async {
    final Completer<void> completer = Completer<void>();
    final String uuid = uploadZipToNotary(file);

    Future<void> callback(Timer timer) async {
      final bool notaryFinished = checkNotaryJobFinished(uuid);
      if (notaryFinished) {
        timer.cancel();
        log.info('successfully notarized ${file.path}');
        completer.complete();
      }
    }

    // check on results
    Timer.periodic(
      _notarizationTimerDuration,
      callback,
    );
    await completer.future;
  }

  /// Make a request to the notary service to see if the notary job is finished.
  ///
  /// A return value of true means that notarization finished successfully,
  /// false means that the job is still pending. If the notarization fails, this
  /// function will throw a [ConductorException].
  bool checkNotaryJobFinished(String uuid) {
    final List<String> args = <String>[
      'xcrun',
      'notarytool',
      'info',
      uuid,
      '--password',
      appSpecificPassword,
      '--apple-id',
      codesignAppstoreId,
      '--team-id',
      codesignTeamId,
    ];

    log.info('checking notary status with ${args.join(' ')}');
    final io.ProcessResult result = processManager.runSync(args);
    final String combinedOutput = (result.stdout as String) + (result.stderr as String);

    final RegExpMatch? match = _notarytoolStatusCheckPattern.firstMatch(combinedOutput);

    if (match == null) {
      throw CodesignException(
        'Malformed output from "${args.join(' ')}"\n${combinedOutput.trim()}',
      );
    }

    final String status = match.group(1)!;

    if (status == 'Accepted') {
      return true;
    }
    if (status == 'In Progress') {
      log.info('job $uuid still pending');
      return false;
    }
    throw CodesignException('Notarization failed with: $status\n$combinedOutput');
  }

  /// Upload artifact to Apple notary service.
  String uploadZipToNotary(File localFile, [int retryCount = 3, int sleepTime = 1]) {
    while (retryCount > 0) {
      final List<String> args = <String>[
        'xcrun',
        'notarytool',
        'submit',
        localFile.absolute.path,
        '--apple-id',
        codesignAppstoreId,
        '--password',
        appSpecificPassword,
        '--team-id',
        codesignTeamId,
      ];

      log.info('uploading ${args.join(' ')}');
      final io.ProcessResult result = processManager.runSync(args);

      final String combinedOutput = (result.stdout as String) + (result.stderr as String);
      final RegExpMatch? match;
      match = _notarytoolRequestPattern.firstMatch(combinedOutput);

      if (match == null) {
        if (result.exitCode >= 0 && result.exitCode <= 255) {
          log.warning('The upload to notary service completed normally, but'
              ' the output format does not match the current notary tool version.'
              ' If after inspecting the output below, you believe the process finished '
              'successfully but was not detected, please contact fujino@');
        }
        log.warning('Failed to upload to the notary service with args: ${args.join(' ')}');
        log.warning('{combinedOutput.trim()}');
        retryCount -= 1;
        log.warning('Trying again $retryCount more time${retryCount > 1 ? 's' : ''}...');
        io.sleep(Duration(seconds: sleepTime));
        continue;
      }

      final String requestUuid = match.group(1)!;
      log.info('RequestUUID for ${localFile.path} is: $requestUuid');

      return requestUuid;
    }
    throw CodesignException('Failed to upload ${localFile.path} to the notary service');
  }
}
