// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Converts the error and stack trace objects to strings for display.
String errorToString(Object error, StackTrace stackTrace) {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln('${error.runtimeType}:\n$error');
  buffer.writeln('');
  buffer.writeln('Stack Trace:\n$stackTrace');
  return buffer.toString();
}
