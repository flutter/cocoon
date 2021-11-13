// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';

/// Service class for interacting with the conductor library.
///
/// This exists as a common interface for user interface to rely on.
abstract class ConductorService {
  /// Returns the directory where checkout is saved.
  Directory get rootDirectory;

  /// Returns the current [pb.ConductorState] indicating the state of the current release.
  ///
  /// Returns null when there is no active release, such as in the case when first initialized.
  pb.ConductorState? get state;

  /// This is the first step of every release which creates the release branch.
  Future<void> createRelease({
    required String candidateBranch,
    required String dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required Directory flutterRoot,
    required String incrementLetter,
    required String releaseChannel,
    required File stateFile,
  });
}
