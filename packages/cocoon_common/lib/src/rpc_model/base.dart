// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// The base type for a model.
///
/// This type exists for uniformity, and not part of the public API.
@immutable
@internal
abstract base mixin class Model {
  static const _deepEquality = DeepCollectionEquality();

  @override
  @nonVirtual
  bool operator ==(Object other) {
    if (other is! Model || runtimeType != other.runtimeType) {
      return false;
    }
    return _deepEquality.equals(toJson(), other.toJson());
  }

  @override
  @nonVirtual
  int get hashCode => _deepEquality.hash(toJson());

  /// Returns a JSON-encodable representation of the model.
  ///
  /// **NOTE**: In practice, this should only be used in testing or for local
  /// serialization (i.e. local-storage), and for making calls to the backend
  /// prefer an explicit sub-set of the object:
  ///
  /// ```dart
  /// // GOOD
  /// await makeRpcCall({
  ///   'commit': commit.sha,
  /// });
  ///
  /// // BAD
  /// await makeRpcCall({
  ///   'commit': commit,
  /// })
  /// ```
  Map<String, Object?> toJson();

  @override
  @nonVirtual
  String toString() {
    return '$runtimeType ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}
