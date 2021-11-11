// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart'
    show Checkouts, EngineRepository, FrameworkRepository, StartContext, Repository;
import 'package:file/file.dart';

import 'local_conductor.dart';

/// Service class for using a test conductor in a local environment.
///
/// This is not the production version of the conductor, only intended for test.
/// This service creates fake local upstream repos to simulate the production repos.
class TestLocalConductorService extends LocalConductorService {
  @override
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

    final FrameworkRepository localFramework = FrameworkRepository(checkouts);
    final Repository localFrameworkUpstream = await localFramework.cloneRepository('localFrameworkUpstream');

    final EngineRepository localEngine = EngineRepository(checkouts);
    final Repository localEngineUpstream = await localEngine.cloneRepository('localEngineUpstream');

    final StartContext startContext = StartContext(
      candidateBranch: candidateBranch,
      checkouts: checkouts,
      conductorVersion: 'ui_0.1',
      dartRevision: dartRevision,
      engineCherrypickRevisions: engineCherrypickRevisions,
      engineMirror: engineMirror,
      engineUpstream: (await localEngineUpstream.checkoutDirectory).path,
      frameworkCherrypickRevisions: frameworkCherrypickRevisions,
      frameworkMirror: frameworkMirror,
      frameworkUpstream: (await localFrameworkUpstream.checkoutDirectory).path,
      incrementLetter: incrementLetter,
      processManager: processManager,
      releaseChannel: releaseChannel,
      stateFile: stateFile,
      stdio: stdio,
    );
    return startContext.run();
  }
}
