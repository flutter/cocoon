// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Logging severity levels, from _least_ important to _most_ important.
///
/// The levels are based on what is available for [Google Cloud Logging][gcl],
/// and [Firebase][fbl].
///
/// [gcl]: https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#logseverity
/// [fbl]: https://firebase.google.com/docs/functions/writing-and-viewing-logs?gen=2nd
enum Severity implements Comparable<Severity> {
  /// Unknown or undefined severity.
  ///
  /// Should only be used when mapping from another severity format where an
  /// explicit failure is not appropriate (i.e. deserialization or storage).
  ///
  /// In practice unknown severity should be ignored in production apps.
  unknown,

  /// Debug or trace information.
  ///
  /// Production apps will often completely omit debug logs.
  debug,

  /// Rotuine information, such as ongoing status or performance.
  info,

  /// Normal but significant events, such as configuration changes.
  notice,

  /// Events that _might_ be a sign or cause of problems.
  ///
  /// A warning (or higher) should be actionable, that is, should be an
  /// indication of a bug or state problem within the app that should be
  /// corrected by future development. For example, having to fallback to
  /// a different API or skipping a non-critical task is often a warning.
  warning,

  /// Events that _are likely_ to be a sign of or cause problems.
  ///
  /// An error should be an indication of non-fatal state, and often will
  /// include an exception and/or stack trace. For example, failing to read
  /// from the database or read from an API is often an error.
  error,

  /// Events that cause more severe problems or outages.
  ///
  /// A _critical_ error is an indication of non-fatal state that can cause
  /// outages. For example, failing to update the database or call a mutating
  /// API to reflect the current state is often a critical error.
  critical,

  /// Events that are unambigously a sign of requiring human intervention.
  alert,

  /// Events that indicate a critical system is offline or completely unusable.
  emergency;

  @override
  int compareTo(Severity other) => index.compareTo(other.index);

  bool operator >(Severity other) => compareTo(other) > 0;

  bool operator >=(Severity other) => compareTo(other) >= 0;

  bool operator <(Severity other) => compareTo(other) < 0;

  bool operator <=(Severity other) => compareTo(other) <= 0;
}
