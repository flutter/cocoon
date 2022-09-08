// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class BigQueryException implements Exception {
  /// Create a custom exception for Big Query Errors.
  BigQueryException(this.cause);

  final String cause;

  @override
  String toString() => cause;
}
