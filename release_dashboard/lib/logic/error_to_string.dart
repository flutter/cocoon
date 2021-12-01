// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';

/// Converts the error and stack trace objects to strings for display.
String errorToString(Object error, StackTrace stackTrace) {
  final StringBuffer buffer = StringBuffer();
  if (error is ConductorException) {
    buffer.writeln('Conductor Exception:\n$error');
  } else {
    buffer.writeln('Error:\n$error');
  }
  buffer.writeln('\nStack Trace:\n$stackTrace');
  return buffer.toString();
}
