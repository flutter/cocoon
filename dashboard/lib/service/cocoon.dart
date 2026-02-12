// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:flutter/foundation.dart';

import 'appengine_cocoon.dart';
import 'integration_server_adapter.dart';
import 'scenarios.dart';

/// Service class for interacting with flutter/flutter build data.
///
/// This service exists as a common interface for getting build data from a data source.
abstract class CocoonService {
  /// Creates a new [CocoonService] based on if the Flutter app is in production.
  ///
  /// If `useProductionService` is true, then use the production Cocoon backend
  /// running on AppEngine, otherwise use fake data populated from a fake
  /// service. Defaults to production data on a release build, and fake data on
  /// a debug build.
  factory CocoonService({bool useProductionService = kReleaseMode}) {
    if (useProductionService) {
      return AppEngineCocoonService();
    }
    return IntegrationServerAdapter(IntegrationServer(), now: DateTime.now());
  }

  /// Gets build information on the most recent commits.
  ///
  /// If [lastCommitStatus] is given, it will return the next page of
  /// [List<CommitStatus>] after [lastCommitStatus], not including it.
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus? lastCommitStatus,
    String? branch,
    required String repo,
  });

  /// Gets the current build status of flutter/flutter.
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String? branch,
    required String repo,
  });

  /// Get the current list of version branches in flutter/flutter.
  Future<CocoonResponse<List<Branch>>> fetchFlutterBranches();

  /// Get the current list of repositories supported by Cocoon.
  Future<CocoonResponse<List<String>>> fetchRepos();

  /// Get the current list of manual tree status changes in a particular repo.
  Future<CocoonResponse<List<TreeStatusChange>>> fetchTreeStatusChanges({
    required String idToken,
    required String repo,
  });

  /// Adds a tree status change with an optional [reason].
  Future<CocoonResponse<void>> updateTreeStatus({
    required String idToken,
    required String repo,
    required TreeStatus status,
    String? reason,
  });

  /// Schedule the provided [task] to be re-run.
  Future<CocoonResponse<bool>> rerunTask({
    required String? idToken,
    required String taskName,
    required String commitSha,
    required String repo,
    required String branch,
  });

  /// Tell Cocoon to manually schedule (or reschedule) tasks for the given commit.
  Future<CocoonResponse<void>> rerunCommit({
    required String? idToken,
    required String commitSha,
    required String repo,
    required String branch,
    Iterable<TaskStatus>? include,
  });

  /// Force update Cocoon to get the latest commits.
  Future<CocoonResponse<bool>> vacuumGitHubCommits(
    String idToken, {
    required String repo,
    required String branch,
  });

  /// Get the current list of suppressed tests in a particular repo.
  Future<CocoonResponse<List<SuppressedTest>>> fetchSuppressedTests({
    String? repo,
  });

  /// Updates the suppression status of a test.
  ///
  /// [suppress] true means "suppress" (block tree), false means "unsuppress" (include test).
  Future<CocoonResponse<void>> updateTestSuppression({
    required String idToken,
    required String repo,
    required String testName,
    required bool suppress,
    String? issueLink,
    String? note,
  });

  /// Get the current list of merge queue hooks.
  Future<CocoonResponse<List<MergeGroupHook>>> fetchMergeQueueHooks({
    required String idToken,
  });

  /// Replay a GitHub webhook.
  Future<CocoonResponse<void>> replayGitHubWebhook({
    required String idToken,
    required String id,
  });

  /// Gets the presubmit guard status for a given [repo] and commit [sha].
  Future<CocoonResponse<PresubmitGuardResponse>> fetchPresubmitGuard({
    required String repo,
    required String sha,
  });

  /// Gets the details for a specific presubmit check.
  Future<CocoonResponse<List<PresubmitCheckResponse>>>
  fetchPresubmitCheckDetails({
    required int checkRunId,
    required String buildName,
  });

  /// Gets the presubmit guard summaries for a given [repo] and [pr].
  Future<CocoonResponse<List<PresubmitGuardSummary>>>
  fetchPresubmitGuardSummaries({required String repo, required String pr});

  /// Resets the data scenario for fake implementations.
  ///
  /// No-op for production services.
  void resetScenario(Scenario scenario) {}
}

/// Wrapper class for data this state serves.
///
/// Holds [data] and possible error information.
@immutable
class CocoonResponse<T> {
  const CocoonResponse.data(this.data, {this.statusCode = 200}) : error = null;
  const CocoonResponse.error(this.error, {required this.statusCode})
    : data = null;

  /// The data that gets used from [CocoonService].
  final T? data;

  /// Error information that can be used for debugging.
  final String? error;

  /// Which HTTP status code was emitted.
  final int statusCode;
}

/// This must be kept up to date with what's in app_dart/lib/src/service/config.dart.
final Map<String, String> defaultBranches = <String, String>{
  'cocoon': 'main',
  'flutter': 'master',
  'packages': 'main',
};
