// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../../datastore/cocoon_config.dart';
import '../../model/appengine/task.dart';
import '../../request_handling/api_request_handler.dart';
import '../../request_handling/authentication.dart';
import '../../request_handling/body.dart';

@immutable
class DebugResetPendingTasks
    extends ApiRequestHandler<ResetPendingTasksResponse> {
  const DebugResetPendingTasks(
    Config config,
    AuthenticationProvider authenticationProvider,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  static const String fromStatusParam = 'from-status';
  static const String fromReservedForAgentIdParam =
      'from-reserved-for-agent-id';
  static const String limitParam = 'limit';
  static const String toStatusParam = 'to-status';

  @override
  Future<ResetPendingTasksResponse> post() async {
    return config.db.withTransaction<ResetPendingTasksResponse>(
        (Transaction transaction) async {
      final Map<String, dynamic> params = requestData;
      final Query<Task> query = config.db.query<Task>()
        ..filter('status =', params[fromStatusParam] ?? Task.statusInProgress)
        ..filter(
            'reservedForAgentId =', params[fromReservedForAgentIdParam] ?? '')
        ..order('-createTimestamp')
        ..limit(params[limitParam] ?? 50);
      final List<Task> tasks = await query.run().toList();

      try {
        for (Task task in tasks) {
          task
            ..status = params[toStatusParam] ?? Task.statusNew
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
class ResetPendingTasksResponse extends JsonBody {
  const ResetPendingTasksResponse(this.count) : assert(count != null);

  final int count;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'count': count,
    };
  }
}
