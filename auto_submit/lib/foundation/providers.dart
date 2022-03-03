// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;

/// Signature for a function that returns an [http.Client].
typedef HttpProvider = http.Client Function();

/// Class that holds static default providers.
class Providers {
  const Providers._();

  /// Creates a [http.Client] that interacts with the internet.
  static http.Client freshHttpClient() => http.Client();
}
