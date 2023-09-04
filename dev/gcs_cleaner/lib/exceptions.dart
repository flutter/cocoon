// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class GcsCleanerException implements Exception {
  GcsCleanerException(this.message);

  final String message;

  @override
  String toString() => 'GCS Cleaner Exception: $message';
}

class GitException implements Exception {
  GitException(this.message);

  final String message;

  @override
  String toString() => 'Git Exception: $message';
}
