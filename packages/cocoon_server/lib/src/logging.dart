// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

// Used to access the symbol `self`.
import 'logging.dart' as self;

/// A root application logger using the interface in `package:logging`.
///
/// This is being migrated to [log2], which uses a new interface. See
/// [#164652](https://github.com/flutter/flutter/issues/164652).
Logger log = Logger.root..level = Level.ALL;

/// A root application logger using the interface in `package:cocoon_common`.
LogSink get log2 => const DuringMigrationLogSink();

/// A narrow shim on top of [LogSink] that delegates to [log].
///
/// Used as the default implementation of [log2]. See
/// [#164652](https://github.com/flutter/flutter/issues/164652).
@visibleForTesting
final class DuringMigrationLogSink with LogSink {
  const DuringMigrationLogSink();

  static Level _toLevel(Severity severity) {
    return switch (severity) {
      Severity.unknown || Severity.debug => Level.FINE,
      Severity.info || Severity.notice => Level.INFO,
      Severity.warning => Level.WARNING,
      Severity.error ||
      Severity.critical ||
      Severity.alert ||
      Severity.emergency => Level.SEVERE,
    };
  }

  @override
  void log(
    String message, {
    Severity severity = Severity.info,
    Object? error,
    StackTrace? trace,
  }) {
    self.log.log(_toLevel(severity), message, error, trace);
  }
}
