// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Returns whether [builderName] "looks like" a build from `dart-internal`.
///
/// See https://github.com/flutter/flutter/issues/165718.
bool isTaskFromDartInternalBuilder({required String builderName}) {
  // TODO(matanlurey): Store this information in Task and remove this.
  return _isDartInternalBuilderName.hasMatch(builderName);
}

final _isDartInternalBuilderName = RegExp(
  r'(Linux|Mac|Windows)\s+(engine_release_builder|packaging_release_builder|flutter_release_builder)',
);
