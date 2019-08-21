// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';

import 'typedefs.dart';

class Providers {
  const Providers._();

  /// Default [HttpClient] provider.
  ///
  /// See also:
  ///
  ///  * [HttpClientProvider], which defines this interface.
  static HttpClient freshHttpClient() => HttpClient();

  /// Default [Logging] provider.
  ///
  /// See also:
  ///
  ///  * [LoggingProvider], which defines this interface.
  static Logging serviceScopeLogger() => loggingService;
}
