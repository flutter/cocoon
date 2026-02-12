// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;

import 'context.dart';

/// Signature for a function that returns an App Engine [ClientContext].
///
/// This is used in [AuthenticationProvider] to provide the client context
/// as part of the [AuthenticatedContext].
typedef ClientContextProvider = ClientContext Function();

/// Signature for a function that returns an [HttpClient].
///
/// This is used by [AuthenticationProvider] to provide the HTTP client that
/// will be used (if necessary) to verify OAuth ID tokens (JWT tokens).
typedef HttpClientProvider = http.Client Function();
