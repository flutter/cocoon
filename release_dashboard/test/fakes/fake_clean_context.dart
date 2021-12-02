// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:file/file.dart';

/// Initializes a fake [CleanContext] in a fake local environment for testing.
///
/// [runOverride] parameter overrides the parent's [run] method if it is not null. Else the parent's
/// [run] method is used.
class FakeCleanContext implements CleanContext {
  FakeCleanContext({
    this.runOverride,
  });

  /// An optional override async callback for the real [run] method.
  Future<void> Function()? runOverride;

  /// Call the [runOverride] parameter if it is not null, else return a future that doesn't throw any error.
  @override
  Future<void> run() async {
    if (runOverride != null) {
      return runOverride!();
    }
  }

  @override
  File get stateFile => throw UnimplementedError();
}
