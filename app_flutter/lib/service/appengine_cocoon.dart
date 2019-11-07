// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fixnum/fixnum.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;

import 'cocoon.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client client})
      : _client = client ?? http.Client();

  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const String _baseApiUrl = 'https://flutter-dashboard.appspot.com';

  final http.Client _client;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses() async {
    final String getStatusUrl = kIsWeb
        ? '/api/public/get-status'
        : '$_baseApiUrl/api/public/get-status';

    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    final http.Response response = await _client.get(getStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      print(response.body);
      return CocoonResponse<List<CommitStatus>>()
        ..error = '/api/public/get-status returned ${response.statusCode}';
    }

    try {
      final Map<String, Object> jsonResponse = jsonDecode(response.body);
      return CocoonResponse<List<CommitStatus>>()
        ..data = _commitStatusesFromJson(jsonResponse['Statuses']);
    } catch (error) {
      return CocoonResponse<List<CommitStatus>>()..error = error.toString();
    }
  }

  @override
  Future<CocoonResponse<bool>> fetchTreeBuildStatus() async {
    final String getBuildStatusUrl = kIsWeb
        ? '/api/public/build-status'
        : '$_baseApiUrl/api/public/build-status';

    /// This endpoint returns JSON {AnticipatedBuildStatus: [BuildStatus]}
    final http.Response response = await _client.get(getBuildStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      print(response.body);
      return CocoonResponse<bool>()
        ..error = '/api/public/build-status returned ${response.statusCode}';
    }

    Map<String, Object> jsonResponse;
    try {
      jsonResponse = jsonDecode(response.body);
    } catch (error) {
      return CocoonResponse<bool>()
        ..error = '/api/public/build-status had a malformed response';
    }

    if (!_isBuildStatusResponseValid(jsonResponse)) {
      return CocoonResponse<bool>()
        ..error = '/api/public/build-status had a malformed response';
    }

    return CocoonResponse<bool>()
      ..data = jsonResponse['AnticipatedBuildStatus'] == 'Succeeded';
  }

  @override
  Future<bool> rerunTask(Task task, String accessToken) async {
    assert(accessToken != null);
    final String postResetTaskUrl = kIsWeb
        ? '/api/reset-devicelab-task'
        : '$_baseApiUrl/api/reset-devicelab-task';

    /// This endpoint only returns a status code.
    final http.Response response =
        await _client.post(postResetTaskUrl, headers: <String, String>{
      'X-Flutter-AccessToken': accessToken,
    }, body: <String, String>{
      'Key': task.key.toString(),
    });

    return response.statusCode == HttpStatus.ok;
  }

  /// Check if [Map<String,Object>] follows the format for build-status.
  ///
  /// Template of the response it should receive:
  /// ```json
  /// {
  ///   "AnticipatedBuildStatus": "Succeeded"|"Failed"
  /// }
  /// ```
  bool _isBuildStatusResponseValid(Map<String, Object> response) {
    if (!response.containsKey('AnticipatedBuildStatus')) {
      return false;
    }

    final String treeBuildStatus = response['AnticipatedBuildStatus'];
    if (treeBuildStatus != 'Failed' && treeBuildStatus != 'Succeeded') {
      return false;
    }

    return true;
  }

  List<CommitStatus> _commitStatusesFromJson(List<Object> jsonCommitStatuses) {
    assert(jsonCommitStatuses != null);
    // TODO(chillers): Remove adapter code to just use proto fromJson method. https://github.com/flutter/cocoon/issues/441

    final List<CommitStatus> statuses = <CommitStatus>[];

    for (Map<String, Object> jsonCommitStatus in jsonCommitStatuses) {
      final Map<String, Object> commit = jsonCommitStatus['Checklist'];
      statuses.add(CommitStatus()
        ..commit = _commitFromJson(commit['Checklist'])
        ..stages.addAll(_stagesFromJson(jsonCommitStatus['Stages'])));
    }

    return statuses;
  }

  Commit _commitFromJson(Map<String, Object> jsonCommit) {
    assert(jsonCommit != null);

    final Map<String, Object> commit = jsonCommit['Commit'];
    final Map<String, Object> author = commit['Author'];

    return Commit()
      ..timestamp = Int64() + jsonCommit['CreateTimestamp']
      ..sha = commit['Sha']
      ..author = author['Login']
      ..authorAvatarUrl = author['avatar_url']
      ..repository = jsonCommit['FlutterRepositoryPath'];
  }

  List<Stage> _stagesFromJson(List<Object> json) {
    assert(json != null);
    final List<Stage> stages = <Stage>[];

    for (Object jsonStage in json) {
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

    for (Map<String, Object> jsonTask in json) {
      tasks.add(_taskFromJson(jsonTask['Task']));
    }

    return tasks;
  }

  Task _taskFromJson(Map<String, Object> json) {
    assert(json != null);

    final List<Object> objectRequiredCapabilities =
        json['RequiredCapabilities'];

    return Task()
      ..createTimestamp = Int64(json['CreateTimestamp'])
      ..startTimestamp = Int64(json['StartTimestamp'])
      ..endTimestamp = Int64(json['EndTimestamp'])
      ..name = json['Name']
      ..attempts = json['Attempts']
      ..isFlaky = json['Flaky']
      ..timeoutInMinutes = json['TimeoutInMinutes']
      ..reason = json['Reason']
      ..requiredCapabilities.add(objectRequiredCapabilities.toString())
      ..reservedForAgentId = json['ReservedForAgentID']
      ..stageName = json['StageName']
      ..status = json['Status'];
  }
}
