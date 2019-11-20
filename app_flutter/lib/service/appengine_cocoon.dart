// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:fixnum/fixnum.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Key, RootKey, Stage, Task;

import 'cocoon.dart';
import 'downloader.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// Creates a new [AppEngineCocoonService].
  ///
  /// If a [client] is not specified, a new [http.Client] instance is created.
  AppEngineCocoonService({http.Client client, Downloader downloader})
      : _client = client ?? http.Client(),
        _downloader = downloader ?? Downloader();

  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const String _baseApiUrl = 'https://flutter-dashboard.appspot.com';

  final http.Client _client;

  final Downloader _downloader;

  @override
  Future<CocoonResponse<List<CommitStatus>>> fetchCommitStatuses() async {
    final String getStatusUrl = _apiEndpoint('/api/public/get-status');

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
    final String getBuildStatusUrl = _apiEndpoint('/api/public/build-status');

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
  Future<bool> rerunTask(Task task, String idToken) async {
    assert(idToken != null);
    final String postResetTaskUrl = _apiEndpoint('/api/reset-devicelab-task');

    /// This endpoint only returns a status code.
    final http.Response response = await _client.post(postResetTaskUrl,
        headers: <String, String>{
          'X-Flutter-IdToken': idToken,
        },
        body: jsonEncode(<String, String>{
          'Key': task.key.child.name,
        }));

    return response.statusCode == HttpStatus.ok;
  }

  /// Downloads the log for [task] to the local storage of the current device.
  /// Returns true if write was successful, and false if there was a failure.
  ///
  /// Only works on the web platform.
  @override
  Future<bool> downloadLog(Task task, String idToken, String commitSha) async {
    assert(task != null);
    assert(idToken != null);

    final String getTaskLogUrl =
        _apiEndpoint('/api/get-log?ownerKey=${task.key.child.name}');

    // Only show the first 7 characters of the commit sha. This amount is unique
    // enough to allow lookup of a commit.
    final String shortSha = commitSha.substring(0, 7);

    final String fileName = '${task.name}_${shortSha}_${task.attempts}.log';

    return _downloader.download(getTaskLogUrl, fileName, idToken: idToken);
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
  String _apiEndpoint(String urlSuffix) {
    return kIsWeb ? urlSuffix : '$_baseApiUrl$urlSuffix';
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
      tasks.add(_taskFromJson(jsonTask));
    }

    return tasks;
  }

  Task _taskFromJson(Map<String, Object> json) {
    assert(json != null);

    final Map<String, Object> taskData = json['Task'];
    final List<Object> objectRequiredCapabilities =
        taskData['RequiredCapabilities'];

    return Task()
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
  }
}
