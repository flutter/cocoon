// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:cocoon/http.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'package:cocoon/build/status_card.dart';
import 'package:cocoon/build/common.dart';
import 'package:cocoon/build/task_legend.dart';
import 'package:cocoon/build/task_guide.dart';
import 'package:cocoon/models.dart';

const Duration _kBadHealthGracePeriod = const Duration(hours: 1);
const Color _kHealthyAgentColor = const Color(0x8F, 0xDF, 0x5F);
const Color _kUnhealthyAgentColor = const Color(0xE9, 0x80, 0x80);
const Duration maxHealthCheckAge = const Duration(minutes: 10);

/// A matrix of build results for each commit to the master branch of
/// flutter/flutter.
@Component(
  selector: 'status-table',
  templateUrl: 'status_table.html',
  styleUrls: const ['status_table.css'],
  directives: [
    NgIf,
    NgFor,
    NgClass,
    NgStyle,
    StatusCard,
    TaskGuideComponent,
    TaskLegend,
  ],
  pipes: [
    MaxLengthPipe,
    SourceUrlPipe,
  ],
)
class StatusTableComponent implements OnInit, OnDestroy {
  StatusTableComponent(this._httpClient);

  final http.Client _httpClient;
  bool isLoading = true;
  bool isBuildBroken;

  /// The first row in the table that shows stage names and task names.
  HeaderRow headerRow;

  /// The first column in the table that shows commit information.
  List<BuildStatus> headerCol;

  /// A sparse Commit X Task matrix of test results.
  Map<String, Map<String, TaskEntity>> resultMatrix =
      <String, Map<String, TaskEntity>>{};

  /// The card to display the status of an agent.
  @ViewChild(StatusCard)
  StatusCard agentStatusCard;

  List<AgentStatus> agentStatuses;

  Timer _reloadData;
  Timer _reloadStatus;

  @override
  void ngOnInit() {
    _handleReloadData();
    _handleReloadStatus();
    _reloadData =
        new Timer.periodic(const Duration(seconds: 30), _handleReloadData);
    _reloadStatus =
        new Timer.periodic(const Duration(seconds: 10), _handleReloadStatus);
    getAuthenticationStatus('/').then((AuthenticationStatus status) {
      _userIsAuthenticated = status.isAuthenticated;
    });
  }

  @override
  void ngOnDestroy() {
    _reloadData?.cancel();
    _reloadStatus?.cancel();
  }

  Future<void> _handleReloadStatus([Object _]) async {
    final response = await _httpClient.get('api/public/build-status');
    if (response.statusCode != 200) {
      isBuildBroken = null;
      return;
    }
    Map<String, Object> responseObject = json.decode(response.body);
    final String status = responseObject['AnticipatedBuildStatus'];
    if (status == 'Succeeded') {
      isBuildBroken = false;
    } else if (status == 'Failed') {
      isBuildBroken = true;
    } else {
      isBuildBroken = null;
    }
  }

  Future<void> _handleReloadData([Object _]) async {
    isLoading = true;
    final response = await _httpClient.get('/api/public/get-status');
    if (response.statusCode != 200) {
      return;
    }
    Map<String, Object> statusJson = json.decode(response.body);
    GetStatusResult statusResult = new GetStatusResult.fromJson(statusJson);
    isLoading = false;
    agentStatuses = statusResult.agentStatuses ?? <AgentStatus>[];
    List<BuildStatus> statuses = statusResult.statuses ?? <BuildStatus>[];
    headerCol = <BuildStatus>[];
    headerRow = new HeaderRow();
    resultMatrix = <String, Map<String, TaskEntity>>{};
    for (BuildStatus status in statuses) {
      String sha = status.checklist.checklist.commit.sha;
      resultMatrix[sha] ??= <String, TaskEntity>{};
      headerCol.add(status);
      for (Stage stage in status.stages) {
        headerRow.addStage(stage);
        for (TaskEntity taskEntity in stage.tasks) {
          resultMatrix[sha][taskEntity.task.name] = taskEntity;
        }
      }
    }
  }

