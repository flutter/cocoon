// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;

import '../src/rpc_model.dart';
import 'cocoon.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client? client})
    : _client = client ?? http.Client();

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
      );
    }

    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return CocoonResponse<List<CommitStatus>>.data(
        _commitStatusesFromJson(jsonResponse['Commits'] as List<Object?>),
      );
    } catch (error) {
      return CocoonResponse<List<CommitStatus>>.error(error.toString());
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
      );
    }

    List<String> repos;
    try {
      repos = List<String>.from(jsonDecode(response.body) as List<dynamic>);
    } on FormatException {
      return CocoonResponse<List<String>>.error(
        '$getReposUrl had a malformed response',
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
      );
    }

    BuildStatusResponse protoResponse;
    try {
      protoResponse = BuildStatusResponse.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    } on FormatException {
      return const CocoonResponse<BuildStatusResponse>.error(
        '/api/public/build-status had a malformed response',
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
      return CocoonResponse<List<Branch>>.error(error.toString());
    }
  }

  @override
  Future<bool> vacuumGitHubCommits(String idToken) async {
    final refreshGitHubCommitsUrl = apiEndpoint('/api/vacuum-github-commits');
    final response = await _client.get(
      refreshGitHubCommitsUrl,
      headers: <String, String>{'X-Flutter-IdToken': idToken},
    );
    return response.statusCode == HttpStatus.ok;
  }

  @override
  Future<CocoonResponse<bool>> rerunTask({
    required String? idToken,
    required String taskName,
    required String commitSha,
    required String repo,
    required String branch,
    Iterable<String>? include,
  }) async {
    if (idToken == null || idToken.isEmpty) {
      return const CocoonResponse<bool>.error('Sign in to trigger reruns');
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
    );
  }

  @override
  Future<CocoonResponse<void>> rerunCommit({
    required String? idToken,
    required String commitSha,
    required String repo,
    required String branch,
    Iterable<String>? include,
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
