// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;

import 'context.dart';
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

  /// Initializes the [ClientContext] provider.
  ///
  /// This must be called before [serviceScopeContext] is used.
  static ClientContextProvider contextProvider = () => throw UnimplementedError('ClientContext provider not initialized');

  /// Default [ClientContext] provider.
  ///
  /// See also:
  ///
  ///  * [ClientContextProvider], which defines this interface.
  static ClientContext serviceScopeContext() => contextProvider();
}
