// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:cocoon/model.dart';
import 'package:http/http.dart' as http;

@Component(
  selector: 'status-table',
  template: '''
<div *ngIf="isLoading" style="position: fixed; top: 0; left: 0; background-color: #AAFFAA;">
  Loading...
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
      <img width="20px" [src]="metaTask.iconUrl">
      <div class="task-name">{{metaTask.name}}</div>
    </td>
  </tr>
  <tr *ngFor="let status of headerCol">
    <td class="table-header-cell first-column">
      <img width="20px" [src]="status.checklist.checklist.commit.author.avatarUrl">
      {{shortSha(status.checklist.checklist.commit.sha)}}
      ({{shortSha(status.checklist.checklist.commit.author.login)}})
    </td>
    <td class="task-status-cell" *ngFor="let metaTask of headerRow.allMetaTasks">
      <div [ngClass]="getStatusStyle(status.checklist.checklist.commit.sha, metaTask.name)"
           (click)="openLog(status.checklist.checklist.commit.sha, metaTask.name)">
      </div>
    </td>
  </tr>
</table>
''',
  directives: const [NgIf, NgFor, NgClass]
)
class StatusTable implements OnInit {
  StatusTable(this._httpClient);

  final http.Client _httpClient;
  bool isLoading = true;

  /// The first row in the table that shows stage names and task names.
  HeaderRow headerRow;

  /// The first column in the table that shows commit information.
  List<BuildStatus> headerCol;

  /// A sparse Commit X Task matrix of test results.
  Map<String, Map<String, TaskEntity>> resultMatrix = <String, Map<String, TaskEntity>>{};

  @override
  ngOnInit() async {
    reloadData();
    new Timer.periodic(const Duration(seconds: 30), (_) => reloadData());
  }

  Future<Null> reloadData() async {
    isLoading = true;
    Map<String, dynamic> statusJson = JSON.decode((await _httpClient.get('/api/get-status')).body);
    GetStatusResult statusResult = GetStatusResult.fromJson(statusJson);
    isLoading = false;

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

  List<String> taskStatusToCssStyle(String taskStatus) {
    const statusMap = const <String, String> {
      'New': 'task-new',
      'In Progress': 'task-in-progress',
      'Succeeded': 'task-succeeded',
      'Failed': 'task-failed',
      'Underperformed': 'task-underperformed',
      'Skipped': 'task-skipped',
    };
    return ['task-status-circle', statusMap[taskStatus] ?? 'task-unknown'];
  }

  TaskEntity _findTask(String sha, String taskName) {
    Map<String, TaskEntity> row = resultMatrix[sha];

    if (row == null || !row.containsKey(taskName))
      return null;

    return row[taskName];
  }

  List<String> getStatusStyle(String sha, String taskName) {
    TaskEntity taskEntity = _findTask(sha, taskName);

    if (taskEntity == null)
      return taskStatusToCssStyle('Skipped');

    return taskStatusToCssStyle(taskEntity.task.status);
  }

  void openLog(String sha, String taskName) {
    TaskEntity taskEntity = _findTask(sha, taskName);

    if (taskEntity != null)
      window.open('/api/get-log?ownerKey=${taskEntity.key.value}', '_blank');
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
      	"chromebot",
      	"devicelab",
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
    'chromebot': '/chromium.svg',
    'devicelab': '/android.svg',
  };
  return iconMap[stageName];
}
