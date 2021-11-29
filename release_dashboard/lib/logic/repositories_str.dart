// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../models/repositories.dart';

const String kEngineRepo = 'engine';
const String kFrameworkRepo = 'framework';

/// Helper function that returns the string 'engine' or 'framework' based on the [Repositories] enum.
///
/// Also supports returning first letter capitalized string.
String repositoriesStr(Repositories repository, [bool? capitalized = false]) {
  if (capitalized == true) {
    return repository == Repositories.engine
        ? capitalizeFirstLetter(kEngineRepo)
        : capitalizeFirstLetter(kFrameworkRepo);
  }
  return repository == Repositories.engine ? kEngineRepo : kFrameworkRepo;
}

/// Capitalizes the first letter of a string.
///
/// If the string is empty, returns an empty string.
String capitalizeFirstLetter(String input) {
  if (input == '') return input;
  return ('${input[0].toUpperCase()}${input.substring(1)}');
}
