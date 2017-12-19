// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:cocoon/model.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

@Component(
  selector: 'status-table',
  template: '''
<div *ngIf="isLoading" style="position: fixed; top: 0; left: 0; background-color: #AAFFAA;">
  Loading...
</div>

<legend></legend>

<div class="agent-bar">
  <div><b>Agents</b></div>
  <div *ngFor="let agentStatus of agentStatuses"
       class="agent-chip"
       [ngStyle]="getAgentStyle(agentStatus)"
       (click)="showAgentHealthDetails(agentStatus)">
    {{agentStatus.agentId}}
  </div>

  <div style="width: 40px; text-align: center">
  |
  </div>

  <div><b>Other</b></div>
  <a href="https://github.com/flutter/website" target="_new">
    <img src="www.png" style="height: 20px" title="Build status of flutter/website">
  </a>
  <a href="https://travis-ci.org/flutter/website" target="_new">
    <img src="https://travis-ci.org/flutter/website.svg?branch=master"  title="Build status of flutter/website">
  </a>
  <a href="https://github.com/flutter/plugins" target="_new">
    <img src="plugin.png" style="height: 20px" title="Build status of flutter/plugins">
  </a>
  <a href="https://travis-ci.org/flutter/plugins" target="_new">
    <img src="https://travis-ci.org/flutter/plugins.svg?branch=master" title="Build status of flutter/plugins">
  </a>
</div>

<div *ngIf="displayedAgentStatus != null"
     class="agent-health-details-card">
  <div style="position: absolute; top: 5px; right: 5px; cursor: pointer"
       (click)="hideAgentHealthDetails()">
    [X]
  </div>
  <div>
    {{displayedAgentStatus.agentId}}
    {{isAgentHealthy(displayedAgentStatus) ? "☺" : "☹"}}
  </div>
  <div>
    Last health check: {{displayedAgentStatus.healthCheckTimestamp}}
    {{agentHealthCheckAge(displayedAgentStatus.healthCheckTimestamp)}}
  </div>
  <div>Details:</div>
  <pre>{{displayedAgentStatus.healthDetails}}</pre>
</div>

<table class="status-table"
       cellspacing="0"
       cellpadding="0"
       *ngIf="headerRow != null && headerCol != null && headerCol.length > 0">
  <tr>
    <td class="table-header-cell first-column">
      &nbsp;
    </td>
    <td class="table-header-cell first-row"
        *ngFor="let metaTask of headerRow.allMetaTasks">
      <a [href]="computeLinkToTaskSourceFile(metaTask.name, metaTask.stageName)" target="_blank">
        <img width="18px" [src]="metaTask.iconUrl" title="{{metaTask.name}}">
      </a>
    </td>
  </tr>
  <tr *ngFor="let status of headerCol">
    <td class="table-header-cell first-column">
      <img width="20px" [src]="status.checklist.checklist.commit.author.avatarUrl">
      <a href="https://github.com/flutter/flutter/commit/{{status.checklist.checklist.commit.sha}}"
         target="_blank">
        {{shortSha(status.checklist.checklist.commit.sha)}}
        ({{shortSha(status.checklist.checklist.commit.author.login)}})
      </a>
    </td>
    <td class="task-status-cell" *ngFor="let metaTask of headerRow.allMetaTasks">
      <div [ngClass]="getStatusStyle(status.checklist.checklist.commit.sha, metaTask.name)"
           (click)="openLog(status.checklist.checklist.commit.sha, metaTask.name, metaTask.stageName)"
           title="{{metaTask.name}}">
      </div>
    </td>
  </tr>
</table>
<table class="status-table"
       style="position:fixed;bottom:0;left:0"
       cellspacing="0"
       cellpadding="0"
       *ngIf="headerRow != null && headerCol != null && headerCol.length > 0">
  <tr>
    <td class="table-footer-first-cell">
      &nbsp;
    </td>
    <td class="table-footer-cell"
        *ngFor="let metaTask of headerRow.allMetaTasks">
      <img width="18px" [src]="metaTask.iconUrl">
      <div class="task-name">{{metaTask.name}}</div>
    </td>
  </tr>
</table>
''',
  directives: const [Legend, NgIf, NgFor, NgClass, NgStyle],
)
class StatusTable implements OnInit {
  static const Duration maxHealthCheckAge = const Duration(minutes: 10);

