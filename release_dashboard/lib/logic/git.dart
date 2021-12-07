// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';

final RegExp gitHashRegex = RegExp(r'^[0-9a-f]{40}$');

abstract class GitValidation {
  /// Returns the regex needed to validate this type of input.
  RegExp get regex;

  /// Returns the error message when the regex validation fails.
  String get errorMsg;

  /// Uses [regex] to validate the input provided. Returns true if it is valid, false otherwise.
  ///
  /// This method calls [sanitize] before the validation.
  bool isValid(String? input);

  /// Removes irrelevant characters such as whitespaces.
  String sanitize(String? input);
}

/// Provides all the tools and methods to validate the candidate branch of a release.
class CandidateBranch extends GitValidation {
  final RegExp _candidateBranchRegex = RegExp(r'^flutter-(\d+)\.(\d+)-candidate\.(\d+)$');
  final String _candidateBranchErrorMsg = "Must be a valid candidate branch string, e.g. 'flutter-1.2-candidate.3'";

  @override
  RegExp get regex => _candidateBranchRegex;

  @override
  String get errorMsg => _candidateBranchErrorMsg;

  @override
  String sanitize(String? input) {
    return (input == null ? '' : input.trim()); // removes leading or trailing whitespaces
  }

  @override
  bool isValid(String? input) {
    return regex.hasMatch(sanitize(input));
  }
}

/// Provides all the tools and methods to validate a Git remote such as the engine mirror.
class GitRemote extends GitValidation {
  final String _githubRemoteErrorMsg = "Must be a valid GitHub remote string, e.g. 'git@github.com:user/flutter.git'";

  @override
  RegExp get regex => githubRemotePattern;

  @override
  String get errorMsg => _githubRemoteErrorMsg;

  @override
  String sanitize(String? input) {
    return (input == null ? '' : input.trim()); // removes leading or trailing whitespaces
  }

  @override
  bool isValid(String? input) {
    return regex.hasMatch(sanitize(input));
  }
}

/// Provides all the tools and methods to validate a multiple Git hash entry such as cherrypicks.
class MultiGitHash extends GitValidation {
  final String _multiGitHashErrorMsg =
      'Must be one or more groups of 40 alphanumeric characters delimited by a comma or an empty string.';

  @override
  RegExp get regex => gitHashRegex;

  @override
  String get errorMsg => _multiGitHashErrorMsg;

  @override
  String sanitize(String? input) {
    return (input!.replaceAll(' ', '')); // removes any whitespaces
  }

  @override
  bool isValid(String? input) {
    if (input == null || input == '' || sanitize(input) == '') {
      return true;
    } // allows empty input, and a string of only whitesplaces

    /// Supports multiple git hashes delimited by a comma.
    ///
    /// Every hash in the whole string must be valid.
    /// valid: c7714158950347bd54b1a33af20aaf902a6a0c41,c7714158950347bd54b1a33af20aaf902a6a0c42
    /// valid: c7714158950347bd54b1a33af20aaf902a6a0c41
    /// invalid:   c7714158950347bd54b1a33af20aaf902a6a0c41,@@cccccc
    /// invalid (cannot end with a comma):   c7714158950347bd54b1a33af20aaf902a6a0c41,c7714158950347bd54b1a33af20aaf902a6a0c42,
    List<bool> isEachHashValid = sanitize(input).split(',').map((String gitHash) {
      if (!regex.hasMatch(gitHash)) {
        return false;
      } else {
        return true;
      }
    }).toList();
    return !isEachHashValid.contains(false);
  }
}

/// Provides all the tools and methods to validate a single Git hash such as the dart revision.
class GitHash extends GitValidation {
  final String _gitHashErrorMsg = 'Must be 40 alphanumeric characters or an empty string.';

  @override
  RegExp get regex => gitHashRegex;

  @override
  String get errorMsg => _gitHashErrorMsg;

  @override
  String sanitize(String? input) {
    return (input!.trim()); // removes leading or trailing whitespaces
  }

  @override
  bool isValid(String? input) {
    if (input == null || input == '' || sanitize(input) == '') {
      return true;
    } // allows empty input, but only whitespaces are not allowed
    return regex.hasMatch(sanitize(input));
  }
}
