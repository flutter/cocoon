// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/proto/conductor_state.pb.dart';
import 'package:conductor_ui/services/conductor.dart';

import '../fake_start_context.dart';

/// Fake service class for using the conductor in a fake local environment.
///
/// When [fakeStartContextProvided] is not provided, the class initializes
/// a [createRelease] method that does not throw any error by default.
class FakeConductor extends ConductorService {
  FakeConductor({
    this.fakeStartContextProvided,
    this.testState,
  });

  final FakeStartContext? fakeStartContextProvided;
  final ConductorState? testState;

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
    if (fakeStartContextProvided != null) {
      return fakeStartContextProvided!.run();
    } else {
      /// If there is no [fakeStartContextProvided], initialize a fakeStartContext
      /// with no exception thrown when [run] is called.
      final FakeStartContext fakeStartContext = FakeStartContext(
        candidateBranch: candidateBranch,
        dartRevision: dartRevision,
        engineCherrypickRevisions: engineCherrypickRevisions,
        engineMirror: engineMirror,
        frameworkCherrypickRevisions: frameworkCherrypickRevisions,
        frameworkMirror: frameworkMirror,
        incrementLetter: incrementLetter,
        releaseChannel: releaseChannel,
      );
      return fakeStartContext.run();
    }
  }

  @override
  ConductorState? get state {
    return testState ??
        ConductorState(
          conductorVersion: 'abcdef',
          releaseChannel: 'dev',
          releaseVersion: '1.2.0-3.4.pre',
        );
  }
}
