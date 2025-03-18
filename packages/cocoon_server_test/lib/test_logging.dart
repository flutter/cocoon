// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
// ignore: implementation_imports
import 'package:cocoon_server/src/logging.dart' as internal;
import 'package:test_api/scaffolding.dart';

/// Overrides [internal.log2] to use a [BufferedLogger] per-test instance.
///
/// Note that by using this method, [internal.log], the production root logger
/// instance (https://github.com/flutter/flutter/issues/164652) is no longer
/// written to, meaning that assertions against it will need to be re-written.
///
/// To assert against [log2], use `package:cocoon_common_test`:
/// ```dart
/// // Has a single log message with a specific message:
/// expect(
///   log2,
///   bufferedLoggerOf(equals([
///     logThat(equals('A big bad thing happened!'))
///   ]))
/// );
/// ```
///
/// ## Setup
///
/// Should be invoked exactly once in `void main()` or similar:
/// ```dart
/// void main() {
///   useTestLoggerPerTest();
/// }
/// ```
///
/// ## Failing Tests
///
/// If the test would result in a failure the current log buffer is printed.
void useTestLoggerPerTest() {
  late BufferedLogger testLogger;

  setUp(() {
    internal.overrideLog2ForTesting(testLogger = BufferedLogger());
  });

  tearDown(() {
    printOnFailure('Log buffer: $testLogger');
  });
}
