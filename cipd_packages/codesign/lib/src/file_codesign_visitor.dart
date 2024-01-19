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
    required this.inputZipPath,
    required this.outputZipPath,
    required this.appSpecificPasswordFilePath,
    required this.codesignAppstoreIDFilePath,
    required this.codesignTeamIDFilePath,
    this.dryrun = true,
    @visibleForTesting this.retryOptions = const RetryOptions(
      maxAttempts: 5,
      delayFactor: Duration(seconds: 2),
    ),
    this.notarizationTimerDuration = const Duration(seconds: 5),
  }) {
    entitlementsFile = rootDirectory.childFile('Entitlements.plist')..writeAsStringSync(_entitlementsFileContents);
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

  Set<String> fileWithEntitlements = <String>{};
  Set<String> fileWithoutEntitlements = <String>{};
  Set<String> fileConsumed = <String>{};
  Set<String> directoriesVisited = <String>{};
  Map<String, String> availablePasswords = {
    'CODESIGN_APPSTORE_ID': '',
    'CODESIGN_TEAM_ID': '',
    'APP_SPECIFIC_PASSWORD': '',
  };
  Map<String, String> redactedCredentials = {};

  late final File entitlementsFile;

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
*entitlements.txt is the configuration file encoded in engine artifact zip,
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
  Future<String> readPassword(String passwordFilePath) async {
    if (!(await fileSystem.file(passwordFilePath).exists())) {
      throw CodesignException('$passwordFilePath not found \n'
          'make sure you have provided codesign credentials in a file \n');
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

    log.info('Codesign completed. Codesigned zip is located at $outputZipPath.'
        'If you have uploaded the artifacts back to google cloud storage, please delete'
        ' the folder $outputZipPath and $inputZipPath.');
    if (dryrun) {
      log.info('code signing dry run has completed, this is a quick sanity check without'
          'going through the notary service. To run the full codesign process, use --no-dryrun flag.');
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
    final File originalFile = rootDirectory.fileSystem.file(inputZipPath);

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

    await cleanupEntitlements(directory);

    final List<FileSystemEntity> entities = await directory.list(followLinks: false).toList();
    for (FileSystemEntity entity in entities) {
      if (entity is io.Link) {
        log.info('current file or direcotry ${entity.path} is a symlink to ${(entity as io.Link).targetSync()}, '
            'codesign is therefore skipped for the current file or directory.');
        continue;
      }
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
    final String directoryExtension = directory.basename.split('.').last;
    if (directoryExtension == 'framework' || directoryExtension == 'xcframework') {
      final List<String> args = <String>[
        '/usr/bin/codesign',
        '--keychain',
        'build.keychain', // specify the keychain to look for cert
        '-f', // force. Possible re-signing of FlutterMacOS.framework, Flutter.xcframework/ios-arm64/Flutter.framework etc.
        '-s', // use the cert provided by next argument
        codesignCertName,
        directory.absolute.path,
        '--timestamp', // add a secure timestamp
      ];

      await retryOptions.retry(() async {
        log.info('Code signing framework bundle: ${args.join(' ')}\n');
        final io.ProcessResult result = await processManager.run(args);
        if (result.exitCode == 0) {
          return;
        }

        throw CodesignException(
          'Failed to codesign bundle ${directory.absolute.path} with args: ${args.join(' ')}\n'
          'stdout:\n${(result.stdout as String).trim()}'
          'stderr:\n${(result.stderr as String).trim()}',
        );
      });
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
      outputZipPath: zipEntity.absolute.path,
      processManager: processManager,
    );
    await newDir.delete(recursive: true);
  }

  /// Visit and codesign a binary with / without entitlement.
  ///
  /// At this stage, the virtual [entitlementCurrentPath] accumulated through the recursive visit, is compared
  /// against the paths extracted from [fileWithEntitlements], to help determine if this file should be signed
  /// with entitlements.
  Future<void> visitBinaryFile({
    required File binaryFile,
    required String parentVirtualPath,
  }) async {
    final String currentFileName = binaryFile.basename;
    final String entitlementCurrentPath = joinEntitlementPaths(parentVirtualPath, currentFileName);

    if (!fileWithEntitlements.contains(entitlementCurrentPath) &&
        !fileWithoutEntitlements.contains(entitlementCurrentPath)) {
      log.severe('the binary file $currentFileName is causing an issue. \n'
          'This file is located at $entitlementCurrentPath in the flutter engine artifact.');
      log.severe('The system has detected a binary file at $entitlementCurrentPath. '
          'But it is not in the entitlements configuration files you provided. '
          'If this is a new engine artifact, please add it to one of the entitlements.txt files.');
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
      '/usr/bin/codesign',
      '--keychain',
      'build.keychain', // specify the keychain to look for cert
      '-f', // force
      '-s', // use the cert provided by next argument
      codesignCertName,
      binaryFile.absolute.path,
      '--timestamp', // add a secure timestamp
      '--options=runtime', // hardened runtime
      if (fileWithEntitlements.contains(entitlementCurrentPath)) ...<String>[
        '--entitlements',
        entitlementsFile.absolute.path,
      ],
    ];

    await retryOptions.retry(() async {
      log.info('Executing: ${args.join(' ')}\n');
      final io.ProcessResult result = await processManager.run(args);
      if (result.exitCode == 0) {
        return;
      }

      throw CodesignException(
        'Failed to codesign ${binaryFile.absolute.path} with args: ${args.join(' ')}\n'
        'stdout:\n${(result.stdout as String).trim()}'
        'stderr:\n${(result.stderr as String).trim()}',
      );
    });
  }

  /// Delete codesign metadata at ALL places inside engine binary.
  ///
  /// Context: https://github.com/flutter/flutter/issues/126705. This is a temporary workaround.
  /// Once flutter tools is ready we can remove this logic.
  Future<void> cleanupEntitlements(Directory parent) async {
    final String metadataEntitlements = fileSystem.path.join(parent.path, 'entitlements.txt');
    final String metadataWithoutEntitlements = fileSystem.path.join(parent.path, 'without_entitlements.txt');
    for (String metadataPath in [metadataEntitlements, metadataWithoutEntitlements]) {
      if (await fileSystem.file(metadataPath).exists()) {
        log.warning('cleaning up codesign metadata at $metadataPath.');
        await fileSystem.file(metadataPath).delete();
      }
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
      log.warning('$entitlementFilePath not found. '
          'by default, system will assume there is no ${entitlements ? '' : 'without_'}entitlements file. '
          'As a result, no binary will be codesigned.'
          'if this is not intended, please provide them along with the engine artifacts.');
      return <String>{};
    }

    final Set<String> fileWithEntitlements = <String>{};

    fileWithEntitlements.addAll(await fileSystem.file(entitlementFilePath).readAsLines());
    // TODO(xilaizhang) : add back metadata information after https://github.com/flutter/flutter/issues/126705
    // is resolved.
    await fileSystem.file(entitlementFilePath).delete();

    return fileWithEntitlements;
  }

  /// Upload a zip archive to the notary service and verify the build succeeded.
  ///
  /// The apple notarization service will unzip the artifact, validate all
  /// binaries are properly codesigned, and notarize the entire archive.
  Future<void> notarize(File file) async {
    final Completer<void> completer = Completer<void>();
    final String uuid = await uploadZipToNotary(file);

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
      '--apple-id',
      codesignAppstoreId,
      '--password',
      appSpecificPassword,
      '--team-id',
      codesignTeamId,
    ];

    String argsWithoutCredentials = args.join(' ');
    for (var key in redactedCredentials.keys) {
      argsWithoutCredentials = argsWithoutCredentials.replaceAll(key, redactedCredentials[key]!);
    }
    log.info('checking notary info: $argsWithoutCredentials');
    final io.ProcessResult result = processManager.runSync(args);
    final String combinedOutput = (result.stdout as String) + (result.stderr as String);

    final RegExpMatch? match = _notarytoolStatusCheckPattern.firstMatch(combinedOutput);

    if (match == null) {
      throw CodesignException(
        'Malformed output from "$argsWithoutCredentials"\n${combinedOutput.trim()}',
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

  /// Upload artifact to Apple notary service and return the tracking request UUID.
  Future<String> uploadZipToNotary(File localFile) {
    return retryOptions.retry(
      () async {
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
          '--verbose',
        ];

        String argsWithoutCredentials = args.join(' ');
        for (var key in redactedCredentials.keys) {
          argsWithoutCredentials = argsWithoutCredentials.replaceAll(key, redactedCredentials[key]!);
        }
        log.info('uploading to notary: $argsWithoutCredentials');
        final io.ProcessResult result = processManager.runSync(args);
        if (result.exitCode != 0) {
          throw CodesignException(
            'Command "$argsWithoutCredentials" failed with exit code ${result.exitCode}\nStdout: ${result.stdout}\nStderr: ${result.stderr}',
          );
        }

        final String combinedOutput = (result.stdout as String) + (result.stderr as String);
        final RegExpMatch? match = _notarytoolRequestPattern.firstMatch(combinedOutput);

        if (match == null) {
          log.warning('Failed to upload to the notary service');
          log.warning('$argsWithoutCredentials\n$combinedOutput');
          throw CodesignException('Failed to upload to the notary service\n$combinedOutput');
        }

        final String requestUuid = match.group(1)!;
        log.info('RequestUUID for ${localFile.path} is: $requestUuid');
        return requestUuid;
      },
    );
  }
}
