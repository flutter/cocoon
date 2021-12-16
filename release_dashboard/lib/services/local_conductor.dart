// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:conductor_core/conductor_core.dart'
    show
        Checkouts,
        CleanContext,
        EngineRepository,
        FrameworkRepository,
        Stdio,
        VerboseStdio,
        defaultStateFilePath,
        readStateFromFile;
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:provider/provider.dart';

import '../state/status_state.dart';
import 'conductor.dart';
import 'release_dashboard_next_context.dart';
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

  late final Directory _engineCheckoutDirectory;
  late final Directory _frameworkCheckoutDirectory;

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

  late final Checkouts checkouts = Checkouts(
    parentDirectory: rootDirectory,
    processManager: processManager,
    fileSystem: fs,
    platform: platform,
    stdio: stdio,
  );

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
    required BuildContext context,
  }) async {
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
      // [context] cannot be passed beyong this point, because values returned from
      // the methods of [BuildContext] should not be cached beyond the execution of a
      // single synchronous function.
      syncStatusWithState: context.read<StatusState>().syncStatusWithState,
      dialogPromptChanger: super.dialogPromptChanger,
      // TODO(yugue): Add a button switch to toggle the force parameter.
      // https://github.com/flutter/flutter/issues/94384
    );
    await startContext.run();
    _engineCheckoutDirectory = await startContext.engine.checkoutDirectory;
    _frameworkCheckoutDirectory = await startContext.framework.checkoutDirectory;
  }

  @override
  Future<void> cleanRelease(BuildContext context) async {
    CleanContext cleanContext = CleanContext(stateFile: stateFile);
    await cleanContext.run();
    context.read<StatusState>().syncStatusWithState();
  }

  @override
  Future<void> conductorNext(BuildContext context) async {
    final ReleaseDashboardNextContext nextContext = ReleaseDashboardNextContext(
      // [context] cannot be passed beyong this point, because values returned from
      // the methods of [BuildContext] should not be cached beyond the execution of a
      // single synchronous function.
      syncStatusWithState: context.read<StatusState>().syncStatusWithState,
      autoAccept: false,
      // TODO(yugue): Add a button switch to toggle the force parameter.
      // https://github.com/flutter/flutter/issues/94384
      force: false,
      checkouts: checkouts,
      stateFile: stateFile,
      dialogPromptChanger: super.dialogPromptChanger,
    );
    await nextContext.run(state!);
  }
}
