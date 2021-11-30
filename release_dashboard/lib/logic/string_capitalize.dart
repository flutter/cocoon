// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extension StringExtension on String {
  /// Extension method added on [String] that capitalizes the first letter of a string.
  ///
  /// If the string is empty, returns an empty string.
  ///
  /// In order to use this extended method, one can simply call:
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// import "repositories_str.dart";
  ///
  /// var capitalizedString = 'unCapitalized'.capitalize();
  /// ```
  /// {@end-tool}
  String capitalize() {
    if (this == '') return this;
    return ('${this[0].toUpperCase()}${substring(1)}');
  }
}
