// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../enums/engine_or_framework.dart';

/// Helper function that returns the string 'engine' or 'framework' based on the [engineOrFramework] enum.
///
/// Also supports returning first letter capitalized string.
String engineOrFrameworkStr(EngineOrFramework engineOrFramework, [bool? capitalized = false]) {
  if (capitalized == true) {
    return engineOrFramework == EngineOrFramework.engine ? 'Engine' : 'Framework';
  }
  return engineOrFramework == EngineOrFramework.engine ? 'engine' : 'framework';
}
