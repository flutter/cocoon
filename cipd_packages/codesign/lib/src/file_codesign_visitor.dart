// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:retry/retry.dart';

import 'log.dart';
import 'utils.dart';

/// Statuses reported by Apple's Notary Server.
///
/// See more:
///   * https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
enum NotaryStatus { pending, failed, succeeded }

/// Types of codesigning configuration file.
enum CodesignType {
  /// Binaries requiring codesigning that do not use APIs requiring entitlements.
  withEntitlements(filename: 'entitlements.txt'),

  /// Binaries requiring codesigning that DO NOT use APIs requiring entitlements.
  withoutEntitlements(filename: 'without_entitlements.txt'),

  /// Binaries that do not require codesigning.
  unsigned(filename: 'unsigned_binaries.txt');

  const CodesignType({required this.filename});

  final String filename;
}

/// Codesign and notarize all files within a [RemoteArchive].
class FileCodesignVisitor {
  FileCodesignVisitor({
    required this.codesignCertName,
    required this.fileSystem,
    required this.rootDirectory,
    required this.processManager,
    required this.inputZipPath,
    required this.outputZipPath,
    required this.appSpecificPasswordFilePath,
    required this.codesignAppstoreIDFilePath,
    required this.codesignTeamIDFilePath,
    this.dryrun = true,
    @visibleForTesting
    this.retryOptions = const RetryOptions(
      maxAttempts: 5,
      delayFactor: Duration(seconds: 2),
    ),
    this.notarizationTimerDuration = const Duration(seconds: 5),
  }) {
    entitlementsPlist = rootDirectory.childFile('Entitlements.plist')
      ..writeAsStringSync(_entitlementsFileContents);
  }

  /// Temp [Directory] to download/extract files to.
  ///
  /// This file will be deleted if [validateAll] completes successfully.
  final Directory rootDirectory;
  final FileSystem fileSystem;
  final ProcessManager processManager;

  final String codesignCertName;
  final String inputZipPath;
  final String outputZipPath;
  final String appSpecificPasswordFilePath;
  final String codesignAppstoreIDFilePath;
  final String codesignTeamIDFilePath;
  final bool dryrun;
  final Duration notarizationTimerDuration;
  final RetryOptions retryOptions;

  // 'Apple developer account email used for authentication with notary service.'
  late String codesignAppstoreId;
  // Unique password of the apple developer account.'
  late String appSpecificPassword;
  // Team-id is used by notary service for xcode version 13+.
  late String codesignTeamId;

  /// Files that require codesigning that use APIs requiring entitlements.
  Set<String> withEntitlementsFiles = <String>{};

  /// Files that require codesigning that DO NOT use APIs requiring entitlements.
  Set<String> withoutEntitlementsFiles = <String>{};

  /// Files that do not require codesigning.
  Set<String> unsignedBinaryFiles = <String>{};
  Set<String> fileConsumed = <String>{};
  Set<String> directoriesVisited = <String>{};
  Map<String, String> availablePasswords = {
    'CODESIGN_APPSTORE_ID': '',
    'CODESIGN_TEAM_ID': '',
    'APP_SPECIFIC_PASSWORD': '',
  };
  Map<String, String> redactedCredentials = {};

  late final File entitlementsPlist;

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
  static final RegExp _notarytoolStatusCheckPattern = RegExp(
    r'[ ]*status: ([a-zA-z ]+)',
  );
  static final RegExp _notarytoolRequestPattern = RegExp(r'id: ([a-z0-9-]+)');

  static final String fixItInstructions = '''
Codesign test failed.

We compared binary files in engine artifacts with those listed in
* ${CodesignType.withEntitlements.filename}
* ${CodesignType.withoutEntitlements.filename}
* ${CodesignType.unsigned.filename}
and the binary files do not match.

These are the configuration files encoded in engine artifact zip that detail
the code-signing requirements of each of the binaries in the archive.
Either an unexpected binary was listed in these files, or one of the expected
binaries listed in these files was not found in the archive.

This usually happens during an engine roll.

If this is a valid change, then the BUILD.gn or the codesigning configuration
files need to be changed. Binaries that will run on a macOS host require
entitlements, and binaries that run on an iOS device must NOT have entitlements.
For example, if this is a new binary that runs on macOS host, add it
to ${CodesignType.withEntitlements.filename} file inside the zip artifact produced by BUILD.gn.
If this is a new binary that needs to be run on iOS device, add it to
${CodesignType.withoutEntitlements.filename}. If there are obsolete binaries in entitlements
configuration files, please delete or update these file paths accordingly.
''';

