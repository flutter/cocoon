// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

var gitHashPattern = r'[0-9a-f]{5,40}';

// Allows empty string because the dart revision which is the only input using this regex could be empty
final RegExp gitHashRegex = RegExp([r'^$|^', gitHashPattern, r'$'].join());

/// Supports multiple git hashes delimited by a comma or an empty string.
///
/// valid: c7714158950347,c7714158950347,c7714158950347
/// valid: c7714158950347
/// unvalid:   c7714158950347,@@cccccc
/// unvalid (cannot end with a comma):   c7714158950347,c7714158950347,
var multiGitHashPattern = [r'^$|^', gitHashPattern, r'(?:,', gitHashPattern, r')*$'].join();

final RegExp multiGitHashRegex = RegExp(multiGitHashPattern);
