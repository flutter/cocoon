// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:conductor_core/conductor_core.dart'
    show Checkouts, EngineRepository, FrameworkRepository, Stdio, VerboseStdio, defaultStateFilePath, readStateFromFile;
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'conductor.dart';
import 'release_dashboard_start_context.dart';

/// Service class for using the conductor in a local environment.
///
/// This is the production version of the conductor, only intended for releases.
class LocalConductorService extends ConductorService {
  final FileSystem fs = const LocalFileSystem();
  final Platform platform = const LocalPlatform();
  final ProcessManager processManager = const LocalProcessManager();
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );

  late Directory _engineCheckoutDirectory;
  late Directory _frameworkCheckoutDirectory;

  @override
  Directory get rootDirectory => fs.directory(platform.environment['HOME']);
  File get stateFile => fs.file(defaultStateFilePath(platform));

  @override
  Directory get engineCheckoutDirectory => _engineCheckoutDirectory;

  @override
  Directory get frameworkCheckoutDirectory => _frameworkCheckoutDirectory;

  @override
  pb.ConductorState? get state {
    if (stateFile.existsSync()) {
      return readStateFromFile(stateFile);
    }
    return null;
  }

  @override
  Future<void> createRelease({
    required String candidateBranch,
    required String? dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required String incrementLetter,
    required String releaseChannel,
  }) async {
    final Checkouts checkouts = Checkouts(
      parentDirectory: rootDirectory,
      processManager: processManager,
      fileSystem: fs,
      platform: platform,
      stdio: stdio,
    );
    final ReleaseDashboardStartContext startContext = ReleaseDashboardStartContext(
      candidateBranch: candidateBranch,
      checkouts: checkouts,
      // TODO(yugue): Read conductor version. https://github.com/flutter/flutter/issues/92842
      conductorVersion: 'ui_0.1',
      dartRevision: dartRevision,
      engineCherrypickRevisions: engineCherrypickRevisions,
      engineMirror: engineMirror,
      engineUpstream: EngineRepository.defaultUpstream,
      frameworkCherrypickRevisions: frameworkCherrypickRevisions,
      frameworkMirror: frameworkMirror,
      frameworkUpstream: FrameworkRepository.defaultUpstream,
      incrementLetter: incrementLetter,
      processManager: processManager,
      releaseChannel: releaseChannel,
      stateFile: stateFile,
      // TODO(yugue): Add a button switch to toggle the force parameter of StartContext.
      // https://github.com/flutter/flutter/issues/94384
    );
    await startContext.run();
    _engineCheckoutDirectory = await startContext.engine.checkoutDirectory;
    _frameworkCheckoutDirectory = await startContext.framework.checkoutDirectory;
  }
}
