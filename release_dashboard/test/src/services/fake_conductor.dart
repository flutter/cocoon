// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/proto/conductor_state.pb.dart';
import 'package:conductor_ui/services/conductor.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';

import 'fake_clean_context.dart';

class FakeConductor extends ConductorService {
  FakeConductor({
    this.fakeCleanContextProvided,
    this.testState,
  });

  final ConductorState? testState;
  final FakeCleanContext? fakeCleanContextProvided;

  final FileSystem fs = MemoryFileSystem.test();
  final Platform platform = FakePlatform(
    environment: <String, String>{'HOME': '/path/to/user/home'},
    operatingSystem: const LocalPlatform().operatingSystem,
    pathSeparator: r'/',
  );

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
  }) async {}

  @override
  Directory get rootDirectory => fs.directory(platform.environment['HOME']);

  @override
  ConductorState? get state {
    return testState;
  }

  /// If there is no [fakeCleanContextProvided], initialize a [FakeCleanContext]
  /// with no exception thrown when [run] is called.
  ///
  /// [run] also attempts to clean a fake state file.
  @override
  Future<void> cleanRelease(BuildContext context) async {
    if (fakeCleanContextProvided != null) {
      return fakeCleanContextProvided!.run();
    } else {
      final FakeCleanContext fakeCleanContext = FakeCleanContext();
      return fakeCleanContext.run();
    }
  }
}
