// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:cocoon_service/protos.dart' show Agent, CommitStatus, Task;

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

    return FakeCocoonService();
  }

  /// Gets build information from the last 200 commits.
  ///
  // TODO(chillers): Make configurable to get range of commits, https://github.com/flutter/cocoon/issues/458
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses();

  /// Gets the current build status of flutter/flutter.
  Future<CocoonResponse<bool>> fetchTreeBuildStatus();

  /// Get the current Flutter infra agent statuses.
  Future<CocoonResponse<List<Agent>>> fetchAgentStatuses();

  /// Send rerun [Task] command to devicelab.
  ///
  /// Will not rerun tasks that are outside of devicelab.
  Future<bool> rerunTask(Task task, String idToken);

  /// Writes the log for [Task] to local storage of the current device.
  /// Returns true if successful, false if failed.
  Future<bool> downloadLog(Task task, String idToken, String commitSha);

  /// Creates [Agent] with the given information.
  ///
  /// Returns an auth token used to authorize the agent.
  Future<CocoonResponse<String>> createAgent(
      String agentId, List<String> capabilities, String idToken);

  /// Generate a new access token for [agent].
  Future<CocoonResponse<String>> authorizeAgent(Agent agent, String idToken);

  /// Attempt to assign a new task to [agent].
  ///
  /// If no task can be assigned, a null value is returned.
  Future<void> reserveTask(Agent agent, String idToken);
}

/// Wrapper class for data this state serves.
///
/// Holds [data] and possible error information.
class CocoonResponse<T> {
  /// The data that gets used from [CocoonService].
  T data;

  /// Error information that can be used for debugging.
  String error;
}