  /// Read a single line of password stored at [passwordFilePath].
  Future<String> readPassword(String passwordFilePath) async {
    if (!(await fileSystem.file(passwordFilePath).exists())) {
      throw CodesignException(
        '$passwordFilePath not found \n'
        'make sure you have provided codesign credentials in a file \n',
      );
    }
    return fileSystem.file(passwordFilePath).readAsString();
  }

  void redactPasswords() {
    redactedCredentials[codesignAppstoreId] = '<appleID-redacted>';
    redactedCredentials[codesignTeamId] = '<teamID-redacted>';
    redactedCredentials[appSpecificPassword] = '<appSpecificPassword-redacted>';
  }

  /// The entrance point of examining and code signing an engine artifact.
  Future<void> validateAll() async {
    codesignAppstoreId = await readPassword(codesignAppstoreIDFilePath);
    codesignTeamId = await readPassword(codesignTeamIDFilePath);
    appSpecificPassword = await readPassword(appSpecificPasswordFilePath);

    redactPasswords();

    await processRemoteZip();

    log.info(
      'Codesign completed. Codesigned zip is located at $outputZipPath.'
      'If you have uploaded the artifacts back to google cloud storage, please delete'
      ' the folder $outputZipPath and $inputZipPath.',
    );
    if (dryrun) {
      log.info(
        'code signing dry run has completed, this is a quick sanity check without'
        'going through the notary service. To run the full codesign process, use --no-dryrun flag.',
      );
    }
  }

  /// Process engine artifacts from [inputZipPath] and kick start a
  /// recursive visit of its contents.
  ///
  /// Invokes [visitDirectory] to recursively visit the contents of the remote
  /// zip. Notarizes the engine artifact if [dryrun] is false.
  /// Returns null as result if [dryrun] is true.
  Future<String?> processRemoteZip() async {
    // download the zip file
    final originalFile = rootDirectory.fileSystem.file(inputZipPath);

    // This is the starting directory of the unzipped artifact.
    final parentDirectory = rootDirectory.childDirectory('single_artifact');

    await unzip(
      inputZip: originalFile,
      outDir: parentDirectory,
      processManager: processManager,
    );

    // Read codesigning configuration files.
    withEntitlementsFiles = await parseCodesignConfig(
      parentDirectory,
      CodesignType.withEntitlements,
    );
    withoutEntitlementsFiles = await parseCodesignConfig(
      parentDirectory,
      CodesignType.withoutEntitlements,
    );
    unsignedBinaryFiles = await parseCodesignConfig(
      parentDirectory,
      CodesignType.unsigned,
    );
    log.info('parsed binaries with entitlements are $withEntitlementsFiles');
    log.info(
      'parsed binaries without entitlements are $withoutEntitlementsFiles',
    );
    log.info('parsed binaries without codesigning $unsignedBinaryFiles');

    // recursively visit extracted files
    await visitDirectory(directory: parentDirectory, parentVirtualPath: '');

    await zip(
      inputDir: parentDirectory,
      outputZipPath: outputZipPath,
      processManager: processManager,
    );

    await parentDirectory.delete(recursive: true);

    // `dryrun` flag defaults to true to save time for a faster sanity check
    if (!dryrun) {
      await notarize(fileSystem.file(outputZipPath));

      return outputZipPath;
    }
    return null;
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

    await cleanupCodesignConfig(directory);

    final ignoredFiles = Set<String>.from(
      CodesignType.values.map((CodesignType type) => type.filename),
    );
    final entities = await directory.list(followLinks: false).toList();
    for (var entity in entities) {
      if (entity is io.Link) {
        log.info(
          'current file or direcotry ${entity.path} is a symlink to ${(entity as io.Link).targetSync()}, '
          'codesign is therefore skipped for the current file or directory.',
        );
        continue;
      }
      if (entity is io.Directory) {
        await visitDirectory(
          directory: directory.childDirectory(entity.basename),
          parentVirtualPath: joinEntitlementPaths(
            parentVirtualPath,
            entity.basename,
          ),
        );
        continue;
      }
      if (ignoredFiles.contains(entity.basename)) {
        continue;
      }
      final childType = getFileType(entity.absolute.path, processManager);
      if (childType == FileType.zip) {
        await visitEmbeddedZip(
          zipEntity: entity,
          parentVirtualPath: parentVirtualPath,
        );
      } else if (childType == FileType.binary) {
        await visitBinaryFile(
          binaryFile: entity as File,
          parentVirtualPath: parentVirtualPath,
        );
      }
      log.info(
        'Child file of directory ${directory.basename} is ${entity.basename}',
      );
    }
    final directoryExtension = directory.basename.split('.').last;
    if (directoryExtension == 'framework' ||
        directoryExtension == 'xcframework') {
      await codesignAtPath(binaryOrBundlePath: directory.absolute.path);
    }
  }