  String _pendingSha;
  String _pendingTaskName;
  String _pendingStageName;
  Timer _pendingEvent;

  void handleMousedown(String sha, String taskName, String stageName) {
    _pendingEvent?.cancel();
    _pendingSha = sha;
    _pendingTaskName = taskName;
    _pendingStageName = stageName;
    _pendingEvent = new Timer(const Duration(seconds: 1, milliseconds: 500), () {
      tryToResetTask(sha, taskName);
      _pendingEvent = null;
    });
  }

  void handleMouseupOrLeave() {
    if (_pendingEvent == null)
      return;
    _pendingEvent.cancel();
    if (_pendingSha != null)
      openLog(_pendingSha, _pendingTaskName, _pendingStageName);
    _pendingSha = null;
    _pendingTaskName = null;
    _pendingStageName = null;
  }

  Future<void> tryToResetTask(String sha, String taskName) async {
    if (!userIsAuthenticated || !canBeReset(sha, taskName))
      return;
    final TaskEntity entity = _findTask(sha, taskName);
    if (entity == null || !entity.task.stageName.contains('devicelab')) return;
    final String request = json.encode(<String, String>{
      'Key': entity.key,
    });
    final oldStatus = entity.task.status;
    entity.task.status = 'New';
    final response = await HttpRequest.request('/api/reset-devicelab-task',
        method: 'POST', sendData: request, mimeType: 'application/json');
    if (response.status != 200) {
      window.alert('Task reset failed');
      entity.task.status = oldStatus;
      return;
    }
    bool result = json.decode(response.response);
    if (!result) {
      entity.task.status = oldStatus;
      window.alert('Task reset failed');
    }
  }

  bool get userIsAuthenticated => _userIsAuthenticated;
  bool _userIsAuthenticated = false;

  bool canBeReset(String sha, String taskName) {
    final TaskEntity entity = _findTask(sha, taskName);
    if (entity == null ||
        _isExternal(entity.task.name) ||
        !entity.task.stageName.contains('devicelab')) return false;
    return entity.task.status != 'In Progress';
  }

  String getHostFor(String sha, String taskName) {
    final TaskEntity entity = _findTask(sha, taskName);
    final String host = entity?.task?.host;
    if (host == null || host.trim().isEmpty) return 'Unknown';
    return host;
  }

  List<String> taskStatusToCssStyle(
      {@required String taskStatus,
      @required int attempts,
      @required bool knownToBeFlaky}) {
    const statusMap = const <String, String>{
      'New': 'task-new',
      'In Progress': 'task-in-progress',
      'Succeeded': 'task-succeeded',
      'Failed': 'task-failed',
      'Underperformed': 'task-underperformed',
      'Skipped': 'task-skipped',
    };

    String cssClass;
    if (taskStatus == 'Succeeded' && attempts > 1) {
      cssClass = 'task-succeeded-but-flaky';
    } else if (taskStatus == 'New' && attempts > 1) {
      cssClass = 'task-underperformed';
    } else {
      cssClass = statusMap[taskStatus] ?? 'task-unknown';
    }

    final List<String> classNames = ['task-status-circle', cssClass];

    if (knownToBeFlaky) classNames.add('task-known-to-be-flaky');

    return classNames;
  }

  TaskEntity _findTask(String sha, String taskName) {
    Map<String, TaskEntity> row = resultMatrix[sha];

    if (row == null || !row.containsKey(taskName)) return null;

    return row[taskName];
  }

  List<String> getStatusStyle(String sha, String taskName) {
    TaskEntity taskEntity = _findTask(sha, taskName);

    if (taskEntity == null) {
      return taskStatusToCssStyle(
        taskStatus: 'Skipped',
        attempts: 0,
        knownToBeFlaky: false,
      );
    }

    return taskStatusToCssStyle(
      taskStatus: taskEntity.task.status,
      attempts: taskEntity.task.attempts,
      knownToBeFlaky: taskEntity.task.isFlaky,
    );
  }

  /// Maps from agent IDs to the latest time agent reported success.
  Map<String, DateTime> _latestAgentPassTimes = <String, DateTime>{};

