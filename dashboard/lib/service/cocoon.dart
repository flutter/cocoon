// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../model/branch.pb.dart';
import '../model/build_status_response.pb.dart';
import '../model/commit_status.pb.dart';
import '../model/commit_tasks_status.pb.dart';
import 'appengine_cocoon.dart';
import 'dev_cocoon.dart';

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
    return DevelopmentCocoonService(
      DateTime.now(),
      simulateLoadingDelays: true,
    );
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

  /// Gets build information on the most recent commits.
  ///
  /// If [lastCommitStatus] is given, it will return the next page of
  /// [List<CommitTasksStatus>] after [lastCommitStatus], not including it.
  Future<CocoonResponse<List<CommitTasksStatus>>> fetchCommitStatusesFirestore({
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

  /// Get the current list of version branches in flutter/flutter.
  Future<CocoonResponse<List<String>>> fetchRepos();

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
  });

  /// Force update Cocoon to get the latest commits.
  Future<bool> vacuumGitHubCommits(String idToken);
}

/// Wrapper class for data this state serves.
///
/// Holds [data] and possible error information.
@immutable
class CocoonResponse<T> {
  const CocoonResponse.data(this.data) : error = null;
  const CocoonResponse.error(this.error) : data = null;

  /// The data that gets used from [CocoonService].
  final T? data;

  /// Error information that can be used for debugging.
  final String? error;
}

/// This must be kept up to date with what's in app_dart/lib/src/service/config.dart.
final Map<String, String> defaultBranches = <String, String>{
  'cocoon': 'main',
  'flutter': 'master',
  'packages': 'main',
};
