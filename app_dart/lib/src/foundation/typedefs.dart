// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';

/// Signature for a function that returns an App Engine [ClientContext].
///
/// This is used in [AuthenticationProvider] to provide the client context
/// as part of the [AuthenticatedContext].
typedef ClientContextProvider = ClientContext Function();

/// Signature for a function that returns an [HttpClient].
///
/// This is used by [AuthenticationProvider] to provide the HTTP client that
/// will be used (if necessary) to verify OAuth ID tokens (JWT tokens).
typedef HttpClientProvider = HttpClient Function();

/// Signature for a function that returns a [Logging] instance.
///
/// This is used by [AuthenticationProvider] to provide the logger.
typedef LoggingProvider = Logging Function();
