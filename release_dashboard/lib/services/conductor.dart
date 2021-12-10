// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';
import 'package:flutter/material.dart';

import '../widgets/progression.dart' show DialogPromptChanger;

/// Service class for interacting with the conductor library.
///
/// This exists as a common interface for user interface to rely on.
abstract class ConductorService {
  late DialogPromptChanger dialogPromptChanger;

  /// Returns the directory where checkout is saved.
  Directory get rootDirectory;

  /// Returns the current [pb.ConductorState] indicating the state of the current release.
  ///
  /// Returns null when there is no active release, such as in the case when first initialized.
  pb.ConductorState? get state;

  /// Returns the directory where the engine checkout is being saved.
  ///
  /// Can only be called after [createRelease] has been ran correctly.
  /// Returns [rootDirectory] if it is called before [createRelease] or has not been initialized.
  Directory get engineCheckoutDirectory;

  /// Returns the directory where the framework checkout is being saved.
  ///
  /// Can only be called after [createRelease] has been ran correctly.
  /// Returns [rootDirectory] if it is called before [createRelease] or has not been initialized.
  Directory get frameworkCheckoutDirectory;

  /// This is the first step of every release which creates the release branch.
  Future<void> createRelease({
    required String candidateBranch,
    required String? dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required String incrementLetter,
    required String releaseChannel,
    required BuildContext context,
  });

  /// Deletes the current release state..
  ///
  /// Throws an exception if the file cannot be deleted or is not found.
  Future<void> cleanRelease(BuildContext context);

  /// Proceeds to the next phase of the release.
  Future<void> conductorNext(BuildContext context);
}
