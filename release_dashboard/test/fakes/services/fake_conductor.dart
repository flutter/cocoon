// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/proto/conductor_state.pb.dart';
import 'package:conductor_ui/services/conductor.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';

import '../fake_clean_context.dart';
import '../fake_next_context.dart';
import '../fake_start_context.dart';

/// Fake service class for using the conductor in a fake local environment.
///
/// When [fakeStartContextProvided] is not provided, the class initializes
/// a [createRelease] method that does not throw any error by default.
///
/// When [fakeNextContextProvided] is not provided, the class initializes
/// a [conductorNext] method that does not throw any error by default.
///
/// [testState] parameter accepts a fake test state and passes it to the
/// release dashboard.
class FakeConductor extends ConductorService {
  FakeConductor({
    this.fakeCleanContextProvided,
    this.fakeStartContextProvided,
    this.fakeNextContextProvided,
    this.testState,
  }) {
    /// If there is no [fakeCleanContextProvided], initialize a [FakeCleanContext]
    /// with no exception thrown when [run] is called.
    fakeCleanContextProvided ??= FakeCleanContext();
  }

  late FakeCleanContext? fakeCleanContextProvided;
  FakeStartContext? fakeStartContextProvided;
  FakeNextContext? fakeNextContextProvided;
  ConductorState? testState;

  final FileSystem fs = MemoryFileSystem.test();
  final Platform platform = FakePlatform(
    environment: <String, String>{'HOME': '/path/to/user/home'},
    operatingSystem: const LocalPlatform().operatingSystem,
    pathSeparator: r'/',
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
    BuildContext? context,
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
  Future<void> conductorNext(BuildContext context) async {
    if (fakeNextContextProvided != null) {
      return fakeNextContextProvided!.run(testState!);
    } else {
      final FakeNextContext fakeNextContext = FakeNextContext();
      return fakeNextContext.run(testState!);
    }
  }

  @override
  Directory get rootDirectory => fs.directory(platform.environment['HOME']);

  /// If there is no [testState] parameter passed, this getter simply returns a null state.
  ///
  /// A [testState] parameter simulates a conductor withtout a release state file initialized.
  @override
  ConductorState? get state {
    return testState;
  }

  @override
  Directory get engineCheckoutDirectory => fs.directory('${rootDirectory.path}/flutter_conductor_checkouts/engine');

  @override
  Directory get frameworkCheckoutDirectory =>
      fs.directory('${rootDirectory.path}/flutter_conductor_checkouts/framework');

  @override
  Future<void> cleanRelease(BuildContext context) async {
    return fakeCleanContextProvided?.run();
  }
}
