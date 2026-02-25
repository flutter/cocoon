// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'is_dart_internal.dart';

/// The base URL for LUCI production logs.
const String luciProdLogBase = 'https://ci.chromium.org/p/flutter/builders';

/// The base URL for dart-internal logs.
const String dartInternalLogBase =
    'https://ci.chromium.org/p/dart-internal/builders';

/// Generates a LUCI UI URL for a build log.
String generateBuildLogUrl({
  required String buildName,
  required int buildNumber,
  bool isBringup = false,
}) {
  if (isTaskFromDartInternalBuilder(builderName: buildName)) {
    return Uri.https(
      'ci.chromium.org',
      '/p/dart-internal/builders/flutter/$buildName/$buildNumber',
    ).toString();
  } else {
    final pool = isBringup ? 'staging' : 'prod';
    return Uri.https(
      'ci.chromium.org',
      '/p/flutter/builders/$pool/$buildName/$buildNumber',
    ).toString();
  }
}
