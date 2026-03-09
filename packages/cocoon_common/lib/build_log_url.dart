// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'is_dart_internal.dart';

/// The base URL for LUCI production logs.
const String luciProdLogBase = 'https://ci.chromium.org/p/flutter/builders';

/// The base URL for dart-internal logs.
const String dartInternalLogBase =
    'https://ci.chromium.org/p/dart-internal/builders';

/// Generates a LUCI UI URL for a postsubmit build log.
///
/// The [isBringup] flag configures the URL to target the staging builder pool
/// (if true) rather than the default production pool. [buildName] and
/// [buildNumber] are required to identify the specific build.
String generatePostSubmitBuildLogUrl({
  required String buildName,
  required int buildNumber,
  bool isBringup = false,
}) {
  return _generateBuildLogUrl(
    buildName: buildName,
    buildNumber: buildNumber,
    buildersGroup: isBringup
        ? BuildersGroup.flutterStaging
        : BuildersGroup.flutter,
  );
}

/// Generates a LUCI UI URL for a presubmit build log.
///
/// Targets the try builder pool. [buildName] and [buildNumber] are required
/// to identify the specific build.
String generatePreSubmitBuildLogUrl({
  required String buildName,
  required int buildNumber,
}) {
  return _generateBuildLogUrl(
    buildName: buildName,
    buildNumber: buildNumber,
    buildersGroup: BuildersGroup.flutterTryBuilders,
  );
}

String _generateBuildLogUrl({
  required String buildName,
  required int buildNumber,
  required BuildersGroup buildersGroup,
}) {
  if (isTaskFromDartInternalBuilder(builderName: buildName)) {
    return Uri.https(
      'ci.chromium.org',
      '/p/dart-internal/builders/flutter/$buildName/$buildNumber',
    ).toString();
  } else {
    return Uri.https(
      'ci.chromium.org',
      '/p/flutter/builders/${buildersGroup.value}/$buildName/$buildNumber',
    ).toString();
  }
}

/// Represents the group or pool of builders running the task.
///
/// Corresponds to the segment in the LUCI URL path to target
/// specific builder groups (like 'prod', 'staging', or 'try').
enum BuildersGroup {
  /// The production builders pool.
  flutter('prod'),

  /// The staging builders pool for bringup tasks.
  flutterStaging('staging'),

  /// The try builders pool for presubmit tasks.
  flutterTryBuilders('try');

  const BuildersGroup(this.value);

  /// The string value representing this group in a LUCI URL.
  final String value;
}
