// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart' show Checkouts, EngineRepository, FrameworkRepository;
import 'local_conductor.dart';
import 'release_dashboard_start_context.dart';

/// Service class for using a development conductor in a local environment.
///
/// This is not the production version of the conductor, only intended for development.
///
/// This service creates fake local upstream repos to simulate the production repos.
/// This is because [run] of [StartContext] is disruptive and creates tags in the
/// flutter repos. This class is used in a development environment to prevent
/// accidently creating tags during development.
class DevLocalConductorService extends LocalConductorService {
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

    final FrameworkRepository localFrameworkUpstream = FrameworkRepository(
      checkouts,
      localUpstream: true,
      name: 'framework-upstream',
      additionalRequiredLocalBranches: [candidateBranch],
    );

    final EngineRepository localEngineUpstream = EngineRepository(
      checkouts,
      localUpstream: true,
      name: 'engine-upstream',
      additionalRequiredLocalBranches: [candidateBranch],
    );

    final ReleaseDashboardStartContext startContext = ReleaseDashboardStartContext(
      candidateBranch: candidateBranch,
      checkouts: checkouts,
      // TODO(yugue): Read conductor version. https://github.com/flutter/flutter/issues/92842
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
      // TODO(yugue): Add a button switch to toggle the force parameter of StartContext.
      // https://github.com/flutter/flutter/issues/94384
    );
    return startContext.run();
  }
}
