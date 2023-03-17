// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ConfigurationException implements Exception {
  /// Create a custom exception for Autosubmit Configuration Errors.
  ConfigurationException(this.cause);

  final String cause;

  @override
  String toString() => cause;
}