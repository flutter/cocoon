// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../../datastore/cocoon_config.dart';
import '../../model/appengine/commit.dart';
import '../../model/appengine/key_helper.dart';
import '../../model/appengine/task.dart';
import '../../request_handling/api_request_handler.dart';
import '../../request_handling/authentication.dart';
import '../../request_handling/body.dart';

@immutable
class DebugGetTaskById extends ApiRequestHandler<GetTaskByIdResponse> {
  const DebugGetTaskById(
    Config config,
    AuthenticationProvider authenticationProvider,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  static const String commitParam = 'commit';
  static const String taskIdParam = 'task-id';

  @override
  Future<GetTaskByIdResponse> post() async {
    final Map<String, dynamic> params = requestData;
    checkRequiredParameters(params, <String>[commitParam, taskIdParam]);

    final Query<Commit> query = config.db.query()..filter('sha =', params[commitParam]);
    final List<Commit> commits = await query.run().toList();
    assert(commits.length <= 1);
    if (commits.isEmpty) {
      return null;
    }

    final Key taskKey = commits.single.key.append(Task, id: int.parse(params[taskIdParam]));
    final List<Task> tasks = await config.db.lookup<Task>(<Key>[taskKey]);
    if (tasks.isEmpty) {
      return null;
    }

    final KeyHelper keyHelper =
        KeyHelper(applicationContext: authContext.clientContext.applicationContext);
    return GetTaskByIdResponse(tasks.single, commits.single, keyHelper);
  }
}

@immutable
class GetTaskByIdResponse extends Body {
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
