// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../../datastore/cocoon_config.dart';
import '../../model/commit.dart';
import '../../model/key_helper.dart';
import '../../model/task.dart';
import '../../request_handling/api_request_handler.dart';
import '../../request_handling/api_response.dart';
import '../../request_handling/request_context.dart';

@immutable
class DebugGetTaskById extends ApiRequestHandler<GetTaskByIdResponse> {
  const DebugGetTaskById(Config config) : super(config: config);

  static const String commitParam = 'commit';
  static const String taskIdParam = 'task-id';

  @override
  Future<GetTaskByIdResponse> handleApiRequest(
    RequestContext context,
    Map<String, dynamic> request,
  ) async {
    checkRequiredParameters(request, <String>[commitParam, taskIdParam]);

    Query<Commit> query = config.db.query()..filter('sha =', request[commitParam]);
    List<Commit> commits = await query.run().toList();
    assert(commits.length <= 1);
    if (commits.isEmpty) {
      return null;
    }

    Key taskKey = commits.single.key.append(Task, id: int.parse(request[taskIdParam]));
    List<Task> tasks = await config.db.lookup<Task>(<Key>[taskKey]);
    if (tasks.isEmpty) {
      return null;
    }

    KeyHelper keyHelper = KeyHelper(applicationContext: context.clientContext.applicationContext);
    return GetTaskByIdResponse(tasks.single, commits.single, keyHelper);
  }
}

@immutable
class GetTaskByIdResponse extends ApiResponse {
  const GetTaskByIdResponse(this.task, this.commit, this.keyHelper)
      : assert(task != null),
        assert(commit != null),
        assert(keyHelper != null);

  final Task task;
  final Commit commit;
  final KeyHelper keyHelper;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'TaskEntity': <String, dynamic>{
        'Task': <String, dynamic>{
          'TimeoutInMinutes': task.timeoutInMinutes,
          'Name': task.name,
        },
        'Key': keyHelper.encode(task.key),
      },
      'ChecklistEntity': <String, dynamic>{
        'Checklist': <String, dynamic>{
          'Commit': <String, dynamic>{
            'Sha': commit.sha,
          },
        },
      },
    };
  }
}
