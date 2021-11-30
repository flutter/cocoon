// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';

/// Initializes a fake [RunContext] in a fake local environment.
class FakeCleanContext extends RunContext {
  factory FakeCleanContext({
    File? stateFile,
    Future<void> Function()? runOverride,
  }) {
    final FileSystem fileSystem = MemoryFileSystem.test();
    stateFile ??= fileSystem.file(kStateFileName);
    return FakeCleanContext._(stateFile: stateFile);
  }

  FakeCleanContext._({
    required File stateFile,
  }) : super(stateFile: stateFile);

  /// An optional override async callback for the real [run] method.
  Future<void> Function()? runOverride;

  /// Either call [runOverride] if it is not null, else call [super.run].
  @override
  Future<void> run() {
    if (runOverride != null) {
      return runOverride!();
    }
    return super.run();
  }
}
