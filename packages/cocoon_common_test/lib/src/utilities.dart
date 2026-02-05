// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Polls [predicate] until it returns true or [timeout] passes.
Future<void> pollUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final expiration = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(expiration)) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(interval);
  }
  throw 'Timed out waiting for condition to be true';
}
