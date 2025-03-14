// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@internal
library;

import 'package:meta/meta.dart';

/// Whether `assert` is enabled in the current runtime.
///
/// This will evaluate to `false` when an application is run normally
/// (i.e. `dart run` or similar for an AOT-compiled app), and `true` when
/// run in debug mode or a testing environment (i.e. `dart test`).
bool get assertionsEnabled {
  var enabled = false;
  assert(enabled = true);
  return enabled;
}
