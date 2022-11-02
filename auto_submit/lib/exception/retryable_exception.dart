// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// General exception for retryable error catching.
class RetryableException implements Exception {
  const RetryableException(this.cause);

  final String cause;

  @override
  String toString() => cause;
}
