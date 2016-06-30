// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'dart:convert' show JSON;

import 'package:angular2/angular2.dart';
import 'package:cocoon/model.dart';

@Component(
  selector: 'status-table',
  template: '''
<div *ngIf="isLoading">Loading...</div>
<table *ngIf="!isLoading && statuses.length > 0">
  <tr>
    <td class="table-header-cell">
      Commit
    </td>
    <td *ngFor="let task of statuses.first.tasks" class="table-header-cell">
      {{task.task.name}}
    </td>
  </tr>
  <tr *ngFor="let status of statuses">
    <td class="table-header-cell">
      {{shortSha(status.checklist.checklist.commit.sha)}}
      ({{shortSha(status.checklist.checklist.commit.author.login)}})
    </td>
    <td *ngFor="let task of status.tasks">
      {{task.task.status}}
    </td>
  </tr>
</table>
''',
  directives: const [NgIf, NgFor]
)
class StatusTable implements OnInit {
  bool isLoading = true;
  List<BuildStatus> statuses;

  @override
  ngOnInit() async {
    GetStatusResult statusResult = GetStatusResult.fromJson(JSON.decode(await HttpRequest.getString('/api/get-status')));
    isLoading = false;
    statuses = statusResult.statuses ?? <BuildStatus>[];
  }

  String shortSha(String fullSha) {
    return fullSha.length > 7 ? fullSha.substring(0, 7) : fullSha;
  }
}
