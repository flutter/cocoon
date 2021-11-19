// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/proto/conductor_state.pb.dart';
import 'package:conductor_ui/services/conductor.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';

class FakeConductor extends ConductorService {
  FakeConductor({
    this.testState,
  });

  final ConductorState? testState;
  final FileSystem fs = MemoryFileSystem.test();
  final Platform platform = FakePlatform(
    environment: <String, String>{'HOME': '/path/to/user/home'},
    operatingSystem: const LocalPlatform().operatingSystem,
    pathSeparator: r'/',
  );

  @override
  Future<void> createRelease(
      {required String candidateBranch,
      required String dartRevision,
      required List<String> engineCherrypickRevisions,
      required String engineMirror,
      required List<String> frameworkCherrypickRevisions,
      required String frameworkMirror,
      required Directory flutterRoot,
      required String incrementLetter,
      required String releaseChannel,
      required File stateFile}) async {}

  @override
  Directory get rootDirectory => fs.directory(platform.environment['HOME']);

  @override
  ConductorState? get state {
    return testState;
  }
}
