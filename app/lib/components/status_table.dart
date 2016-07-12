// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:angular2/angular2.dart';
import 'package:cocoon/model.dart';
import 'package:http/http.dart' as http;

@Component(
  selector: 'status-table',
  template: '''
<div *ngIf="isLoading">Loading...</div>
<table class="status-table"
       cellspacing="0"
       cellpadding="0"
       *ngIf="!isLoading && headerCol.length > 0">
  <tr>
    <td class="table-header-cell first-column">
      &nbsp;
    </td>
    <td class="table-header-cell"
        *ngFor="let stage of headerRow.stageHeaders"
        [colSpan]="stage.taskNames.length">
      {{stage.stageName}}
    </td>
  </tr>
  <tr>
    <td class="table-header-cell first-column">
      &nbsp;
    </td>
    <td class="table-header-cell"
        *ngFor="let taskName of headerRow.allTaskNames">
      <div class="task-name">{{taskName}}</div>
    </td>
  </tr>
  <tr *ngFor="let status of headerCol">
    <td class="table-header-cell first-column">
      <img width="10px" [src]="status.checklist.checklist.commit.author.avatarUrl">
      {{shortSha(status.checklist.checklist.commit.sha)}}
      ({{shortSha(status.checklist.checklist.commit.author.login)}})
    </td>
    <td class="task-status-cell" *ngFor="let taskName of headerRow.allTaskNames">
      <div [ngClass]="getStatusStyle(status.checklist.checklist.commit.sha, taskName)"></div>
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
  final resultMatrix = <String, Map<String, TaskEntity>>{};

  @override
  ngOnInit() async {
    Map<String, dynamic> statusJson = JSON.decode((await _httpClient.get('/api/get-status')).body);
    GetStatusResult statusResult = GetStatusResult.fromJson(statusJson);
    isLoading = false;

    List<BuildStatus> statuses = statusResult.statuses ?? <BuildStatus>[];
    headerCol = <BuildStatus>[];
    headerRow = new HeaderRow();

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

  List<String> getStatusStyle(String sha, String taskName) {
    Map<String, TaskEntity> row = resultMatrix[sha];
    if (row == null || !row.containsKey(taskName))
      return taskStatusToCssStyle('Skipped');
    TaskEntity task = row[taskName];
    return taskStatusToCssStyle(task.task.status);
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
      header.addTaskName(taskEntity.task.name);
    }
  }

  List<String> get allTaskNames => stageHeaders.fold(<String>[], (List<String> prev, StageHeader h) {
    return prev..addAll(h.taskNames);
  });
}

class StageHeader {
  StageHeader(this.stageName);

  final String stageName;
  final List<String> taskNames = <String>[];

  void addTaskName(String name) {
    if (taskNames.contains(name))
      return;
    taskNames.add(name);
  }
}
