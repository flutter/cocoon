// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class NoDeviceFoundException implements Exception {
  NoDeviceFoundException(this.cause);

  final String cause;

  @override
  String toString() => cause;
}
