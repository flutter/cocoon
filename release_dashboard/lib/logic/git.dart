// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';

abstract class GitValidation {
  /// Returns the regex needed to validate this type of input.
  RegExp get regex;

  /// Returns the error message when the regex validation fails.
  String get errorMsg;

  /// Uses [regex] to validate the input provided. Returns true if it is valid, false otherwise.
  ///
  /// This method calls [sanitize] before the validation.
  bool isValidate(String? input);

  /// Removes irrelevant characters such as whitespaces.
  String sanitize(String? input);
}

/// Provides all the tools and methods to validate the candidate branch of a release.
class CandidateBranch extends GitValidation {
  final RegExp _candidateBranchRegex = RegExp(r'^flutter-(\d+)\.(\d+)-candidate\.(\d+)$');
  final String _candidateBranchErrorMsg = "Must be a valid candidate branch string, e.g. 'flutter-1.2-candidate.3'";

  RegExp get regex => _candidateBranchRegex;

  String get errorMsg => _candidateBranchErrorMsg;

  String sanitize(String? input) {
    return (input == null ? '' : input.trim()); // removes leading or trailing whitespaces
  }

  bool isValidate(String? input) {
    return this.regex.hasMatch(this.sanitize(input));
  }
}

/// Provides all the tools and methods to validate a Git remote such as the engine mirror.
class GitRemote extends GitValidation {
  final String _githubRemoteErrorMsg = "Must be a valid Github remote string, e.g. 'git@github.com:user/flutter.git'";

  RegExp get regex => githubRemotePattern;

  String get errorMsg => _githubRemoteErrorMsg;

  String sanitize(String? input) {
    return (input == null ? '' : input.trim()); // removes leading or trailing whitespaces
  }

  bool isValidate(String? input) {
    return this.regex.hasMatch(this.sanitize(input));
  }
}

/// Provides all the tools and methods to validate a multiple Git hash entry such as cherrypicks.
class MultiGitHash extends GitValidation {
  /// Supports multiple git hashes delimited by a comma.
  ///
  /// valid: c7714158950347,c7714158950347,c7714158950347
  /// valid: c7714158950347
  /// invalid:   c7714158950347,@@cccccc
  /// invalid (cannot end with a comma):   c7714158950347,c7714158950347,
  final RegExp _multiGitHashRegex = RegExp(r'^[0-9a-z]{40}(?:,[0-9a-z]{40})*$');
  final String _multiGitHashErrorMsg =
      'Must be one or more groups of 40 alphanumeric characters delimited by a comma or an empty string.';

  RegExp get regex => _multiGitHashRegex;

  String get errorMsg => _multiGitHashErrorMsg;

  String sanitize(String? input) {
    return (input!.replaceAll(' ', '')); // removes any whitespaces
  }

  bool isValidate(String? input) {
    if (input == null || input == '' || this.sanitize(input) == '')
      return true; // allows empty input, and a string of only whitesplaces
    return this.regex.hasMatch(this.sanitize(input));
  }
}

/// Provides all the tools and methods to validate a single Git hash such as the dart revision.
class GitHash extends GitValidation {
  final RegExp _gitHashRegex = RegExp(r'^[0-9a-f]{40}$');
  final String _gitHashErrorMsg = 'Must be 40 alphanumeric characters or an empty string.';

  RegExp get regex => _gitHashRegex;

  String get errorMsg => _gitHashErrorMsg;

  String sanitize(String? input) {
    return (input!.trim()); // removes leading or trailing whitespaces
  }

  bool isValidate(String? input) {
    if (input == null || input == '' || this.sanitize(input) == '')
      return true; // allows empty input, but only whitespaces are not allowed
    return this.regex.hasMatch(this.sanitize(input));
  }
}
