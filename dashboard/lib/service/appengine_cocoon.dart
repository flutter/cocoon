// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb, visibleForTesting;
import 'package:flutter_dashboard/model/branch.pb.dart';
import 'package:http/http.dart' as http;

import '../logic/qualified_task.dart';
import '../model/build_status_response.pb.dart';
import '../model/commit.pb.dart';
import '../model/commit_status.pb.dart';
import '../model/key.pb.dart';
import '../model/task.pb.dart';
import 'cocoon.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client? client}) : _client = client ?? http.Client();

  /// Branch on flutter/flutter to default requests for.
  final String _defaultBranch = 'master';

  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const String _baseApiUrl = 'flutter-dashboard.appspot.com';

  final http.Client _client;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus? lastCommitStatus,
    String? branch,
    required String repo,
  }) async {
    final Map<String, String?> queryParameters = <String, String?>{
      if (lastCommitStatus != null) 'lastCommitKey': lastCommitStatus.commit.key.child.name,
      'branch': branch ?? _defaultBranch,
      'repo': repo,
    };
    final Uri getStatusUrl = apiEndpoint('/api/public/get-status', queryParameters: queryParameters);

    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    final http.Response response = await _client.get(getStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<CommitStatus>>.error('/api/public/get-status returned ${response.statusCode}');
    }

    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return CocoonResponse<List<CommitStatus>>.data(
        await compute<List<dynamic>, List<CommitStatus>>(_commitStatusesFromJson, jsonResponse['Statuses']),
      );
    } catch (error) {
      return CocoonResponse<List<CommitStatus>>.error(error.toString());
    }
  }

  @override
  Future<CocoonResponse<List<String>>> fetchRepos() async {
    final Uri getReposUrl = apiEndpoint('/api/public/repos');

    // This endpoint returns a JSON array of strings.1
    final http.Response response = await _client.get(getReposUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<String>>.error('$getReposUrl returned ${response.statusCode}');
    }

    List<String> repos;
    try {
      repos = List<String>.from(jsonDecode(response.body) as List<dynamic>);
    } on FormatException {
      return CocoonResponse<List<String>>.error('$getReposUrl had a malformed response');
    }
    return CocoonResponse<List<String>>.data(repos);
  }

  @override
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String? branch,
    required String repo,
  }) async {
    final Map<String, String?> queryParameters = <String, String?>{
      'branch': branch ?? _defaultBranch,
      'repo': repo,
    };
    final Uri getBuildStatusUrl = apiEndpoint('/api/public/build-status', queryParameters: queryParameters);

    /// This endpoint returns JSON {AnticipatedBuildStatus: [BuildStatus]}
    final http.Response response = await _client.get(getBuildStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<BuildStatusResponse>.error('/api/public/build-status returned ${response.statusCode}');
    }

    BuildStatusResponse protoResponse;
    try {
      protoResponse = BuildStatusResponse.fromJson(response.body);
    } on FormatException {
      return const CocoonResponse<BuildStatusResponse>.error('/api/public/build-status had a malformed response');
    }
    return CocoonResponse<BuildStatusResponse>.data(protoResponse);
  }

  @override
  Future<CocoonResponse<List<Branch>>> fetchFlutterBranches() async {
    final Uri getBranchesUrl = apiEndpoint('/api/public/get-release-branches');

    /// This endpoint returns JSON {"Branches": List<String>}
    final http.Response response = await _client.get(getBranchesUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<Branch>>.error('/api/public/get-release-branches returned ${response.statusCode}');
    }

    try {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      final List<Branch> branches = <Branch>[];
      for (final Map<String, dynamic> jsonBranch in jsonResponse) {
        branches.add(
          Branch()
            ..branch = jsonBranch['branch']!
            ..channel = jsonBranch['name']!,
        );
      }
      return CocoonResponse<List<Branch>>.data(branches);
    } catch (error) {
      return CocoonResponse<List<Branch>>.error(error.toString());
    }
  }

  @override
  Future<bool> vacuumGitHubCommits(String idToken) async {
    final Uri refreshGitHubCommitsUrl = apiEndpoint('/api/vacuum-github-commits');
    final http.Response response = await _client.get(
      refreshGitHubCommitsUrl,
      headers: <String, String>{
        'X-Flutter-IdToken': idToken,
      },
    );
    return response.statusCode == HttpStatus.ok;
  }

  @override
  Future<CocoonResponse<bool>> rerunTask(Task task, String? idToken, String repo) async {
    if (idToken == null || idToken.isEmpty) {
      return const CocoonResponse<bool>.error('Sign in to trigger reruns');
    }

    final QualifiedTask qualifiedTask = QualifiedTask.fromTask(task);
    assert(qualifiedTask.isLuci);

    /// This endpoint only returns a status code.
    final Uri postResetTaskUrl = apiEndpoint('/api/reset-prod-task');
    final http.Response response = await _client.post(
      postResetTaskUrl,
      headers: <String, String>{
        'X-Flutter-IdToken': idToken,
      },
      body: jsonEncode(<String, String>{
        'Key': task.key.child.name,
        'Repo': repo,
      }),
    );

    if (response.statusCode == HttpStatus.ok) {
      return const CocoonResponse<bool>.data(true);
    }

    return CocoonResponse<bool>.error('HTTP Code: ${response.statusCode}, ${response.body}');
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
  Uri apiEndpoint(
    String urlSuffix, {
    Map<String, String?>? queryParameters,
  }) {
    if (kIsWeb) {
      return Uri.base.replace(path: urlSuffix, queryParameters: queryParameters);
    }
    return Uri.https(_baseApiUrl, urlSuffix, queryParameters);
  }

  List<CommitStatus> _commitStatusesFromJson(List<dynamic>? jsonCommitStatuses) {
    assert(jsonCommitStatuses != null);
    // TODO(chillers): Remove adapter code to just use proto fromJson method. https://github.com/flutter/cocoon/issues/441

    final List<CommitStatus> statuses = <CommitStatus>[];

    for (final Map<String, dynamic> jsonCommitStatus in jsonCommitStatuses!) {
      final Map<String, dynamic> checklist = jsonCommitStatus['Checklist'];
      statuses.add(
        CommitStatus()
          ..commit = _commitFromJson(checklist)
          ..branch = _branchFromJson(checklist)!
          ..tasks.addAll(_tasksFromStagesJson(jsonCommitStatus['Stages'])),
      );
    }

    return statuses;
  }

  String? _branchFromJson(Map<String, dynamic> jsonChecklist) {
    final Map<String, dynamic> checklist = jsonChecklist['Checklist'];
    return checklist['Branch'] as String?;
  }

  Commit _commitFromJson(Map<String, dynamic> jsonChecklist) {
    final Map<String, dynamic> checklist = jsonChecklist['Checklist'];

    final Map<String, dynamic> commit = checklist['Commit'];
    final Map<String, dynamic> author = commit['Author'];

    final Commit result = Commit()
      ..key = (RootKey()..child = (Key()..name = jsonChecklist['Key'] as String))
      ..timestamp = Int64() + checklist['CreateTimestamp']!
      ..sha = commit['Sha'] as String
      ..author = author['Login'] as String
      ..authorAvatarUrl = author['avatar_url'] as String
      ..repository = checklist['FlutterRepositoryPath'] as String
      ..branch = checklist['Branch'] as String;
    if (commit['Message'] != null) {
      result.message = commit['Message'] as String;
    }
    return result;
  }

  List<Task> _tasksFromStagesJson(List<dynamic> json) {
    final List<Task> tasks = <Task>[];

    for (final Map<String, dynamic> jsonStage in json) {
      tasks.addAll(_tasksFromJson(jsonStage['Tasks']));
    }

    return tasks;
  }

  List<Task> _tasksFromJson(List<dynamic> json) {
    final List<Task> tasks = <Task>[];

    for (final Map<String, dynamic> jsonTask in json) {
      //as Iterable<Map<String, Object>>
      tasks.add(_taskFromJson(jsonTask));
    }

    return tasks;
  }

  Task _taskFromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> taskData = json['Task'];
    final List<dynamic>? objectRequiredCapabilities = taskData['RequiredCapabilities'] as List<dynamic>?;

    final Task task = Task()
      ..key = (RootKey()..child = (Key()..name = json['Key'] as String))
      ..createTimestamp = Int64(taskData['CreateTimestamp'] as int)
      ..startTimestamp = Int64(taskData['StartTimestamp'] as int)
      ..endTimestamp = Int64(taskData['EndTimestamp'] as int)
      ..name = taskData['Name'] as String
      ..attempts = taskData['Attempts'] as int
      ..isFlaky = taskData['Flaky'] as bool
      ..timeoutInMinutes = taskData['TimeoutInMinutes'] as int
      ..reason = taskData['Reason'] as String
      ..requiredCapabilities.add(objectRequiredCapabilities.toString())
      ..reservedForAgentId = taskData['ReservedForAgentID'] as String
      ..stageName = taskData['StageName'] as String
      ..status = taskData['Status'] as String
      ..isTestFlaky = taskData['TestFlaky'] as bool? ?? false;

    if (taskData['StageName'] != StageName.cirrus) {
      task
        ..buildNumberList = taskData['BuildNumberList'] as String? ?? ''
        ..builderName = taskData['BuilderName'] as String? ?? ''
        ..luciBucket = taskData['LuciBucket'] as String? ?? '';
    }
    return task;
  }
}
