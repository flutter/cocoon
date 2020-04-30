// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show Agent, CommitStatus, Task;

import 'appengine_cocoon.dart';
import 'dev_cocoon.dart';

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
    return DevelopmentCocoonService(DateTime.now());
  }

  /// Gets build information on the most recent commits.
  ///
  /// If [lastCommitStatus] is given, it will return the next page of
  /// [List<CommitStatus>] after [lastCommitStatus], not including it.
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus lastCommitStatus,
    String branch,
  });

  /// Gets the current build status of flutter/flutter.
  Future<CocoonResponse<bool>> fetchTreeBuildStatus({
    String branch,
  });

  /// Get the current Flutter infra agent statuses.
  Future<CocoonResponse<List<Agent>>> fetchAgentStatuses();

  /// Get the current list of version branches in flutter/flutter.
  Future<CocoonResponse<List<String>>> fetchFlutterBranches();

  /// Send rerun [Task] command to devicelab.
  ///
  /// Will not rerun tasks that are outside of devicelab.
  Future<bool> rerunTask(Task task, String idToken, String commitSha);

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
@immutable
class CocoonResponse<T> {
  const CocoonResponse.data(this.data) : error = null;
  const CocoonResponse.error(this.error) : data = null;

  /// The data that gets used from [CocoonService].
  final T data;

  /// Error information that can be used for debugging.
  final String error;
}