  StatusTable(this._httpClient);

  final http.Client _httpClient;
  bool isLoading = true;

  /// The first row in the table that shows stage names and task names.
  HeaderRow headerRow;

  /// The first column in the table that shows commit information.
  List<BuildStatus> headerCol;

  /// A sparse Commit X Task matrix of test results.
  Map<String, Map<String, TaskEntity>> resultMatrix = <String, Map<String, TaskEntity>>{};

  List<AgentStatus> agentStatuses;

  @override
  Future<Null> ngOnInit() async {
    await reloadData();
    new Timer.periodic(const Duration(seconds: 30), (_) => reloadData());
  }

  Future<Null> reloadData() async {
    isLoading = true;
    Map<String, dynamic> statusJson = JSON.decode((await _httpClient.get('/api/public/get-status')).body);
    GetStatusResult statusResult = GetStatusResult.fromJson(statusJson);
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

  String shortSha(String fullSha) {
    return fullSha.length > 7 ? fullSha.substring(0, 7) : fullSha;
  }

  List<String> taskStatusToCssStyle({
    @required String taskStatus,
    @required int attempts,
    @required bool knownToBeFlaky
  }) {
    const statusMap = const <String, String> {
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

    if (knownToBeFlaky)
      classNames.add('task-known-to-be-flaky');

    return classNames;
  }

  TaskEntity _findTask(String sha, String taskName) {
    Map<String, TaskEntity> row = resultMatrix[sha];

    if (row == null || !row.containsKey(taskName))
      return null;

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

  static const Duration _kBadHealthGracePeriod = const Duration(hours: 1);
  static const Color _kHealthyAgentColor = const Color(0x8F, 0xDF, 0x5F);
  static const Color _kUnhealthyAgentColor = const Color(0xE9, 0x80, 0x80);

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
      unhealthyDuration = unhealthyDuration > _kBadHealthGracePeriod ? _kBadHealthGracePeriod : unhealthyDuration;
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
    return status.isHealthy && status.healthCheckTimestamp != null &&
      new DateTime.now().difference(status.healthCheckTimestamp) < maxHealthCheckAge;
  }

  AgentStatus displayedAgentStatus;

  void showAgentHealthDetails(AgentStatus agentStatus) {
    displayedAgentStatus = agentStatus;
  }

  void hideAgentHealthDetails() {
    displayedAgentStatus = null;
  }

  String agentHealthCheckAge(DateTime dt) {
    if (dt == null)
      return '';
    Duration age = new DateTime.now().difference(dt);
    String ageQualifier = age > maxHealthCheckAge
      ? 'out-of-date!!!'
      : 'old';
    return '(${age.inMinutes} minutes $ageQualifier)';
  }

  void openLog(String sha, String taskName, String taskStage) {
    TaskEntity taskEntity = _findTask(sha, taskName);

    if (isExternal(taskStage)) {
      // We cannot serve the log file from an external system directly, but we
      // can redirect the user closer to where they can find it.
      window.open(computeLinkToExternalBuildHistory(taskName, taskStage), '_blank');
    } else if (taskEntity != null) {
      window.open('/api/get-log?ownerKey=${taskEntity.key.value}', '_blank');
    }
  }

  String computeLinkToTaskSourceFile(String taskName, String taskStage) {
    if (isExternal(taskStage)) {
      return computeLinkToExternalBuildHistory(taskName, taskStage);
    }
    return 'https://github.com/flutter/flutter/blob/master/dev/devicelab/bin/tasks/$taskName.dart';
  }

  bool isExternal(String taskStage) {
    return taskStage == 'travis' || taskStage == 'appveyor' || taskStage == 'chromebot';
  }

  String computeLinkToExternalBuildHistory(taskName, taskStage) {
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
    } else {
      return '#';
    }
  }
}

class HeaderRow {
  List<StageHeader> stageHeaders = <StageHeader>[];

