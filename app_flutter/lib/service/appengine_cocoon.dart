// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fixnum/fixnum.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;

import 'cocoon.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const _baseApiUrl = 'https://flutter-dashboard.appspot.com/api';

  final http.Client _client;

  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client client})
      : _client = client ?? http.Client();

  @override
  Future<List<CommitStatus>> fetchCommitStatuses() async {
    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    http.Response response =
        await _client.get('$_baseApiUrl/public/get-status');

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
          '$_baseApiUrl/public/get-status returned ${response.statusCode}');
    }

    Map<String, Object> jsonResponse = jsonDecode(response.body);

    return _commitStatusesFromJson(jsonResponse['Statuses']);
  }

  @override
  Future<bool> fetchTreeBuildStatus() async {
    /// This endpoint returns JSON {AnticipatedBuildStatus: [BuildStatus]}
    http.Response response =
        await _client.get('$_baseApiUrl/public/build-status');

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
          '$_baseApiUrl/public/build-status returned ${response.statusCode}');
    }

    Map<String, Object> jsonResponse = jsonDecode(response.body);

    if (!_isBuildStatusResponseValid(jsonResponse)) {
      throw HttpException(
          '$_baseApiUrl/public/build-status had a malformed response');
    }

    return jsonResponse['AnticipatedBuildStatus'] == "Succeeded";
  }

  /// Check if [Map<String,Object>] follows the format for build-status.
  ///
  /// ```json
  /// {
  ///   "AnticipatedBuildStatus": "Succeeded"|"Failed"
  /// }
  /// ```
  bool _isBuildStatusResponseValid(Map<String, Object> response) {
    if (!response.containsKey('AnticipatedBuildStatus')) {
      return false;
    }

    String treeBuildStatus = response['AnticipatedBuildStatus'];
    if (treeBuildStatus != 'Failed' && treeBuildStatus != 'Succeeded') {
      return false;
    }

    return true;
  }

  List<CommitStatus> _commitStatusesFromJson(List<Object> jsonCommitStatuses) {
    assert(jsonCommitStatuses != null);
    // TODO(chillers): Remove adapter code to just use proto fromJson method. https://github.com/flutter/cocoon/issues/441

    List<CommitStatus> statuses = <CommitStatus>[];

    for (Map<String, Object> jsonCommitStatus in jsonCommitStatuses) {
      Map<String, Object> commit = jsonCommitStatus['Checklist'];
      statuses.add(CommitStatus()
        ..commit = _commitFromJson(commit['Checklist'])
        ..stages.addAll(_stagesFromJson(jsonCommitStatus['Stages'])));
    }

    return statuses;
  }

  Commit _commitFromJson(Map<String, Object> jsonCommit) {
    assert(jsonCommit != null);

    Map<String, Object> commit = jsonCommit['Commit'];
    Map<String, Object> author = commit['Author'];

    return Commit()
      ..timestamp = Int64() + jsonCommit['CreateTimestamp']
      ..sha = commit['Sha']
      ..author = author['Login']
      ..authorAvatarUrl = author['avatar_url']
      ..repository = jsonCommit['FlutterRepositoryPath'];
  }

  List<Stage> _stagesFromJson(List<Object> json) {
    assert(json != null);
    List<Stage> stages = <Stage>[];

    json.forEach((jsonStage) => stages.add(_stageFromJson(jsonStage)));

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
    List<Task> tasks = <Task>[];

    for (Map<String, Object> jsonTask in json) {
      tasks.add(_taskFromJson(jsonTask['Task']));
    }

    return tasks;
  }

  Task _taskFromJson(Map<String, Object> json) {
    assert(json != null);

    List<String> requiredCapabilities = <String>[];
    List<Object> objectRequiredCapabilities = json['RequiredCapabilities'];
    objectRequiredCapabilities.forEach((objectCapability) =>
        requiredCapabilities.add(objectRequiredCapabilities.toString()));

    return Task()
      ..createTimestamp = Int64(json['CreateTimestamp'])
      ..startTimestamp = Int64(json['StartTimestamp'])
      ..endTimestamp = Int64(json['EndTimestamp'])
      ..name = json['Name']
      ..attempts = json['Attempts']
      ..isFlaky = json['Flaky']
      ..timeoutInMinutes = json['TimeoutInMinutes']
      ..reason = json['Reason']
      ..requiredCapabilities.addAll(requiredCapabilities)
      ..reservedForAgentId = json['ReservedForAgentID']
      ..stageName = json['StageName']
      ..status = json['Status'];
  }
}
