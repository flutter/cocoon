// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;

/// Signature for a function that returns an [HttpClient].
///
/// This is used by [CronAuthProvider] to provide the HTTP client that
/// will be used (if necessary) to verify OAuth ID tokens (JWT tokens).
typedef HttpClientProvider = http.Client Function();