  /// Unzip an [EmbeddedZip] and visit its children.
  Future<void> visitEmbeddedZip({
    required FileSystemEntity zipEntity,
    required String parentVirtualPath,
  }) async {
    log.info(
      'This embedded file is ${zipEntity.path} and parentVirtualPath is $parentVirtualPath',
    );
    final currentFileName = zipEntity.basename;
    final newDir = rootDirectory.childDirectory(
      'embedded_zip_${zipEntity.absolute.path.hashCode}',
    );
    await unzip(
      inputZip: zipEntity,
      outDir: newDir,
      processManager: processManager,
    );

    // the virtual file path is advanced by the name of the embedded zip
    final currentZipEntitlementPath = joinEntitlementPaths(
      parentVirtualPath,
      currentFileName,
    );
    await visitDirectory(
      directory: newDir,
      parentVirtualPath: currentZipEntitlementPath,
    );
    await zipEntity.delete();
    await zip(
      inputDir: newDir,
      outputZipPath: zipEntity.absolute.path,
      processManager: processManager,
    );
    await newDir.delete(recursive: true);
  }

  /// Visit and handle code-signing for a binary.
  ///
  /// At this stage, the virtual [currentFilePath] accumulated through the recursive
  /// visit is compared against the paths extracted from the contents of the codesigning
  /// config files, to help determine whether or not this file should be codesigned
  /// and if so, whether or not it should be signed with entitlements.
  Future<void> visitBinaryFile({
    required File binaryFile,
    required String parentVirtualPath,
  }) async {
    final currentFileName = binaryFile.basename;
    final currentFilePath = joinEntitlementPaths(
      parentVirtualPath,
      currentFileName,
    );

    if (!withEntitlementsFiles.contains(currentFilePath) &&
        !withoutEntitlementsFiles.contains(currentFilePath) &&
        !unsignedBinaryFiles.contains(currentFilePath)) {
      log.severe(
        'The binary file $currentFileName is causing an issue. \n'
        'This file is located at $currentFilePath in the flutter engine artifact.',
      );
      log.severe(
        'The system has detected a binary file at $currentFilePath. '
        'But it is not in the codesigning configuration files you provided. '
        'If this is a new engine artifact, please add it to one of the codesigning '
        'config files.',
      );
      throw CodesignException(fixItInstructions);
    }
    if (unsignedBinaryFiles.contains(currentFilePath)) {
      // No codesigning necessary.
      log.info('Not signing file at path ${binaryFile.absolute.path}');
      return;
    }
    log.info('Signing file at path ${binaryFile.absolute.path}');
    log.info(
      'The virtual entitlement path associated with file is $currentFilePath',
    );
    log.info(
      'The decision to sign with entitlement is ${withEntitlementsFiles.contains(currentFilePath)}',
    );
    fileConsumed.add(currentFilePath);
    if (dryrun) {
      return;
    }
    await codesignAtPath(
      binaryOrBundlePath: binaryFile.absolute.path,
      currentFilePath: currentFilePath,
    );
  }

  Future<void> codesignAtPath({
    required String binaryOrBundlePath,
    String? currentFilePath,
  }) async {
    final args = <String>[
      '/usr/bin/codesign',
      '--keychain',
      'build.keychain', // specify the keychain to look for cert
      '-f', // force. Needed to overwrite signature if major executable of bundle is already signed before bundle is signed.
      '-s', // use the cert provided by next argument
      codesignCertName,
      binaryOrBundlePath,
      '--timestamp', // add a secure timestamp
      '--options=runtime', // hardened runtime
      if (currentFilePath != '' &&
          withEntitlementsFiles.contains(currentFilePath)) ...<String>[
        '--entitlements',
        entitlementsPlist.absolute.path,
      ],
    ];

    await retryOptions.retry(() async {
      log.info('Executing: ${args.join(' ')}\n');
      final result = await processManager.run(args);
      if (result.exitCode == 0) {
        return;
      }

      throw CodesignException(
        'Failed to codesign binary or bundle at $binaryOrBundlePath with args: ${args.join(' ')}\n'
        'stdout:\n${(result.stdout as String).trim()}'
        'stderr:\n${(result.stderr as String).trim()}',
      );
    });
  }

  /// Delete codesign metadata at ALL places inside engine binary.
  ///
  /// Context: https://github.com/flutter/flutter/issues/126705. This is a temporary workaround.
  /// Once flutter tools is ready we can remove this logic.
  Future<void> cleanupCodesignConfig(Directory parent) async {
    final pathsToDelete = CodesignType.values.map(
      (CodesignType type) => fileSystem.path.join(parent.path, type.filename),
    );
    for (var metadataPath in pathsToDelete) {
      if (await fileSystem.file(metadataPath).exists()) {
        log.warning('cleaning up codesign metadata at $metadataPath.');
        await fileSystem.file(metadataPath).delete();
      }
    }
  }

