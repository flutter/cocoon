// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Class that represents an HTTP response body before it has been serialized.
@immutable
abstract class Body {
  /// Creates a new [Body].
  const Body();

  /// Value indicating that the HTTP response body should be empty.
  static const Body empty = _EmptyBody();

  /// Serializes this response body to a JSON-primitive map.
  Map<String, dynamic> toJson();
}

class _EmptyBody extends Body {
  const _EmptyBody();

  @override
  Map<String, dynamic> toJson() => throw StateError('Unreachable');
}
