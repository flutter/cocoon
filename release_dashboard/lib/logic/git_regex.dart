// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Allows empty string because the dart revision which is the only input using this regex could be empty
final RegExp gitHashRegex = RegExp(r'^$|^[0-9a-f]{40}$');

/// Supports multiple git hashes delimited by a comma or an empty string.
///
/// valid: c7714158950347,c7714158950347,c7714158950347
/// valid: c7714158950347
/// invalid:   c7714158950347,@@cccccc
/// invalid (cannot end with a comma):   c7714158950347,c7714158950347,
var multiGitHashRegex = RegExp(r'^$|^[0-9a-z]{40}(?:,[0-9a-z]{40})*$');

final RegExp candidateBranchRegex = RegExp(r'^flutter-(\d+)\.(\d+)-candidate\.(\d+)$');
