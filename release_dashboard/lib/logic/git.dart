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
var multiGitHashRegex = RegExp(r'^$|^[0-9a-z]{40}(?:,[0-9a-z]{40})*$');
final String multiGitHashErrorMsg =
    'Must be one or more groups of 40 alphanumeric characters delimited by a comma or an empty string.';

final RegExp candidateBranchRegex = RegExp(r'^flutter-(\d+)\.(\d+)-candidate\.(\d+)$');
final String candidateBranchErrorMsg = "Must be a valid candidate branch string, e.g. 'flutter-1.2-candidate.3'";

final String githubRemoteErrorMsg = "Must be a valid Github remote string, e.g. 'git@github.com:user/flutter.git'";

/// Class that accepts only the index parameter as an identifier to the type of input.
class git {
  git({required this.index});

  final int index;

  /// Return the regex and the error message if the regex fails in a map for each type of input.
  Map<String, Object> getRegexAndErrorMsg() {
    switch (index) {
      case 0:
        return <String, Object>{'regex': candidateBranchRegex, 'errorMsg': candidateBranchErrorMsg};
      case 2:
      case 3:
        return <String, Object>{'regex': githubRemotePattern, 'errorMsg': githubRemoteErrorMsg};
      case 4:
      case 5:
        return <String, Object>{'regex': multiGitHashRegex, 'errorMsg': multiGitHashErrorMsg};
      case 6:
        return <String, Object>{'regex': gitHashRegex, 'errorMsg': gitHashErrorMsg};
      default:
        return <String, Object>{};
    }
  }
}
