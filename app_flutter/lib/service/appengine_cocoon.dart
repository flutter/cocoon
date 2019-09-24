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
  static const baseApiUrl = 'https://flutter-dashboard.appspot.com/api';

  http.Client client = http.Client();

  @override
  Future<List<CommitStatus>> getStats() async {
    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    http.Response response = await client.get('$baseApiUrl/public/get-status');

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
          '$baseApiUrl/public/get-status returned ${response.statusCode}');
    }

    Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    assert(jsonResponse != null);

    return _commitStatusesFromJson(jsonResponse['Statuses']);
  }

  List<CommitStatus> _commitStatusesFromJson(List<dynamic> jsonCommitStatuses) {
    assert(jsonCommitStatuses != null);
    // TODO(chillers): Remove adapter code to just use proto fromJson method. https://github.com/flutter/cocoon/issues/441

    List<CommitStatus> statuses = List();

    jsonCommitStatuses.forEach((jsonCommitStatus) {
      statuses.add(CommitStatus()
        ..commit = _commitFromJson(jsonCommitStatus['Checklist']['Checklist'])
        ..stages.addAll(_stagesFromJson(jsonCommitStatus['Stages'])));
    });

    return statuses;
  }

  Commit _commitFromJson(Map<String, dynamic> jsonCommit) {
    assert(jsonCommit != null);

    return Commit()
      ..timestamp = Int64() + jsonCommit['CreateTimestamp']
      ..sha = jsonCommit['Commit']['Sha']
      ..author = jsonCommit['Commit']['Author']['Login']
      ..authorAvatarUrl = jsonCommit['Commit']['Author']['avatar_url']
      ..repository = jsonCommit['FlutterRepositoryPath'];
  }

  List<Stage> _stagesFromJson(List<dynamic> json) {
    assert(json != null);
    List<Stage> stages = List();

    json.forEach((jsonStage) => stages.add(_stageFromJson(jsonStage)));

    return stages;
  }

  Stage _stageFromJson(Map<String, dynamic> json) {
    assert(json != null);

    return Stage()
      ..name = json['Name']
      ..tasks.addAll(_tasksFromJson(json['Tasks']))
      ..taskStatus = json['Status'];
  }

  List<Task> _tasksFromJson(List<dynamic> json) {
    assert(json != null);
    List<Task> tasks = List();

    json.forEach((jsonTask) => tasks.add(_taskFromJson(jsonTask['Task'])));

    return tasks;
  }

  Task _taskFromJson(Map<String, dynamic> json) {
    assert(json != null);

    List<String> requiredCapabilities = List();
    List<dynamic> dynamicRequiredCapabilities = json['RequiredCapabilities'];
    dynamicRequiredCapabilities.forEach((dynamicCapability) =>
        requiredCapabilities.add(dynamicRequiredCapabilities.toString()));

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
