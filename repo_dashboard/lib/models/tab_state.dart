// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:localstorage/localstorage.dart';

const String _kPausedTabIndexStorageKey = 'paused-tab-index';

final LocalStorage storage = new LocalStorage('github.json');

int get pausedTabIndex {
  final String storedValue = storage.getItem(_kPausedTabIndexStorageKey);
  return storedValue == null ? null : math.max<int>(0, int.tryParse(storedValue));
}

set pausedTabIndex(int taxIndex) {
  storage.setItem(_kPausedTabIndexStorageKey, taxIndex.toString());
}

bool get isPaused {
  return storage.getItem(_kPausedTabIndexStorageKey) != null;
}

void pause(int taxIndex) {
  pausedTabIndex = taxIndex;
}

void play() {
  storage.deleteItem(_kPausedTabIndexStorageKey);
}
