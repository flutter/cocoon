// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';

/// Initializes a fake [CleanContext] in a fake local environment for testing.
///
/// [runOverride] parameter overrides the parent's [run] method if it is not null. Else the parent's
/// [run] method is used.
class FakeCleanContext extends CleanContext {
  factory FakeCleanContext({
    File? stateFile,
    Future<void> Function()? runOverride,
  }) {
    final FileSystem fileSystem = MemoryFileSystem.test();
    stateFile ??= fileSystem.file(kStateFileName);
    return FakeCleanContext._(
      stateFile: stateFile,
      runOverride: runOverride,
    );
  }

  FakeCleanContext._({
    required File stateFile,
    this.runOverride,
  }) : super(stateFile: stateFile);

  /// An optional override async callback for the real [run] method.
  Future<void> Function()? runOverride;

  /// Call the [runOverride] parameter if it is not null, else call the parent [run] method.
  @override
  Future<void> run() {
    if (runOverride != null) {
      return runOverride!();
    }
    return super.run();
  }
}
