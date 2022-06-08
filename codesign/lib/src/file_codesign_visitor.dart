// Copyright 2021 The Flutter Authors. All rights reserved.
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

  /// helper function to generate unique next IDs.
  int _nextId = 0;
  int get nextId {
    final int currentKey = _nextId;
    _nextId += 1;
    return currentKey;
  }

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

    await _checkUnusedFiles();

    if (!production) {
      print('\ncode signing simulation has completed, If you intend to upload the artifacts back to'
          ' google cloud storage, please use the --production=true flag when running code signing script.\n'
          'thanks for understanding the security concerns!\n');
    }
  }

  /// Unzip an [EmbeddedZip] and visit its children.
  @override
  Future<void> visitEmbeddedZip(EmbeddedZip file, String parentPath, String entitlementParentPath) async {
    print('this embedded file is ${file.path} and entilementParentPath is $entitlementParentPath\n');
    String currentFileName = file.path.split('/').last;
    final File localFile = (await _validateFileExists(file))!;
    final Directory newDir = tempDir.childDirectory('embedded_zip_$nextId');
    final package_arch.Archive? archive = await _unzip(localFile, newDir);

    String absoluteDirectoryPath = newDir.absolute.path;
    // the virtual file path is advanced by the name of the embedded zip
    String currentZipEntitlementPath = '$entitlementParentPath/$currentFileName';
    await visitDirectory(absoluteDirectoryPath, currentZipEntitlementPath);
    await localFile.delete();
    final package_arch.Archive? codesignedArchive = await _zip(newDir, localFile);
    if (codesignedArchive != null && archive != null) {
      _ensureArchivesAreEquivalent(
        archive.files,
        codesignedArchive.files,
      );
    }
  }

  /// Visit a [Directory] type.
  ///
  /// Based on the child file type returned from `ls` command, a reursive visit on
  /// [FILETYPE.BINARY], [FILETYPE.ZIP], or [FILETYPE.FOLDER] will be triggered.
  /// entitlementParentPath tracks a theorectical file path if every file was unzipped
  /// in the current folder. Since we extract zip files to another folder,
  /// entitlementParentPath may not be the real absolute file path.
  Future<void> visitDirectory(String parentPath, String entitlementParentPath) async {
    print('visiting directory $parentPath\n');
    if (await isSymlink(parentPath, processManager)) {
      print('this is a symlink folder\n');
      return;
    }
    List<String> files = listFiles(parentPath, processManager);
    print('files are $files \n');
    for (String childFile in files) {
      String absoluteChildPath = '$parentPath/$childFile';
      FILETYPE childType = checkFileType(absoluteChildPath, processManager);
      print('childFile is $childFile, child type is $childType');
      if (childType == FILETYPE.BINARY) {
        await BinaryFile(path: absoluteChildPath).visit(this, parentPath, entitlementParentPath);
      } else if (childType == FILETYPE.ZIP) {
        await EmbeddedZip(path: absoluteChildPath).visit(this, parentPath, entitlementParentPath);
      } else if (childType == FILETYPE.FOLDER) {
        // only advance entitlement virtual path for directory type
        await visitDirectory(absoluteChildPath, "$entitlementParentPath/$childFile");
      } else {
        await Future.value(null);
      }
    }
  }

  /// Download and unzip a [RemoteZip] file, and kick start a recursive visit of its children.
  ///
  /// The [parent] directory is scoped to this particular [RemoteZip].
  @override
  Future<void> visitRemoteZip(RemoteZip file, Directory parent) async {
    final FileSystem fs = tempDir.fileSystem;

    // namespace by index otherwise there will be collisions
    final String localFilePath = '${remoteDownloadIndex}_${fs.path.basename(file.path)}';

    // download the zip file
    final File originalFile = await download(
      file.path,
      remoteDownloadsDir.childFile(localFilePath).path,
    );

    final package_arch.Archive? archive = await _unzip(originalFile, parent);

    //extract entitlements file.
    fileWithEntitlements = await parseEntitlements(parent, true);
    fileWithoutEntitlements = await parseEntitlements(parent, false);
    print('parsed entitlements are ');
    print(fileWithEntitlements);

    // recursively visit extracted files
    final String parentPath = fs.path.join(parent.path);
    await visitDirectory(parentPath, file.path);

    final File codesignedFile = codesignedZipsDir.childFile(localFilePath);

    final package_arch.Archive? codesignedArchive = await _zip(parent, codesignedFile);
    if (archive != null && codesignedArchive != null) {
      _ensureArchivesAreEquivalent(
        archive.files,
        codesignedArchive.files,
      );
    }

    // notarize
    await notarize(codesignedFile);

    // we will only upload for production
    if (production) {
      await upload(
        codesignedFile.path,
        file.path,
      );
    }
  }

  /// Visit a binary file.
  @override
  Future<void> visitBinaryFile(BinaryFile file, String entitlementParentPath) async {
    if (await isSymlink(file.path, processManager)) {
      return;
    }
    final File localFile = (await _validateFileExists(file))!;

    String currentFileName = file.path.split('/').last;
    String entitlementCurrentPath = '$entitlementParentPath/$currentFileName';
    await codesign(localFile, file, entitlementCurrentPath);
  }

  /// Codesign a binary with / without entilement.
  ///
  /// At this stage, the virtual [entitlementCurrentPath] accumulated through the recursive visit, is compared
  /// against the paths extracted from [fileWithEntitlements], to help determine if this file should be signed
  /// with entitlements.
  Future<void> codesign(File file, BinaryFile binaryFile, String entitlementCurrentPath) async {
    if (!fileWithEntitlements!.contains(entitlementCurrentPath) &&
        !fileWithoutEntitlements!.contains(entitlementCurrentPath)) {
      throw Exception(
        'The system has detected a binary file at $entitlementCurrentPath\n'
        'but it is not in the entitlements configuartion files your provided \n'
        'if this is a new engine artifact, please add it to one of the entilements.txt files',
      );
    }
    print('\n signing file at path ${file.absolute.path}');
    print('\n the virtual entitlement path associated with file is $entitlementCurrentPath');
    print('\n the decision to sign with entitlement is ${fileWithEntitlements!.contains(entitlementCurrentPath)}');
    final List<String> args = <String>[
      'codesign',
      '-f', // force
      '-s', // use the cert provided by next argument
      codesignCertName,
      file.absolute.path,
      '--timestamp', // add a secure timestamp
      '--options=runtime', // hardened runtime
      if (fileWithEntitlements!.contains(entitlementCurrentPath)) ...<String>[
        '--entitlements',
        entitlementsFile.absolute.path
      ],
    ];
    final io.ProcessResult result = await processManager.run(args);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to codesign ${file.absolute.path} with args: ${args.join(' ')}\n'
        'stdout:\n${(result.stdout as String).trim()}\n'
        'stderr:\n${(result.stderr as String).trim()}',
      );
    }
    fileConsumed.add(entitlementCurrentPath);
  }

  void _ensureArchivesAreEquivalent(List<package_arch.ArchiveFile> first, List<package_arch.ArchiveFile> second) {
    final Set<String> firstStrings = first.map<String>((package_arch.ArchiveFile file) {
      return file.name;
    }).toSet();
    final Set<String> secondStrings = first.map<String>((package_arch.ArchiveFile file) {
      return file.name;
    }).toSet();

    for (final String archiveName in firstStrings) {
      if (!secondStrings.contains(archiveName)) {
        throw Exception('first has $archiveName but second does not');
      }
    }
    for (final String archiveName in secondStrings) {
      if (!firstStrings.contains(archiveName)) {
        throw Exception('second has $archiveName but first does not');
      }
    }
  }

  static const Duration _notarizationTimerDuration = Duration(seconds: 45);

  /// Upload a zip archive to the notary service and verify the build succeeded.
  ///
  /// Only [RemoteZip] files need to be uploaded to the notary service,
  /// as the service will unzip it, validate all binaries are codesigning, and
  /// notarize the entire archive.
  ///
  Future<void> notarize(File file) async {
    final Completer<void> completer = Completer<void>();
    final String uuid = uploadZipToNotary(file);

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
      _notarizationTimerDuration,
      callback,
    );
    await completer.future;
  }

  static final RegExp _altoolStatusCheckPattern = RegExp(r'[ ]*Status: ([a-z ]+)');
  static final RegExp _notarytoolStatusCheckPattern = RegExp(r'[ ]*status: ([a-zA-z ]+)');

  /// Make a request to the notary service to see if the notary job is finished.
  ///
  /// A return value of true means that notarization finished successfully,
  /// false means that the job is still pending. If the notarization fails, this
  /// function will throw a [ConductorException].
  bool checkNotaryJobFinished(String uuid) {
    List<String> args;
    if (isNotaryTool) {
      args = <String>[
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
    } else {
      args = <String>[
        'xcrun',
        'altool',
        '--notarization-info',
        uuid,
        '-u',
        codesignUserName,
        '--password',
        appSpecificPassword,
      ];
    }

    stdio.printStatus('checking notary status with ${args.join(' ')}');
    final io.ProcessResult result = processManager.runSync(args);
    // Note that this tool outputs to STDOUT on Xcode 11, STDERR on earlier
    final String combinedOutput = (result.stdout as String) + (result.stderr as String);

    RegExpMatch? match;
    if (isNotaryTool) {
      match = _notarytoolStatusCheckPattern.firstMatch(combinedOutput);
    } else {
      match = _altoolStatusCheckPattern.firstMatch(combinedOutput);
    }

    if (match == null) {
      throw ConductorException(
        'Malformed output from "${args.join(' ')}"\n${combinedOutput.trim()}',
      );
    }

    final String status = match.group(1)!;
    if (isNotaryTool) {
      if (status == 'Accepted') {
        return true;
      }
      if (status == 'In Progress') {
        stdio.printStatus('job $uuid still pending');
        return false;
      }
      throw ConductorException('Notarization failed with: $status\n$combinedOutput');
    } else {
      if (status == 'success') {
        return true;
      }
      if (status == 'in progress') {
        stdio.printStatus('job $uuid still pending');
        return false;
      }
      throw ConductorException('Notarization failed with: $status\n$combinedOutput');
    }
  }

  static final RegExp _altoolRequestPattern = RegExp(r'RequestUUID = ([a-z0-9-]+)');
  static final RegExp _notarytoolRequestPattern = RegExp(r'id: ([a-z0-9-]+)');

  String uploadZipToNotary(File localFile, [int retryCount = 3]) {
    while (retryCount > 0) {
      List<String> args;
      if (isNotaryTool) {
        args = <String>[
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
      } else {
        args = <String>[
          'xcrun',
          'altool',
          '--notarize-app',
          '--primary-bundle-id',
          codesignPrimaryBundleId,
          '--username',
          codesignUserName,
          '--password',
          appSpecificPassword,
          '--file',
          localFile.absolute.path,
        ];
      }

      stdio.printStatus('uploading ${args.join(' ')}');
      // altool utilizes file locks, so run this synchronously
      final io.ProcessResult result = processManager.runSync(args);

      // Note that this tool outputs to STDOUT on Xcode 11, STDERR on earlier
      final String combinedOutput = (result.stdout as String) + (result.stderr as String);
      final RegExpMatch? match;
      if (isNotaryTool) {
        match = _notarytoolRequestPattern.firstMatch(combinedOutput);
      } else {
        match = _altoolRequestPattern.firstMatch(combinedOutput);
      }
      if (match == null) {
        print('Failed to upload to the notary service with args: ${args.join(' ')}\n\n${combinedOutput.trim()}\n');
        retryCount -= 1;
        print('Trying again $retryCount more time${retryCount > 1 ? 's' : ''}...');
        io.sleep(const Duration(seconds: 1));
        continue;
      }

      final String requestUuid = match.group(1)!;
      print('RequestUUID for ${localFile.path} is: $requestUuid');

      return requestUuid;
    }
    throw ConductorException('Failed to upload ${localFile.path} to the notary service');
  }

  static const String gsCloudBaseUrl = r'gs://flutter_infra_release';

  Future<File> download(String remotePath, String localPath) async {
    final String source = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    final io.ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', source, localPath],
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to download $source');
    }
    return tempDir.fileSystem.file(localPath);
  }

  Future<void> upload(String localPath, String remotePath) async {
    final String fullRemotePath = '$gsCloudBaseUrl/flutter/$commitHash/$remotePath';
    final io.ProcessResult result = await processManager.run(
      <String>['gsutil', 'cp', localPath, fullRemotePath],
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to upload $localPath to $fullRemotePath');
    }
  }

  Future<package_arch.Archive?> _unzip(File inputZip, Directory outDir) async {
    // unzip is faster, commenting it out to pass hash check
    if (processManager.canRun('unzip')) {
      await processManager.run(
        <String>[
          'unzip',
          inputZip.absolute.path,
          '-d',
          outDir.absolute.path,
        ],
      );
      print('the downloaded file is unzipped from ${inputZip.absolute.path} to ${outDir.absolute.path}');
      return null;
    } else {
      stdio.printError('unzip binary not found on path, falling back to package:archive implementation');
      final Uint8List bytes = await inputZip.readAsBytes();
      final package_arch.Archive archive = package_arch.ZipDecoder().decodeBytes(bytes);
      package_arch.extractArchiveToDisk(archive, outDir.path);
      return archive;
    }
  }

  Future<package_arch.Archive?> _zip(Directory inDir, File outputZip) async {
    // zip is faster
    if (processManager.canRun('zip')) {
      await processManager.run(
        <String>[
          'zip',
          '--symlinks',
          '--recurse-paths',
          outputZip.absolute.path,
          // use '.' so that the full absolute path is not encoded into the zip file
          '.',
          '--include',
          '*',
        ],
        workingDirectory: inDir.absolute.path,
      );
      return null;
    } else {
      stdio.printError('zip binary not found on path, falling back to package:archive implementation');
      final package_arch.Archive archive = package_arch.createArchiveFromDirectory(inDir);
      package_arch.ZipFileEncoder().zipDirectory(
        inDir,
        filename: outputZip.absolute.path,
      );
      return archive;
    }
  }

  /// Report binaries provided in configuration files, but not consumed during the code sign process.
  Future<void> _checkUnusedFiles() {
    int diffs = 0;
    for (final String filename in fileWithEntitlements!) {
      if (!fileConsumed.contains(filename)) {
        stdio.printError('\nwarning: The value $filename in entitlements file was not consumed.\n');
        diffs += 1;
      }
    }
    for (final String filename in fileWithoutEntitlements!) {
      if (!fileConsumed.contains(filename)) {
        stdio.printError('\nwarning: The value $filename in Non-entitlements file was not consumed.\n');
        diffs += 1;
      }
    }
    if (diffs > 0) {
      throw '$diffs diffs found!\n';
    }
    return Future.value(null);
  }

  Future<File?> _validateFileExists(ArchiveFile archiveFile, {bool silent = false}) async {
    FileSystem fs = tempDir.fileSystem;
    final String filePath = archiveFile.path;
    final File file = fs.file(filePath);
    if (!silent && !(await file.exists())) {
      throw Exception('${file.absolute.path} was expected to exist but does not!');
    }
    if (silent) {
      return null;
    }
    return file;
  }

  /// Extract entitlements configurations from downloaded zip files. Parse and store these configurations.
  ///
  /// File paths of entilement files and non entitlement files will be parsed and stored in [fileWithEntitlements].
  /// File path patterns accomodate special cases such as darwin-x64/FlutterMacOS.framework.zip/FlutterMacOS.framework.zip/Versions/A/FlutterMacOS,
  /// in which case the `unzip input -d output` command would produce another FlutterMacOS.framework.zip file
  Future<Set<String>> parseEntitlements(Directory parent, bool entitlements) async {
    final FileSystem fs = tempDir.fileSystem;
    String entitlementFilePath = entitlements
        ? fs.path.join(parent.path, 'entitlements.txt')
        : fs.path
            .join(parent.path, 'withoutEntitlements.txt'); // TODO(xilaizhang): switch this back to normal environment
    if (!(await fs.file(entitlementFilePath).exists())) {
      entitlementFilePath = entitlements
          ? ('/Users/xilaizhang/Desktop/entitlements.txt')
          : ('/Users/xilaizhang/Desktop/withoutEntitlements.txt'); //TODO(xilaizhang): this is for testing
      if (!(await fs.file(entitlementFilePath).exists())) {
        throw Exception("\n entitilements configuration files are not detected \n"
            "make sure you have provided them along with the engine artifacts \n");
      }
    }

    Set<String> fileWithEntitlements = <String>{};
    await io.File(entitlementFilePath)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .forEach((String singleFileRelativePath) {
      // add the logical path of each file with entitlement
      fileWithEntitlements.add(singleFileRelativePath);
    });
    return fileWithEntitlements;
  }
}
