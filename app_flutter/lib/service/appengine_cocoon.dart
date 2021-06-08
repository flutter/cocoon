// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;

import '../logic/qualified_task.dart';
import '../model/build_status_response.pb.dart';
import '../model/commit.pb.dart';
import '../model/commit_status.pb.dart';
import '../model/key.pb.dart';
import '../model/stage.pb.dart';
import '../model/task.pb.dart';
import 'cocoon.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client client}) : _client = client ?? http.Client();

  /// Branch on flutter/flutter to default requests for.
  final String _defaultBranch = 'master';

  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const String _baseApiUrl = 'flutter-dashboard.appspot.com';

  final http.Client _client;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses({
    CommitStatus lastCommitStatus,
    String branch,
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      if (lastCommitStatus != null) 'lastCommitKey': lastCommitStatus.commit.key.child.name,
      'branch': branch ?? _defaultBranch,
    };
    final String getStatusUrl = apiEndpoint('/api/public/get-status', queryParameters: queryParameters);

    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    final http.Response response = await _client.get(getStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<CommitStatus>>.error('/api/public/get-status returned ${response.statusCode}');
    }

    try {
      final Map<String, Object> jsonResponse = jsonDecode(response.body);
      return CocoonResponse<List<CommitStatus>>.data(_commitStatusesFromJson(jsonResponse['Statuses']));
    } catch (error) {
      return CocoonResponse<List<CommitStatus>>.error(error.toString());
    }
  }

  @override
  Future<CocoonResponse<BuildStatusResponse>> fetchTreeBuildStatus({
    String branch,
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      'branch': branch ?? _defaultBranch,
    };
    final String getBuildStatusUrl = apiEndpoint('/api/public/build-status', queryParameters: queryParameters);

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
  Future<CocoonResponse<List<String>>> fetchFlutterBranches() async {
    final String getBranchesUrl = apiEndpoint('/api/public/get-branches');

    /// This endpoint returns JSON {"Branches": List<String>}
    final http.Response response = await _client.get(getBranchesUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<String>>.error('/api/public/get-branches returned ${response.statusCode}');
    }

    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<String> branches = jsonResponse['Branches'].cast<String>();
      return CocoonResponse<List<String>>.data(branches);
    } catch (error) {
      return CocoonResponse<List<String>>.error(error.toString());
    }
  }

  @override
  Future<bool> vacuumGitHubCommits(String idToken) async {
    assert(idToken != null);
    final String refreshGitHubCommitsUrl = apiEndpoint('/api/vacuum-github-commits');
    final http.Response response = await _client.get(
      refreshGitHubCommitsUrl,
      headers: <String, String>{
        'X-Flutter-IdToken': idToken,
      },
    );
    return response.statusCode == HttpStatus.ok;
  }

  @override
  Future<bool> rerunTask(Task task, String idToken) async {
    assert(idToken != null);

    final QualifiedTask qualifiedTask = QualifiedTask.fromTask(task);
    String postResetTaskUrl;
    if (qualifiedTask.isLuci) {
      postResetTaskUrl = apiEndpoint('/api/reset-prod-task');
    } else {
      assert(false);
    }

    /// This endpoint only returns a status code.
    final http.Response response = await _client.post(postResetTaskUrl,
        headers: <String, String>{
          'X-Flutter-IdToken': idToken,
        },
        body: jsonEncode(<String, String>{
          'Key': task.key.child.name,
          // This prepares this api to support different repos.
          'Owner': 'flutter',
          'Repo': 'flutter',
        }));

    return response.statusCode == HttpStatus.ok;
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
  String apiEndpoint(
    String urlSuffix, {
    Map<String, String> queryParameters,
  }) {
    final Uri uri = Uri.https(_baseApiUrl, urlSuffix, queryParameters);
    final String url = uri.toString();

    return kIsWeb ? url.replaceAll('https://$_baseApiUrl', '') : url;
  }

  List<CommitStatus> _commitStatusesFromJson(List<Object> jsonCommitStatuses) {
    assert(jsonCommitStatuses != null);
    // TODO(chillers): Remove adapter code to just use proto fromJson method. https://github.com/flutter/cocoon/issues/441

    final List<CommitStatus> statuses = <CommitStatus>[];

    for (final Map<String, Object> jsonCommitStatus in jsonCommitStatuses) {
      final Map<String, Object> checklist = jsonCommitStatus['Checklist'];
      statuses.add(CommitStatus()
        ..commit = _commitFromJson(checklist)
        ..branch = _branchFromJson(checklist)
        ..stages.addAll(_stagesFromJson(jsonCommitStatus['Stages'])));
    }

    return statuses;
  }

  String _branchFromJson(Map<String, Object> jsonChecklist) {
    assert(jsonChecklist != null);

    final Map<String, Object> checklist = jsonChecklist['Checklist'];
    return checklist['Branch'];
  }

  Commit _commitFromJson(Map<String, Object> jsonChecklist) {
    assert(jsonChecklist != null);

    final Map<String, Object> checklist = jsonChecklist['Checklist'];

    final Map<String, Object> commit = checklist['Commit'];
    final Map<String, Object> author = commit['Author'];

    final Commit result = Commit()
      ..key = (RootKey()..child = (Key()..name = jsonChecklist['Key']))
      ..timestamp = Int64() + checklist['CreateTimestamp']
      ..sha = commit['Sha']
      ..author = author['Login']
      ..authorAvatarUrl = author['avatar_url']
      ..repository = checklist['FlutterRepositoryPath']
      ..branch = checklist['Branch'];
    if (commit['Message'] != null) {
      result.message = commit['Message'];
    }
    return result;
  }

  List<Stage> _stagesFromJson(List<Object> json) {
    assert(json != null);
    final List<Stage> stages = <Stage>[];

    for (final Object jsonStage in json) {
      stages.add(_stageFromJson(jsonStage));
    }

    return stages;
  }

  Stage _stageFromJson(Map<String, Object> json) {
    assert(json != null);
    return Stage()
      ..name = json['Name']
      ..tasks.addAll(_tasksFromJson(json['Tasks']))
      ..taskStatus = json['Status'];
  }

  List<Task> _tasksFromJson(List<Object> json) {
    assert(json != null);
    final List<Task> tasks = <Task>[];

    for (final Map<String, Object> jsonTask in json) {
      tasks.add(_taskFromJson(jsonTask));
    }

    return tasks;
  }

  Task _taskFromJson(Map<String, Object> json) {
    assert(json != null);

    final Map<String, Object> taskData = json['Task'];
    final List<Object> objectRequiredCapabilities = taskData['RequiredCapabilities'];

    final Task task = Task()
      ..key = (RootKey()..child = (Key()..name = json['Key']))
      ..createTimestamp = Int64(taskData['CreateTimestamp'])
      ..startTimestamp = Int64(taskData['StartTimestamp'])
      ..endTimestamp = Int64(taskData['EndTimestamp'])
      ..name = taskData['Name']
      ..attempts = taskData['Attempts']
      ..isFlaky = taskData['Flaky']
      ..timeoutInMinutes = taskData['TimeoutInMinutes']
      ..reason = taskData['Reason']
      ..requiredCapabilities.add(objectRequiredCapabilities.toString())
      ..reservedForAgentId = taskData['ReservedForAgentID']
      ..stageName = taskData['StageName']
      ..status = taskData['Status'];

    if (taskData['StageName'] != StageName.cirrus) {
      task
        ..buildNumberList = taskData['BuildNumberList'] ?? ''
        ..builderName = taskData['BuilderName'] ?? ''
        ..luciBucket = taskData['LuciBucket'] ?? '';
    }
    return task;
  }
}