  /// Extract entitlements configurations from downloaded zip files.
  ///
  /// Parse and store codesign configurations detailed in configuration files.
  /// File paths of entitlement files and non entitlement files will be parsed and stored in [withEntitlementsFiles].
  Future<Set<String>> parseCodesignConfig(
    Directory parent,
    CodesignType codesignType,
  ) async {
    final codesignConfigPath = fileSystem.path.join(
      parent.path,
      codesignType.filename,
    );
    if (!(await fileSystem.file(codesignConfigPath).exists())) {
      log.warning(
        '$codesignConfigPath not found. '
        'by default, system will assume there is no ${codesignType.filename} file. '
        'As a result, no binary will be codesigned.'
        'if this is not intended, please provide them along with the engine artifacts.',
      );
      return <String>{};
    }

    final fileWithEntitlements = <String>{};

    fileWithEntitlements.addAll(
      await fileSystem.file(codesignConfigPath).readAsLines(),
    );
    // TODO(xilaizhang) : add back metadata information after https://github.com/flutter/flutter/issues/126705
    // is resolved.
    await fileSystem.file(codesignConfigPath).delete();

    return fileWithEntitlements;
  }

  /// Upload a zip archive to the notary service and verify the build succeeded.
  ///
  /// The apple notarization service will unzip the artifact, validate all
  /// binaries are properly codesigned, and notarize the entire archive.
  Future<void> notarize(File file) async {
    final completer = Completer<void>();
    final uuid = await uploadZipToNotary(file);

    Future<void> callback(Timer timer) async {
      final notaryFinished = checkNotaryJobFinished(uuid);
      if (notaryFinished) {
        timer.cancel();
        log.info('successfully notarized ${file.path}');
        completer.complete();
      }
    }

    // check on results
    Timer.periodic(notarizationTimerDuration, callback);
    await completer.future;
  }

  /// Make a request to the notary service to see if the notary job is finished.
  ///
  /// A return value of true means that notarization finished successfully,
  /// false means that the job is still pending. If the notarization fails, this
  /// function will throw a [ConductorException].
  bool checkNotaryJobFinished(String uuid) {
    final args = <String>[
      'xcrun',
      'notarytool',
      'info',
      uuid,
      '--apple-id',
      codesignAppstoreId,
      '--password',
      appSpecificPassword,
      '--team-id',
      codesignTeamId,
    ];

    var argsWithoutCredentials = args.join(' ');
    for (var key in redactedCredentials.keys) {
      argsWithoutCredentials = argsWithoutCredentials.replaceAll(
        key,
        redactedCredentials[key]!,
      );
    }
    log.info('checking notary info: $argsWithoutCredentials');
    final result = processManager.runSync(args);
    final combinedOutput =
        (result.stdout as String) + (result.stderr as String);

    final match = _notarytoolStatusCheckPattern.firstMatch(combinedOutput);

    if (match == null) {
      throw CodesignException(
        'Malformed output from "$argsWithoutCredentials"\n${combinedOutput.trim()}',
      );
    }

    final status = match.group(1)!;

    if (status == 'Accepted') {
      return true;
    }
    if (status == 'In Progress') {
      log.info('job $uuid still pending');
      return false;
    }
    throw CodesignException(
      'Notarization failed with: $status\n$combinedOutput',
    );
  }

  /// Upload artifact to Apple notary service and return the tracking request UUID.
  Future<String> uploadZipToNotary(File localFile) {
    return retryOptions.retry(() async {
      final args = <String>[
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
        '--verbose',
      ];

      var argsWithoutCredentials = args.join(' ');
      for (var key in redactedCredentials.keys) {
        argsWithoutCredentials = argsWithoutCredentials.replaceAll(
          key,
          redactedCredentials[key]!,
        );
      }
      log.info('uploading to notary: $argsWithoutCredentials');
      final result = processManager.runSync(args);
      if (result.exitCode != 0) {
        throw CodesignException(
          'Command "$argsWithoutCredentials" failed with exit code ${result.exitCode}\nStdout: ${result.stdout}\nStderr: ${result.stderr}',
        );
      }

      final combinedOutput =
          (result.stdout as String) + (result.stderr as String);
      final match = _notarytoolRequestPattern.firstMatch(combinedOutput);

      if (match == null) {
        log.warning('Failed to upload to the notary service');
        log.warning('$argsWithoutCredentials\n$combinedOutput');
        throw CodesignException(
          'Failed to upload to the notary service\n$combinedOutput',
        );
      }

      final requestUuid = match.group(1)!;
      log.info('RequestUUID for ${localFile.path} is: $requestUuid');
      return requestUuid;
    });
  }
}
