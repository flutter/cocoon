// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../models/repositories.dart';

const String kEngineStr = 'engine';
const String kFrameworkStr = 'framework';
const String kFlutterStr = 'flutter';

/// Returns the string 'engine' or 'framework' based on the [Repositories] enum.
///
/// Also supports returning first letter capitalized string.
String repositoriesStr(Repositories repository, [bool? capitalized = false]) {
  if (capitalized == true) {
    return repository == Repositories.engine ? capitalizeFirstLetter(kEngineStr) : capitalizeFirstLetter(kFrameworkStr);
  }
  return repository == Repositories.engine ? kEngineStr : kFrameworkStr;
}

/// Returns the string 'engine' or 'flutter' based on the [Repositories] enum.
///
/// Also supports returning first letter capitalized string.
String repositoriesStrFlutter(Repositories repository, [bool? capitalized = false]) {
  if (capitalized == true) {
    return repository == Repositories.engine ? capitalizeFirstLetter(kEngineStr) : capitalizeFirstLetter(kFlutterStr);
  }
  return repository == Repositories.engine ? kEngineStr : kFlutterStr;
}

/// Capitalizes the first letter of a string.
///
/// If the string is empty, returns an empty string.
String capitalizeFirstLetter(String input) {
  if (input == '') return input;
  return ('${input[0].toUpperCase()}${input.substring(1)}');
}
