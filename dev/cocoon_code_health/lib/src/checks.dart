// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';

/// A check that can be made against a file.
abstract base class Check {
  const Check();

  /// What files should be checked by this check.
  ///
  /// Assume the context is relative to a package root.
  Glob get shouldCheck;

  /// Whether to exclude certian files from this check.
  ///
  /// If omitted, does nothing.
  ///
  /// Assume the context is relative to the Cocoon repository root.
  Iterable<Glob> get allowListed => const [];

  /// Checks [file] for violations of `this`.
  ///
  /// May optionally emit diagnostic information to [logger].
  Future<CheckResult> check(LogSink logger, File file);
}

/// Possible reuslts for [Check.check].
enum CheckResult { failed, passed }
