// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class NoBuildFoundException implements Exception {
  /// Create a custom exception for no build found Errors.
  NoBuildFoundException(this.cause);

  final String cause;

  @override
  String toString() => cause;
}

class UnfinishedBuildException implements Exception {
  /// Create a custom exception for an unfinished buildbucket build
  UnfinishedBuildException(this.cause);

  final String cause;

  @override
  String toString() => cause;
}
