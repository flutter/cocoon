// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';

// Allows empty string because the dart revision which is the only input using this regex could be empty
final RegExp gitHashRegex = RegExp(r'^$|^[0-9a-f]{40}$');
final String gitHashErrorMsg = 'Must be 40 alphanumeric characters or an empty string.';

/// Supports multiple git hashes delimited by a comma or an empty string.
///
/// valid: c7714158950347,c7714158950347,c7714158950347
/// valid: c7714158950347
/// invalid:   c7714158950347,@@cccccc
/// invalid (cannot end with a comma):   c7714158950347,c7714158950347,
final RegExp multiGitHashRegex = RegExp(r'^$|^[0-9a-z]{40}(?:,[0-9a-z]{40})*$');
final String multiGitHashErrorMsg =
    'Must be one or more groups of 40 alphanumeric characters delimited by a comma or an empty string.';

final RegExp candidateBranchRegex = RegExp(r'^flutter-(\d+)\.(\d+)-candidate\.(\d+)$');
final String candidateBranchErrorMsg = "Must be a valid candidate branch string, e.g. 'flutter-1.2-candidate.3'";

final String githubRemoteErrorMsg = "Must be a valid Github remote string, e.g. 'git@github.com:user/flutter.git'";

/// Class that accepts only the index parameter as an identifier to the type of input.
class git {
  git({required this.name});

  final String name;

  /// Return the regex and the error message if the regex fails in a map for each type of input.
  Map<String, Object> getRegexAndErrorMsg() {
    switch (name) {
      case 'Candidate Branch':
        return <String, Object>{'regex': candidateBranchRegex, 'errorMsg': candidateBranchErrorMsg};
      case 'Framework Mirror':
      case 'Engine Mirror':
        return <String, Object>{'regex': githubRemotePattern, 'errorMsg': githubRemoteErrorMsg};
      case 'Engine Cherrypicks (if necessary)':
      case 'Framework Cherrypicks (if necessary)':
        return <String, Object>{'regex': multiGitHashRegex, 'errorMsg': multiGitHashErrorMsg};
      case 'Dart Revision (if necessary)':
        return <String, Object>{'regex': gitHashRegex, 'errorMsg': gitHashErrorMsg};
      default:
        return <String, Object>{};
    }
  }
}

abstract class gitValidation {
  /// Returns the regex needed to validate this type of input.
  RegExp get regex;

  /// Returns the error message if the regex validation fails.
  String get errorMsg;

  /// Uses [regex] to validate the input provided. Returns true if it is valid, false otherwise.
  bool isValidate(String? input);
}

/// Provides all the tools and methods to validate a single Git hash such as the dart revision.
class gitHash extends gitValidation {
  // Allows empty string because the dart revision which is the only input using this regex could be empty
  final RegExp gitHashRegex = RegExp(r'^$|^[0-9a-f]{40}$');
  final String gitHashErrorMsg = 'Must be 40 alphanumeric characters or an empty string.';

  RegExp get regex => gitHashRegex;

  String get errorMsg => gitHashErrorMsg;

  bool isValidate(String? input) {
    return this.regex.hasMatch(input == null ? '' : input.trim()); // removes leading or trailing whitespaces
  }
}

/// Provides all the tools and methods to validate a multiple Git hash entry such as cherrypicks.
class multiGitHash extends gitValidation {
  /// Supports multiple git hashes delimited by a comma or an empty string.
  ///
  /// valid: c7714158950347,c7714158950347,c7714158950347
  /// valid: c7714158950347
  /// invalid:   c7714158950347,@@cccccc
  /// invalid (cannot end with a comma):   c7714158950347,c7714158950347,
  final RegExp multiGitHashRegex = RegExp(r'^$|^[0-9a-z]{40}(?:,[0-9a-z]{40})*$');
  final String multiGitHashErrorMsg =
      'Must be one or more groups of 40 alphanumeric characters delimited by a comma or an empty string.';

  RegExp get regex => multiGitHashRegex;

  String get errorMsg => multiGitHashErrorMsg;

  bool isValidate(String? input) {
    return this.regex.hasMatch(input == null ? '' : input.replaceAll(' ', '')); // removes any whitespaces
  }
}

/// Provides all the tools and methods to validate a single Git branch such as the candidate branch.
class gitBranch extends gitValidation {
  final String githubRemoteErrorMsg = "Must be a valid Github remote string, e.g. 'git@github.com:user/flutter.git'";

  RegExp get regex => githubRemotePattern;

  String get errorMsg => githubRemoteErrorMsg;

  bool isValidate(String? input) {
    return this.regex.hasMatch(input == null ? '' : input.trim()); // removes leading or trailing whitespaces
  }
}
