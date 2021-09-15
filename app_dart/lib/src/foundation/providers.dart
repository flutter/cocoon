// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart' as gae;
import 'package:http/http.dart' as http;

import 'typedefs.dart';

/// Class that holds static default providers.
class Providers {
  const Providers._();

  /// Default [http.Client] provider.
  ///
  /// See also:
  ///
  ///  * [HttpClientProvider], which defines this interface.
  static http.Client freshHttpClient() => http.Client();

  /// Default [gae.Logging] provider.
  ///
  /// See also:
  ///
  ///  * [LoggingProvider], which defines this interface.
  static gae.Logging serviceScopeLogger() => gae.loggingService;

  /// Default [gae.ClientContext] provider.
  ///
  /// See also:
  ///
  ///  * [ClientContextProvider], which defines this interface.
  static gae.ClientContext serviceScopeContext() => gae.context;
}
