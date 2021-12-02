// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_ui/logic/error_to_string.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String errorMsg = 'Something went wrong';
  const String stackTraceMsg = 'This is the stackTrace';

  group('errorToString tests', () {
    test('errorToString displays the correct Conductor Exception with its stack trace', () async {
      late final String errorOutput;
      try {
        await Future.error(ConductorException(errorMsg), StackTrace.fromString(stackTraceMsg));
      } catch (err, stackTrace) {
        errorOutput = errorToString(err, stackTrace);
      }

      expect(errorOutput.contains('ConductorException:'), true);
      expect(errorOutput.contains(errorMsg), true);
      expect(errorOutput.contains('Stack Trace:'), true);
      expect(errorOutput.contains(stackTraceMsg), true);
    });

    test('errorToString displays the correct general exception with its stack trace', () async {
      late final String errorOutput;
      late final String runtimeType;
      try {
        await Future.error(Exception(errorMsg), StackTrace.fromString(stackTraceMsg));
      } catch (err, stackTrace) {
        runtimeType = '${err.runtimeType}';
        errorOutput = errorToString(err, stackTrace);
      }

      expect(errorOutput.contains(runtimeType), true);
      expect(errorOutput.contains(errorMsg), true);
      expect(errorOutput.contains('Stack Trace:'), true);
      expect(errorOutput.contains(stackTraceMsg), true);
    });
  });
}
