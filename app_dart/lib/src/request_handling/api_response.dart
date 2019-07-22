// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Class that serves as the return value of [ApiRequestHandler.handleApiRequest].
@immutable
abstract class ApiResponse {
  /// Creates a new [ApiResponse].
  const ApiResponse();

  /// Serializes this response to a JSON-primitive map.
  Map<String, dynamic> toJson();
}
