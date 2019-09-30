// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:cocoon_service/protos.dart' show CommitStatus;

import 'appengine_cocoon.dart';
import 'fake_cocoon.dart';

/// Service class for interacting with flutter/flutter build data.
///
/// This service exists as a common interface for getting build data from a data source.
abstract class CocoonService {
  /// Creates a new [CocoonService] based on if the Flutter app is in production.
  ///
  /// Production uses the Cocoon backend running on AppEngine.
  /// Otherwise, it uses fake data populated from a fake service.
  factory CocoonService() {
    if (kReleaseMode) {
      return AppEngineCocoonService();
    }

    // TODO(chillers): LocalCocoonService. https://github.com/flutter/cocoon/issues/442

    return FakeCocoonService();
  }

  /// Gets build information from the last 200 commits.
  ///
  /// TODO(chillers): Make configurable to get range of commits
  Future<List<CommitStatus>> fetchCommitStatuses();

  /// Gets the current build status of flutter/flutter.
  Future<bool> fetchTreeBuildStatus();
}
