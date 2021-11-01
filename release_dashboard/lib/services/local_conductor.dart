// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of String source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:conductor_core/conductor_core.dart'
    show Checkouts, StartContext, Stdio, VerboseStdio, defaultStateFilePath, readStateFromFile;
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'conductor.dart';

/// Service class for using the conductor in a local environment.
///
/// This is the production version of the conductor, only intended for releases.
class LocalConductorService extends ConductorService {
  final FileSystem fs = LocalFileSystem();
  final Platform platform = LocalPlatform();
  final ProcessManager processManager = LocalProcessManager();
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );

  Directory get rootDirectory => fs.directory(String.fromEnvironment('HOME'));
  File get stateFile => fs.file(defaultStateFilePath(platform));

  static const String frameworkUpstream = 'https://github.com/flutter/flutter';
  static const String engineUpstream = 'https://github.com/flutter/engine';

  pb.ConductorState? get state {
    if (stateFile.existsSync()) {
      return readStateFromFile(stateFile);
    }

    return null;
  }

  Future<void> createRelease({
    required String candidateBranch,
    required String dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required Directory flutterRoot,
    required String incrementLetter,
    required String releaseChannel,
    required File stateFile,
  }) async {
    final Checkouts checkouts = Checkouts(
      parentDirectory: rootDirectory,
      processManager: processManager,
      fileSystem: fs,
      platform: platform,
      stdio: stdio,
    );
    final StartContext startContext = StartContext(
      candidateBranch: candidateBranch,
      checkouts: checkouts,
      // TODO(yugue): Read conductor version. https://github.com/flutter/flutter/issues/92842
      conductorVersion: 'local',
      dartRevision: dartRevision,
      engineCherrypickRevisions: engineCherrypickRevisions,
      engineMirror: engineMirror,
      engineUpstream: engineUpstream,
      frameworkCherrypickRevisions: frameworkCherrypickRevisions,
      frameworkMirror: frameworkMirror,
      frameworkUpstream: frameworkUpstream,
      incrementLetter: incrementLetter,
      processManager: processManager,
      releaseChannel: releaseChannel,
      stateFile: stateFile,
      stdio: stdio,
    );
    return startContext.run();
  }
}
