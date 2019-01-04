// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Convert an abbreviation to a string readable by Talkback and
/// VoiceOver.
///
/// Example: Convert "ms" to "milliseconds"
///
/// If the string is not known, the original value is returned.
String unitAbbreviationToName(String name) {
  switch (name) {
    case 'ms':
      return 'milliseconds';
    case 'μs':
      return 'microseconds';
    case 'KB':
      return 'kilobytes';
  }
  return name;
}

/// Returns a valid semantic index for even indexes. Useful for lists with dividers.
int evenSemanticIndexes(Widget child, int index) {
  if (index.isEven) {
    return index ~/ 2;
  }
  return null;
}