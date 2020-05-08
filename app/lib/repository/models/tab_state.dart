// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:math' as math;

const String _kPausedTabIndexStorageKey = 'paused-tab-index';

int get pausedTabIndex {
  final String storedValue = window.localStorage[_kPausedTabIndexStorageKey];
  return storedValue == null
      ? null
      : math.max<int>(0, int.tryParse(storedValue));
}

set pausedTabIndex(int taxIndex) {
  window.localStorage[_kPausedTabIndexStorageKey] = taxIndex.toString();
}

bool get isPaused {
  return window.localStorage.containsKey(_kPausedTabIndexStorageKey);
}

void pause(int taxIndex) {
  pausedTabIndex = taxIndex;
}

void play() {
  window.localStorage.remove(_kPausedTabIndexStorageKey);
}
