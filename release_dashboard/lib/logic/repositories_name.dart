// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../models/repositories.dart';
import 'string_capitalize.dart';

const String kEngineRepo = 'engine';
const String kFrameworkRepo = 'framework';
const String kFlutterRepo = 'flutter';

/// Returns the string 'engine' or 'framework' based on the [Repositories] enum.
///
/// Also supports returning first letter capitalized string.
// TODO(Yugue): [conductor] add a method that returns the repository names,
// https://github.com/flutter/flutter/issues/94388.
String repositoryName(Repositories repository, [bool? capitalized = false]) {
  if (capitalized == true) {
    return repository == Repositories.engine ? kEngineRepo.capitalize() : kFrameworkRepo.capitalize();
  }
  return repository == Repositories.engine ? kEngineRepo : kFrameworkRepo;
}

/// Returns the string 'engine' or 'flutter' based on the [Repositories] enum.
///
/// Also supports returning first letter capitalized string.
String repositoryNameAlt(Repositories repository, [bool? capitalized = false]) {
  if (capitalized == true) {
    return repository == Repositories.engine ? kEngineRepo.capitalize() : kFlutterRepo.capitalize();
  }
  return repository == Repositories.engine ? kEngineRepo : kFlutterRepo;
}
