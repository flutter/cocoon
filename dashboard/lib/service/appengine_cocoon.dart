// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;

import 'cocoon.dart';
import 'scenarios.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client? client})
    : _client = client ?? http.Client();

  @override
  void resetScenario(Scenario scenario) {}

  /// Branch on flutter/flutter to default requests for.
  final String _defaultBranch = 'master';

  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const String _baseApiUrl = 'flutter-dashboard.appspot.com';

  /// Json keys from response data.
  static const String kCommitAvatar = 'Avatar';
  static const String kCommitAuthor = 'Author';
  static const String kCommitBranch = 'Branch';
  static const String kCommitCreateTimestamp = 'CreateTimestamp';
  static const String kCommitDocumentName = 'DocumentName';
  static const String kCommitMessage = 'Message';
  static const String kCommitRepositoryPath = 'RepositoryPath';
  static const String kCommitSha = 'Sha';

  static const String kTaskAttempts = 'Attempts';
  static const String kTaskBringup = 'Bringup';
  static const String kTaskBuildList = 'BuildList';
  static const String kTaskBuildNumber = 'BuildNumber';
  static const String kTaskCommitSha = 'CommitSha';
  static const String kTaskCreateTimestamp = 'CreateTimestamp';
  static const String kTaskDocumentName = 'DocumentName';
  static const String kTaskEndTimestamp = 'EndTimestamp';
  static const String kTaskStartTimestamp = 'StartTimestamp';
  static const String kTaskStatus = 'Status';
  static const String kTaskTaskName = 'TaskName';
  static const String kTaskTestFlaky = 'TestFlaky';

  final http.Client _client;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus? lastCommitStatus,
    String? branch,
    required String repo,
  }) async {
    final queryParameters = <String, String?>{
      if (lastCommitStatus != null)
        'lastCommitSha': lastCommitStatus.commit.sha,
      'branch': branch ?? _defaultBranch,
      'repo': repo,
    };
    final getStatusUrl = apiEndpoint(
      '/api/public/get-status',
      queryParameters: queryParameters,
    );

    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    final response = await _client.get(getStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<CommitStatus>>.error(
        '/api/public/get-status returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return CocoonResponse<List<CommitStatus>>.data(
        _commitStatusesFromJson(jsonResponse['Commits'] as List<Object?>),
      );
    } catch (error) {
      return CocoonResponse<List<CommitStatus>>.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<List<String>>> fetchRepos() async {
    final getReposUrl = apiEndpoint('/api/public/repos');

    // This endpoint returns a JSON array of strings.1
    final response = await _client.get(getReposUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<String>>.error(
        '$getReposUrl returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    List<String> repos;
    try {
      repos = List<String>.from(jsonDecode(response.body) as List<dynamic>);
    } on FormatException {
      return CocoonResponse<List<String>>.error(
        '$getReposUrl had a malformed response',
        statusCode: response.statusCode,
      );
    }
    return CocoonResponse<List<String>>.data(repos);
  }

  @override
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String? branch,
    required String repo,
  }) async {
    final queryParameters = <String, String?>{
      'branch': branch ?? _defaultBranch,
      'repo': repo,
    };
    final getBuildStatusUrl = apiEndpoint(
      '/api/public/build-status',
      queryParameters: queryParameters,
    );

    /// This endpoint returns JSON {AnticipatedBuildStatus: [BuildStatus]}
    final response = await _client.get(getBuildStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<BuildStatusResponse>.error(
        '/api/public/build-status returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    BuildStatusResponse protoResponse;
    try {
      protoResponse = BuildStatusResponse.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    } on FormatException {
      return CocoonResponse<BuildStatusResponse>.error(
        '/api/public/build-status had a malformed response',
        statusCode: response.statusCode,
      );
    }
    return CocoonResponse<BuildStatusResponse>.data(protoResponse);
  }

  @override
  Future<CocoonResponse<List<Branch>>> fetchFlutterBranches() async {
    final getBranchesUrl = apiEndpoint('/api/public/get-release-branches');

    /// This endpoint returns JSON {"Branches": List<String>}
    final response = await _client.get(getBranchesUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/public/get-release-branches returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as List<Object?>;
      final branches = <Branch>[];
      for (final jsonBranch in jsonResponse.cast<Map<String, Object?>>()) {
        branches.add(Branch.fromJson(jsonBranch));
      }
      return CocoonResponse<List<Branch>>.data(branches);
    } catch (error) {
      return CocoonResponse<List<Branch>>.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<List<TreeStatusChange>>> fetchTreeStatusChanges({
    required String idToken,
    required String repo,
  }) async {
    final getTreeStatusChangesUrl = apiEndpoint(
      '/api/get-tree-status',
      queryParameters: {'repo': repo},
    );

    final response = await _client.get(
      getTreeStatusChangesUrl,
      headers: {'X-Flutter-IdToken': idToken},
    );

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/get-tree-status returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as List<Object?>;
      final changes = <TreeStatusChange>[];
      for (final jsonChange in jsonResponse.cast<Map<String, Object?>>()) {
        changes.add(TreeStatusChange.fromJson(jsonChange));
      }
      return CocoonResponse.data(changes);
    } catch (error) {
      return CocoonResponse.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<List<SuppressedTest>>> fetchSuppressedTests({
    String? repo,
  }) async {
    final getSuppressedTestsUrl = apiEndpoint(
      '/api/public/suppressed-tests',
      queryParameters: {'repo': ?repo},
    );

    final response = await _client.get(getSuppressedTestsUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/public/suppressed-tests returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as List<Object?>;
      final suppressedTests = <SuppressedTest>[];
      for (final jsonTest in jsonResponse.cast<Map<String, Object?>>()) {
        suppressedTests.add(SuppressedTest.fromJson(jsonTest));
      }
      return CocoonResponse.data(suppressedTests);
    } catch (error) {
      return CocoonResponse.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<void>> updateTestSuppression({
    required String idToken,
    required String repo,
    required String testName,
    required bool suppress,
    String? issueLink,
    String? note,
  }) async {
    final updateTestSuppressionUrl = apiEndpoint('/api/update-suppressed-test');
    final response = await _client.post(
      updateTestSuppressionUrl,
      headers: {'X-Flutter-IdToken': idToken},
      body: jsonEncode({
        'repository': repo,
        'testName': testName,
        'action': suppress ? 'SUPPRESS' : 'UNSUPPRESS',
        'issueLink': ?issueLink,
        'note': ?note,
      }),
    );
    if (response.statusCode == HttpStatus.ok) {
      return const CocoonResponse.data(null);
    }
    return CocoonResponse.error(
      'HTTP Code: ${response.statusCode}, ${response.body}',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<CocoonResponse<PresubmitGuardResponse>> fetchPresubmitGuard({
    required String repo,
    required String sha,
  }) async {
    final queryParameters = <String, String?>{
      'slug': 'flutter/$repo',
      'sha': sha,
    };
    final getGuardUrl = apiEndpoint(
      '/api/public/get-presubmit-guard',
      queryParameters: queryParameters,
    );

    final response = await _client.get(getGuardUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/public/get-presubmit-guard returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      return CocoonResponse.data(
        PresubmitGuardResponse.fromJson(
          jsonDecode(response.body) as Map<String, Object?>,
        ),
      );
    } catch (error) {
      return CocoonResponse.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<List<PresubmitCheckResponse>>>
  fetchPresubmitCheckDetails({
    required int checkRunId,
    required String buildName,
  }) async {
    final queryParameters = <String, String?>{
      'check_run_id': checkRunId.toString(),
      'build_name': buildName,
    };
    final getChecksUrl = apiEndpoint(
      '/api/public/get-presubmit-checks',
      queryParameters: queryParameters,
    );

    final response = await _client.get(getChecksUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/public/get-presubmit-checks returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as List<Object?>;
      return CocoonResponse.data(
        jsonResponse
            .cast<Map<String, Object?>>()
            .map(PresubmitCheckResponse.fromJson)
            .toList(),
      );
    } catch (error) {
      return CocoonResponse.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<List<PresubmitGuardSummary>>>
  fetchPresubmitGuardSummaries({
    required String repo,
    required String pr,
  }) async {
    final queryParameters = <String, String?>{'repo': repo, 'pr': pr};
    final getSummariesUrl = apiEndpoint(
      '/api/public/get-presubmit-guard-summaries',
      queryParameters: queryParameters,
    );

    final response = await _client.get(getSummariesUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/public/get-presubmit-guard-summaries returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as List<Object?>;
      return CocoonResponse.data(
        jsonResponse
            .cast<Map<String, Object?>>()
            .map(PresubmitGuardSummary.fromJson)
            .toList(),
      );
    } catch (error) {
      return CocoonResponse.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<void>> updateTreeStatus({
    required String idToken,
    required String repo,
    required TreeStatus status,
    String? reason,
  }) async {
    final updateTreeStatusUrl = apiEndpoint('/api/update-tree-status');
    final response = await _client.post(
      updateTreeStatusUrl,
      headers: {'X-Flutter-IdToken': idToken},
      body: jsonEncode({
        'repo': repo,
        'passing': status == TreeStatus.success,
        'reason': ?reason,
      }),
    );
    if (response.statusCode == HttpStatus.ok) {
      return const CocoonResponse.data(null);
    }
    return CocoonResponse.error(
      'HTTP Code: ${response.statusCode}, ${response.body}',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<CocoonResponse<bool>> vacuumGitHubCommits(
    String idToken, {
    required String repo,
    required String branch,
  }) async {
    final refreshGitHubCommitsUrl = apiEndpoint(
      '/api/vacuum-github-commits',
      queryParameters: {'repo': repo, 'branch': branch},
    );
    final response = await _client.get(
      refreshGitHubCommitsUrl,
      headers: <String, String>{'X-Flutter-IdToken': idToken},
    );
    if (response.statusCode == HttpStatus.ok) {
      return const CocoonResponse.data(true);
    }
    return CocoonResponse.error(
      'Failed to vacuum github commits: ${response.reasonPhrase}',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<CocoonResponse<bool>> rerunTask({
    required String? idToken,
    required String taskName,
    required String commitSha,
    required String repo,
    required String branch,
    Iterable<TaskStatus>? include,
  }) async {
    if (idToken == null || idToken.isEmpty) {
      return const CocoonResponse<bool>.error(
        'Sign in to trigger reruns',
        statusCode: 401 /* HTTP Unathorized */,
      );
    }

    /// This endpoint only returns a status code.
    final postResetTaskUrl = apiEndpoint('/api/rerun-prod-task');
    final response = await _client.post(
      postResetTaskUrl,
      headers: {'X-Flutter-IdToken': idToken},
      body: jsonEncode({
        'branch': branch,
        'repo': repo,
        'commit': commitSha,
        'task': taskName,
        if (include != null) 'include': include.join(','),
      }),
    );

    if (response.statusCode == HttpStatus.ok) {
      return const CocoonResponse<bool>.data(true);
    }

    return CocoonResponse<bool>.error(
      'HTTP Code: ${response.statusCode}, ${response.body}',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<CocoonResponse<void>> rerunCommit({
    required String? idToken,
    required String commitSha,
    required String repo,
    required String branch,
    Iterable<TaskStatus>? include,
  }) async {
    return rerunTask(
      idToken: idToken,
      taskName: 'all',
      include: include,
      commitSha: commitSha,
      repo: repo,
      branch: branch,
    );
  }

  @override
  Future<CocoonResponse<List<MergeGroupHook>>> fetchMergeQueueHooks({
    required String idToken,
  }) async {
    final getMergeQueueHooksUrl = apiEndpoint('/api/merge_queue_hooks');

    final response = await _client.get(
      getMergeQueueHooksUrl,
      headers: {'X-Flutter-IdToken': idToken},
    );

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse.error(
        '/api/merge_queue_hooks returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, Object?>;
      final hooks = MergeGroupHooks.fromJson(jsonResponse);
      return CocoonResponse.data(hooks.hooks);
    } catch (error) {
      return CocoonResponse.error(
        error.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<CocoonResponse<void>> replayGitHubWebhook({
    required String idToken,
    required String id,
  }) async {
    if (idToken.isEmpty) {
      return const CocoonResponse.error(
        'Sign in to replay events',
        statusCode: 401,
      );
    }

    final replayUrl = apiEndpoint(
      '/api/github-webhook-replay',
      queryParameters: {'id': id},
    );

    final response = await _client.post(
      replayUrl,
      headers: {'X-Flutter-IdToken': idToken},
    );

    if (response.statusCode == HttpStatus.ok) {
      return const CocoonResponse.data(null);
    }

    return CocoonResponse.error(
      'HTTP Code: ${response.statusCode}, ${response.body}',
      statusCode: response.statusCode,
    );
  }

  /// Construct the API endpoint based on the priority of using a local endpoint
  /// before falling back to the production endpoint.
  ///
  /// This functions resolves the relative url endpoint to the production endpoint
  /// that can be used on web to the production endpoint if running not on web.
  /// This is because only on web a Cocoon backend can be running from the same
  /// host as this Flutter application, but on mobile we need to ping a separate
  /// production endpoint.
  ///
  /// The urlSuffix begins with a slash, e.g. "/api/public/get-status".
  ///
  /// [queryParameters] are appended to the url and are url encoded.
  @visibleForTesting
  Uri apiEndpoint(String urlSuffix, {Map<String, String?>? queryParameters}) {
    if (kIsWeb) {
      return Uri.base.replace(
        path: urlSuffix,
        queryParameters: queryParameters,
      );
    }
    return Uri.https(_baseApiUrl, urlSuffix, queryParameters);
  }

  List<CommitStatus> _commitStatusesFromJson(List<Object?> commits) {
    return [...commits.cast<Map<String, Object?>>().map(CommitStatus.fromJson)];
  }
}
