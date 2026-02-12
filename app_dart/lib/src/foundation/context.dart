// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A context for the current request.
///
/// This abstracts the underlying App Engine context to avoid direct dependencies
/// on package:appengine in core logic.
abstract class ClientContext {
  /// Whether the application is running in the development environment.
  bool get isDevelopmentEnvironment;
}
