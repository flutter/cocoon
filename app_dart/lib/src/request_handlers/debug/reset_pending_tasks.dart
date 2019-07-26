// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../../datastore/cocoon_config.dart';
import '../../model/task.dart';
import '../../request_handling/api_request_handler.dart';
import '../../request_handling/api_response.dart';
import '../../request_handling/request_context.dart';

@immutable
class DebugResetPendingTasks extends ApiRequestHandler<ResetPendingTasksResponse> {
  const DebugResetPendingTasks(Config config) : super(config: config);

  static const String fromStatusParam = 'from-status';
  static const String fromReservedForAgentIdParam = 'from-reserved-for-agent-id';
  static const String limitParam = 'limit';
  static const String toStatusParam = 'to-status';

  @override
  Future<ResetPendingTasksResponse> handleApiRequest(
    RequestContext context,
    Map<String, dynamic> request,
  ) {
    return config.db.withTransaction<ResetPendingTasksResponse>((Transaction transaction) async {
      Query<Task> query = config.db.query<Task>()
        ..filter('status =', request[fromStatusParam] ?? Task.statusInProgress)
        ..filter('reservedForAgentId =', request[fromReservedForAgentIdParam] ?? '')
        ..order('-createTimestamp')
        ..limit(request[limitParam] ?? 50);
      List<Task> tasks = await query.run().toList();

      try {
        for (Task task in tasks) {
          task
            ..status = request[toStatusParam] ?? Task.statusNew
            ..reservedForAgentId = ''
            ..startTimestamp = 0
            ..attempts = math.max(task.attempts - 1, 0);
        }
        transaction.queueMutations(inserts: tasks);
        await transaction.commit();
      } catch (error) {
        await transaction.rollback();
        rethrow;
      }

      return ResetPendingTasksResponse(tasks.length);
    });
  }
}

@immutable
class ResetPendingTasksResponse extends ApiResponse {
  const ResetPendingTasksResponse(this.count) : assert(count != null);

  final int count;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'count': count,
    };
  }
}