  void addStage(Stage stage) {
    StageHeader header = stageHeaders.firstWhere(
      (StageHeader h) => h.stageName == stage.name,
      orElse: () {
        StageHeader newHeader = new StageHeader(stage.name);
        stageHeaders.add(newHeader);
        return newHeader;
      }
    );
    for (TaskEntity taskEntity in stage.tasks) {
      header.addMetaTask(taskEntity);
    }
    stageHeaders.sort((StageHeader a, StageHeader b) {
      const stagePrecedence = const <String>[
        "travis",
        "appveyor",
        "chromebot",
        "devicelab",
        "devicelab_win",
        "devicelab_ios",
      ];

      int aIdx = stagePrecedence.indexOf(a.stageName);
      aIdx = aIdx == -1 ? 1000000 : aIdx;
      int bIdx = stagePrecedence.indexOf(b.stageName);
      bIdx = bIdx == -1 ? 1000000 : bIdx;
      return aIdx.compareTo(bIdx);
    });
  }

  List<MetaTask> get allMetaTasks => stageHeaders.fold(<MetaTask>[], (List<MetaTask> prev, StageHeader h) {
    return prev..addAll(h.metaTasks);
  });
}

class StageHeader {
  StageHeader(this.stageName);

  final String stageName;
  final List<MetaTask> metaTasks = <MetaTask>[];

  void addMetaTask(TaskEntity taskEntity) {
    Task task = taskEntity.task;
    if (metaTasks.any((MetaTask m) => m.name == task.name))
      return;
    metaTasks.add(new MetaTask(taskEntity.key, task.name, task.stageName));
  }
}

/// Information about a task without a result.
class MetaTask {
  MetaTask(this.key, this.name, String stageName)
    : this.stageName = stageName,
      iconUrl = _iconForStageName(stageName);

  final Key key;
  final String name;
  final String stageName;
  final String iconUrl;
}

String _iconForStageName(String stageName) {
  const Map<String, String> iconMap = const <String, String>{
    'travis': '/travis.svg',
    'appveyor': '/appveyor.png',
    'chromebot': '/chromium.svg',
    'devicelab': '/android.svg',
    'devicelab_ios': '/apple.svg',
    'devicelab_win': '/windows.svg',
  };
  return iconMap[stageName];
}

class Color {
  final int r, g, b;

  const Color(this.r, this.g, this.b);

  /// A 6-digit hex CSS string representation of the color.
  String get cssHex => '#${_cHex(r)}${_cHex(g)}${_cHex(b)}';

  /// Prints a single color [component] to a 2-digit hex string.
  static String _cHex(int component) => component.toRadixString(16).padLeft(2, '0');

  /// Linear interpolation between two colors [from] and [to] with coefficient
  /// [c].
  static Color lerp(Color from, Color to, double c) => new Color(
      (from.r + (to.r - from.r) * c).toInt(),
      (from.g + (to.g - from.g) * c).toInt(),
      (from.b + (to.b - from.b) * c).toInt(),
  );
}

@Component(
  selector: 'legend',
  template: '''
  <div class="legend-icon" (click)="toggleVisibility()">?</div>
  <div *ngIf="legendVisible" class="legend">
    <div class="row">
      <div class="task-status-circle task-new"></div><span class="description">- new task</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-in-progress"></div><span class="description">- task is running</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-succeeded"></div><span class="description">- task succeeded</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-succeeded-but-flaky"></div><span class="description">- task is flaky</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-failed"></div><span class="description">- task failed</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-underperformed"></div><span class="description">- task underperformed</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-skipped"></div><span class="description">- task was skipped</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-unknown"></div><span class="description">- task status unknown</span>
    </div>
    <div class="row">
      <div class="task-status-circle task-failed task-known-to-be-flaky"></div><span class="description">- task marked flaky</span>
    </div>
  </div>
  ''',
  directives: const [NgIf, NgFor, NgClass, NgStyle],
)
class Legend {
  bool legendVisible = false;

  void toggleVisibility() {
    legendVisible = !legendVisible;
  }
}