  Map<String, String> getAgentStyle(AgentStatus status) {
    DateTime now = new DateTime.now();

    if (isAgentHealthy(status)) {
      _latestAgentPassTimes[status.agentId] = now;
    }

    Duration unhealthyDuration;
    if (!_latestAgentPassTimes.containsKey(status.agentId)) {
      // First time an agent reports status. Assume the worst.
      unhealthyDuration = _kBadHealthGracePeriod;
    } else {
      unhealthyDuration = now.difference(_latestAgentPassTimes[status.agentId]);
      // Clamp difference to _kBadHealthGracePeriod so that lerp coefficient is between 0.0 and 1.0.
      unhealthyDuration = unhealthyDuration > _kBadHealthGracePeriod
          ? _kBadHealthGracePeriod
          : unhealthyDuration;
    }

    Color statusColor = Color.lerp(
      _kHealthyAgentColor,
      _kUnhealthyAgentColor,
      unhealthyDuration.inMilliseconds / _kBadHealthGracePeriod.inMilliseconds,
    );

    return {
      'background-color': statusColor.cssHex,
    };
  }

  /// An agent is considered healthy if the latest health report was OK and is
  /// up-to-date.
  bool isAgentHealthy(AgentStatus status) {
    return status.isHealthy &&
        status.healthCheckTimestamp != null &&
        new DateTime.now().difference(status.healthCheckTimestamp) <
            maxHealthCheckAge;
  }

  /// Show an agent status card for [agentStatus].
  void showAgentHealthDetails(AgentStatus agentStatus) {
    agentStatusCard.show(agentStatus);
  }

  /// Hide the the current agent status card.
  void hideAgentHealthDetails() {
    agentStatusCard.hide();
  }

  /// Opens a new window linking to the provided task's log information.
  void openLog(String sha, String taskName, String taskStage) {
    TaskEntity taskEntity = _findTask(sha, taskName);

    if (_isExternal(taskStage)) {
      // We cannot serve the log file from an external system directly, but we
      // can redirect the user closer to where they can find it.
      window.open(
          SourceUrlPipe._computeLinkToExternalBuildHistory(taskName, taskStage),
          '_blank');
    } else if (taskEntity != null) {
      window.open('/api/get-log?ownerKey=${taskEntity.key}', '_blank');
    }
  }
}

/// A formatter which displays a string with a maximum length
@Pipe('max_length')
class MaxLengthPipe extends PipeTransform {
  String transform(String source, int max) {
    return source.length > max ? source.substring(0, max) : source;
  }
}

bool _isExternal(String taskStage) {
  return taskStage == 'travis' ||
      taskStage == 'appveyor' ||
      taskStage == 'chromebot' ||
      taskStage == 'cirrus';
}

/// A formatter to compute the source url of a task
@Pipe('source_url')
class SourceUrlPipe extends PipeTransform {
  String transform(String taskName, String taskStage) {
    if (_isExternal(taskStage)) {
      return _computeLinkToExternalBuildHistory(taskName, taskStage);
    }
    return 'https://github.com/flutter/flutter/blob/master/dev/devicelab/bin/tasks/$taskName.dart';
  }

  static String _computeLinkToExternalBuildHistory(
      String taskName, String taskStage) {
    if (taskStage == 'travis') {
      return 'https://travis-ci.org/flutter/flutter/builds';
    } else if (taskStage == 'appveyor') {
      return 'https://ci.appveyor.com/project/flutter/flutter/history';
    } else if (taskStage == 'chromebot') {
      switch (taskName) {
        case 'mac_bot':
          return 'https://build.chromium.org/p/client.flutter/builders/Mac';
          break;
        case 'linux_bot':
          return 'https://build.chromium.org/p/client.flutter/builders/Linux';
          break;
        case 'windows_bot':
          return 'https://build.chromium.org/p/client.flutter/builders/Windows';
          break;
        default:
          return 'https://travis-ci.org/flutter/flutter/builds';
      }
    } else if (taskStage == 'cirrus') {
      return 'https://cirrus-ci.com/github/flutter/flutter/master';
    } else {
      return '#';
    }
  }
}
