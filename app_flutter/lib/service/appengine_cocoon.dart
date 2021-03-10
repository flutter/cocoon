// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:app_flutter/logic/qualified_task.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import 'package:http/http.dart' as http;
import 'package:fixnum/fixnum.dart';

import 'package:cocoon_service/models.dart';

import '../logic/qualified_task.dart';
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

  /// Branch on flutter/flutter to default requests for.
  final String _defaultBranch = 'master';

  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const String _baseApiUrl = 'flutter-dashboard.appspot.com';

  final http.Client _client;

  final Downloader _downloader;

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
  Future<CocoonResponse<List<Agent>>> fetchAgentStatuses() async {
    final String getStatusUrl = apiEndpoint('/api/public/get-status');

    /// This endpoint returns JSON [List<Agent>, List<CommitStatus>]
    final http.Response response = await _client.get(getStatusUrl);

    if (response.statusCode != HttpStatus.ok) {
      return CocoonResponse<List<Agent>>.error('/api/public/get-status returned ${response.statusCode}');
    }

    try {
      final Map<String, Object> jsonResponse = jsonDecode(response.body);
      return CocoonResponse<List<Agent>>.data(_agentStatusesFromJson(jsonResponse['AgentStatuses']));
    } catch (error) {
      return CocoonResponse<List<Agent>>.error(error.toString());
    }
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
  Future<bool> rerunTask(Task task, String idToken) async {
    assert(idToken != null);

    final QualifiedTask qualifiedTask = QualifiedTask.fromTask(task);
    String postResetTaskUrl;
    if (qualifiedTask.isDevicelab) {
      postResetTaskUrl = apiEndpoint('/api/reset-devicelab-task');
    } else if (qualifiedTask.isLuci) {
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

    final Map<String, String> queryParameters = <String, String>{'ownerKey': task.key.child.name};
    final String getTaskLogUrl = apiEndpoint('/api/get-log', queryParameters: queryParameters);

    // Only show the first 7 characters of the commit sha. This amount is unique
    // enough to allow lookup of a commit.
    final String shortSha = commitSha.substring(0, 7);

    final String fileName = '${task.name}_${shortSha}_${task.attempts}.log';

    return _downloader.download(getTaskLogUrl, fileName, idToken: idToken);
  }

  @override
  Future<CocoonResponse<String>> createAgent(String agentId, List<String> capabilities, String idToken) async {
    assert(agentId != null);
    assert(capabilities.isNotEmpty);
    assert(idToken != null);

    final String createAgentUrl = apiEndpoint('/api/create-agent');

    /// This endpoint returns JSON {'Token': [Token]}
    final http.Response response = await _client.post(
      createAgentUrl,
      headers: <String, String>{'X-Flutter-IdToken': idToken},
      body: jsonEncode(<String, Object>{
        'AgentID': agentId,
        'Capabilities': capabilities,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      return const CocoonResponse<String>.error('/api/create-agent did not respond with 200');
    }

    Map<String, Object> responseBody;
    try {
      responseBody = jsonDecode(response.body);
      if (responseBody['Token'] == null) {
        return const CocoonResponse<String>.error('/api/create-agent returned unexpected response');
      }
    } catch (e) {
      return const CocoonResponse<String>.error('/api/create-agent returned unexpected response');
    }

    return CocoonResponse<String>.data(responseBody['Token']);
  }

  @override
  Future<void> reserveTask(Agent agent, String idToken) async {
    assert(agent != null);
    assert(idToken != null);

    final String reserveTaskUrl = apiEndpoint('/api/reserve-task');

    final http.Response response = await _client.post(
      reserveTaskUrl,
      headers: <String, String>{'X-Flutter-IdToken': idToken},
      body: jsonEncode(<String, Object>{
        'AgentID': agent.agentId,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception('/api/reserve-task did not respond with 200');
    }

    Map<String, Object> responseBody;
    try {
      responseBody = jsonDecode(response.body);
      if (responseBody['Task'] == null) {
        throw Exception('/api/reserve-task returned unexpected response');
      }
    } catch (e) {
      throw Exception('/api/reserve-task returned unexpected response');
    }
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

  List<Agent> _agentStatusesFromJson(List<Object> jsonAgentStatuses) {
    final List<Agent> agents = <Agent>[];

    for (final Map<String, Object> jsonAgent in jsonAgentStatuses) {
      final List<Object> objectCapabilities = jsonAgent['Capabilities'];
      final List<String> capabilities = objectCapabilities.map((Object value) => value.toString()).toList();
      final Agent agent = Agent()
        ..agentId = jsonAgent['AgentID']
        ..healthCheckTimestamp = Int64.parseInt(jsonAgent['HealthCheckTimestamp'].toString())
        ..isHealthy = jsonAgent['IsHealthy']
        ..capabilities.addAll(capabilities)
        ..healthDetails = jsonAgent['HealthDetails'];
      agents.add(agent);
    }

    return agents;
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

    if (taskData['StageName'] == StageName.luci) {
      task
        ..buildNumberList = taskData['BuildNumberList'] ?? ''
        ..builderName = taskData['BuilderName'] ?? ''
        ..luciBucket = taskData['LuciBucket'] ?? '';
    }
    return task;
  }
}
