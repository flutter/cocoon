// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:process/process.dart';

import 'google_cloud_storage.dart';
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
    required this.codesignCertName,
    required this.fileSystem,
    required this.rootDirectory,
    required this.processManager,
    required this.gcsDownloadPath,
    required this.gcsUploadPath,
    required this.googleCloudStorage,
    required this.appSpecificPasswordFilePath,
    required this.codesignAppstoreIDFilePath,
    required this.codesignTeamIDFilePath,
    this.dryrun = true,
    this.notarizationTimerDuration = const Duration(seconds: 5),
  }) {
    entitlementsFile = rootDirectory.childFile('Entitlements.plist')..writeAsStringSync(_entitlementsFileContents);
    remoteDownloadsDir = rootDirectory.childDirectory('downloads')..createSync();
    codesignedZipsDir = rootDirectory.childDirectory('codesigned_zips')..createSync();
  }

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  final Directory rootDirectory;
  final FileSystem fileSystem;
  final ProcessManager processManager;
  final GoogleCloudStorage googleCloudStorage;

  final String codesignCertName;
  final String gcsDownloadPath;
  final String gcsUploadPath;
  final String appSpecificPasswordFilePath;
  final String codesignAppstoreIDFilePath;
  final String codesignTeamIDFilePath;
  final bool dryrun;
  final Duration notarizationTimerDuration;

  // 'Apple developer account email used for authentication with notary service.'
  late String codesignAppstoreId;
  // Unique password of the apple developer account.'
  late String appSpecificPassword;
  // Team-id is used by notary service for xcode version 13+.
  late String codesignTeamId;

  Set<String> fileWithEntitlements = <String>{};
  Set<String> fileWithoutEntitlements = <String>{};
  Set<String> fileConsumed = <String>{};
  Set<String> directoriesVisited = <String>{};
  Map<String, String> availablePasswords = {
    'CODESIGN_APPSTORE_ID': '',
    'CODESIGN_TEAM_ID': '',
    'APP_SPECIFIC_PASSWORD': ''
  };

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

  /// Read a single line of password stored at [passwordFilePath].
  ///
  /// The password file should provide the password name and value, deliminated by a single colon.
  /// The content of a password file would look similar to:
  /// CODESIGN_APPSTORE_ID:123
  Future<void> readPassword(String passwordFilePath) async {
    if (!(await fileSystem.file(passwordFilePath).exists())) {
      throw CodesignException('$passwordFilePath not found \n'
          'make sure you have provided codesign credentials in a file \n');
    }

    final String passwordLine = await fileSystem.file(passwordFilePath).readAsString();
    final List<String> parsedPasswordLine = passwordLine.split(":");
    if (parsedPasswordLine.length != 2) {
      throw CodesignException('$passwordFilePath is not correctly formatted. \n'
          'please double check formatting \n');
    }
    final String passwordName = parsedPasswordLine[0];
    final String passwordValue = parsedPasswordLine[1];
    if (!availablePasswords.containsKey(passwordName)) {
      throw CodesignException('$passwordName is not a password we can process. \n'
          'please double check passwords.txt \n');
    }
    availablePasswords[passwordName] = passwordValue;
    return;
  }

  /// The entrance point of examining and code signing an engine artifact.
  Future<void> validateAll() async {
    for (String passwordFilePath in [
      codesignAppstoreIDFilePath,
      codesignTeamIDFilePath,
      appSpecificPasswordFilePath,
    ]) {
      await readPassword(passwordFilePath);
    }
    if (availablePasswords.containsValue('')) {
      throw CodesignException('certian passwords are missing. \n'
          'make sure you have provided <CODESIGN_APPSTORE_ID>, <CODESIGN_TEAM_ID>, and <APP_SPECIFIC_PASSWORD>');
    }
    codesignAppstoreId = availablePasswords['CODESIGN_APPSTORE_ID']!;
    codesignTeamId = availablePasswords['CODESIGN_TEAM_ID']!;
    appSpecificPassword = availablePasswords['APP_SPECIFIC_PASSWORD']!;

    await processRemoteZip();

    if (dryrun) {
      log.info('code signing dry run has completed, If you intend to upload the artifacts back to'
          ' google cloud storage, please use the --dryrun=false flag to run code signing script.');
    }
    log.info('Codesigned all binaries in ${rootDirectory.path}');

    await rootDirectory.delete(recursive: true);
  }

  /// Retrieve engine artifact from google cloud storage and kick start a
  /// recursive visit of its contents.
  ///
  /// Invokes [visitDirectory] to recursively visit the contents of the remote
  /// zip. Also downloads, notarizes and uploads the engine artifact.
  Future<void> processRemoteZip() async {
    // Name of the downloaded artifact.
    // There won't be collisions since we are only signing one artifact at a time now
    const String localFilePath = 'remote_artifact.zip';

    // download the zip file
    final File originalFile = await googleCloudStorage.downloadEngineArtifact(
      from: gcsDownloadPath,
      destination: remoteDownloadsDir.childFile(localFilePath).path,
    );

    // This is the starting directory of the unzipped artifact.
    final Directory parentDirectory = rootDirectory.childDirectory('single_artifact');

    await unzip(
      inputZip: originalFile,
      outDir: parentDirectory,
      processManager: processManager,
    );

    //extract entitlements file.
    fileWithEntitlements = await parseEntitlements(parentDirectory, true);
    fileWithoutEntitlements = await parseEntitlements(parentDirectory, false);
    log.info('parsed binaries with entitlements are $fileWithEntitlements');
    log.info('parsed binaries without entitlements are $fileWithEntitlements');

    // recursively visit extracted files
    await visitDirectory(directory: parentDirectory, parentVirtualPath: "");

    final File codesignedFile = codesignedZipsDir.childFile(localFilePath);

    await zip(
      inputDir: parentDirectory,
      outputZip: codesignedFile,
      processManager: processManager,
    );

    // `dryrun` flag defaults to true to prevent uploading artifacts back to google cloud.
    // This would help prevent https://github.com/flutter/flutter/issues/104387
    if (!dryrun) {
      await notarize(codesignedFile);

      await googleCloudStorage.uploadEngineArtifact(
        from: codesignedFile.path,
        destination: gcsUploadPath,
      );
    }
  }

  /// Visit a [Directory] type while examining the file system extracted from an artifact.
  Future<void> visitDirectory({
    required Directory directory,
    required String parentVirtualPath,
  }) async {
    log.info('Visiting directory ${directory.absolute.path}');
    if (directoriesVisited.contains(directory.absolute.path)) {
      log.warning(
        'Warning! You are visiting a directory that has been visited before, the directory is ${directory.absolute.path}',
      );
    }
    directoriesVisited.add(directory.absolute.path);
    final List<FileSystemEntity> entities = await directory.list().toList();
    for (FileSystemEntity entity in entities) {
      if (entity is io.Directory) {
        await visitDirectory(
          directory: directory.childDirectory(entity.basename),
          parentVirtualPath: joinEntitlementPaths(parentVirtualPath, entity.basename),
        );
        continue;
      }
      if (entity.basename == 'entitlements.txt' || entity.basename == 'without_entitlements.txt') {
        continue;
      }
      final FileType childType = getFileType(
        entity.absolute.path,
        processManager,
      );
      if (childType == FileType.zip) {
        await visitEmbeddedZip(
          zipEntity: entity,
          parentVirtualPath: parentVirtualPath,
        );
      } else if (childType == FileType.binary) {
        await visitBinaryFile(binaryFile: entity as File, parentVirtualPath: parentVirtualPath);
      }
      log.info('Child file of directory ${directory.basename} is ${entity.basename}');
    }
  }

  /// Unzip an [EmbeddedZip] and visit its children.
  Future<void> visitEmbeddedZip({
    required FileSystemEntity zipEntity,
    required String parentVirtualPath,
  }) async {
    log.info('This embedded file is ${zipEntity.path} and parentVirtualPath is $parentVirtualPath');
    final String currentFileName = zipEntity.basename;
    final Directory newDir = rootDirectory.childDirectory('embedded_zip_${zipEntity.absolute.path.hashCode}');
    await unzip(
      inputZip: zipEntity,
      outDir: newDir,
      processManager: processManager,
    );

    // the virtual file path is advanced by the name of the embedded zip
    final String currentZipEntitlementPath = joinEntitlementPaths(parentVirtualPath, currentFileName);
    await visitDirectory(
      directory: newDir,
      parentVirtualPath: currentZipEntitlementPath,
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
  Future<void> visitBinaryFile({required File binaryFile, required String parentVirtualPath}) async {
    final String currentFileName = binaryFile.basename;
    final String entitlementCurrentPath = joinEntitlementPaths(parentVirtualPath, currentFileName);

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
    fileConsumed.add(entitlementCurrentPath);
    if (dryrun) {
      return;
    }
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
      notarizationTimerDuration,
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
      if (result.exitCode != 0) {
        throw CodesignException(
          'Command "${args.join(' ')}" failed with exit code ${result.exitCode}\nStdout: ${result.stdout}\nStderr: ${result.stderr}',
        );
      }

      final String combinedOutput = (result.stdout as String) + (result.stderr as String);
      final RegExpMatch? match;
      match = _notarytoolRequestPattern.firstMatch(combinedOutput);

      if (match == null) {
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
    log.warning('The upload to notary service failed after retries, and'
        '  the output format does not match the current notary tool version.'
        ' If after inspecting the output, you believe the process finished '
        'successfully but was not detected, please contact flutter release engineers');
    throw CodesignException('Failed to upload ${localFile.path} to the notary service');
  }
}
