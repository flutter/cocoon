// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart' as gae;
import 'package:gcloud/db.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/agent.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/service_account_info.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/api_response.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_context.dart';

/// Reserves a pending task so that an agent may run the task.
@immutable
class ReserveTask extends ApiRequestHandler<ReserveTaskResponse> {
  ReserveTask(
    Config config, {
    @visibleForTesting TaskProvider taskProvider,
    @visibleForTesting ReservationProvider reservationProvider,
    @visibleForTesting AccessTokenProvider accessTokenProvider,
  })  : this.taskProvider = taskProvider ?? TaskProvider(config),
        this.reservationProvider = reservationProvider ?? ReservationProvider(config),
        this.accessTokenProvider = accessTokenProvider ?? AccessTokenProvider(config),
        super(config: config);

  final TaskProvider taskProvider;
  final ReservationProvider reservationProvider;
  final AccessTokenProvider accessTokenProvider;

  @override
  Future<ReserveTaskResponse> handleApiRequest(
    RequestContext context,
    Map<String, dynamic> request,
  ) async {
    Agent agent;
    if (context.agent != null) {
      agent = context.agent;
      if (agent.agentId != request['AgentID']) {
        throw BadRequestException(
          'Authenticated agent (${agent.agentId}) does not match agent '
          'supplied in the request (${request['AgentID']})',
        );
      }
    } else {
      String agentId = request['AgentID'];
      if (agentId == null) {
        throw BadRequestException('AgentID not specified in request');
      }
      Key key = config.db.emptyKey.append(Agent, id: agentId);
      List<Agent> results = await config.db.lookup<Agent>([key]);
      agent = results.single;
    }

    while (true) {
      TaskAndCommit task = await taskProvider.findNextTask(agent);

      if (task == null) {
        return ReserveTaskResponse.empty();
      }

      try {
        await reservationProvider.secureReservation(task.task, agent.id);
        AccessToken accessToken = await accessTokenProvider.createAccessToken();
        return ReserveTaskResponse(task.task, task.commit, accessToken);
      } on ReservationLostException {
        // Keep looking for another task.
        continue;
      }
    }
  }
}

@immutable
class ReserveTaskResponse extends ApiResponse {
  const ReserveTaskResponse(this.task, this.commit, this.accessToken)
      : assert(task != null),
        assert(commit != null),
        assert(accessToken != null);

  const ReserveTaskResponse.empty()
      : task = null,
        commit = null,
        accessToken = null;

  /// The task that was reserved.
  ///
  /// The existence of this task in this response does not mean the task
  /// reservation has been secured in the cloud datastore yet. It is up to
  /// callers to manage the consistency of the reservation with the cloud
  /// datastore.
  ///
  /// This may be null, which indicates that no task was available to be
  /// reserved.
  ///
  /// See also:
  ///
  ///  * [ReserveTask.secureReservation], which secures consistency of the
  ///    reservation with the cloud datastore.
  final Task task;

  /// The commit that triggered the creation of [task].
  ///
  /// This commit "owns" [task] and represents the instantiation of the commit
  /// referenced by [Task.commitKey].
  ///
  /// This may be null, which indicates that no task was available.
  final Commit commit;

  /// The OAuth 2.0 access token that the receiver of this response may use to
  /// make authenticated requests back to App Engine.
  ///
  /// This may be null. Generally, when [task] is non-null, callers will want
  /// to return a response that contains an access token.
  ///
  /// See also:
  ///
  ///  * [withAccessToken], which is used to add an access token to a response
  ///    that otherwise did not have an access token.
  final AccessToken accessToken;

  @override
  Map<String, dynamic> toJson() {
    // package:json_serializable would work here, but only if we adjust the
    // agent to match what's output here. Since the agent needs to work against
    // the Go backend as well (temporarily), we hand-code the JSON format here.
    Map<String, dynamic> taskMap = task == null
        ? null
        : <String, dynamic>{
            'Task': <String, dynamic>{
              'TimeoutInMinutes': task.timeoutInMinutes,
              'Name': task.name,
            },
            'Key': task.key.id,
          };
    Map<String, dynamic> commitMap = commit == null
        ? null
        : <String, dynamic>{
            'Checklist': <String, dynamic>{
              'Commit': <String, dynamic>{
                'Sha': commit.sha,
              },
            },
          };
    return <String, dynamic>{
      'TaskEntity': taskMap,
      'ChecklistEntity': commitMap,
      'CloudAuthToken': accessToken?.data,
    };
  }
}

@visibleForTesting
class TaskAndCommit {
  const TaskAndCommit(this.task, this.commit)
      : assert(task != null),
        assert(commit != null);

  final Task task;
  final Commit commit;
}

@visibleForTesting
class TaskProvider {
  const TaskProvider(this.config);

  final Config config;

  Future<TaskAndCommit> findNextTask(Agent agent) async {
    Query<Commit> query = config.db.query<Commit>()
      ..limit(100)
      ..order('-timestamp');

    await for (Commit commit in query.run()) {
      List<Stage> stages = await _queryTasksGroupedByStage(commit);
      for (Stage stage in stages) {
        if (!stage.isManagedByDeviceLab) {
          continue;
        }
        for (Task task in List<Task>.from(stage.tasks)..sort(Task.byAttempts)) {
          if (task.requiredCapabilities.isEmpty) {
            throw InvalidTaskException('Task ${task.name} has no required capabilities');
          }
          if (task.status == Task.statusNew && agent.isCapableOfPerformingTask(task)) {
            return TaskAndCommit(task, commit);
          }
        }
      }
    }

    return null;
  }

  /// Finds all tasks owned by the specified [commit] and partitions them into
  /// stages.
  ///
  /// The returned list of stages will be ordered by the natural ordering of
  /// [Stage].
  Future<List<Stage>> _queryTasksGroupedByStage(Commit commit) async {
    Query<Task> query = config.db.query<Task>(ancestorKey: commit.key)..order('-stageName');
    Map<String, StageBuilder> stages = <String, StageBuilder>{};
    await for (Task task in query.run()) {
      if (!stages.containsKey(task.stageName)) {
        stages[task.stageName] = StageBuilder()
          ..commit = commit
          ..name = task.stageName;
      }
      stages[task.stageName].tasks.add(task);
    }
    List<Stage> result = stages.values.map<Stage>((StageBuilder stage) => stage.build()).toList();
    return result..sort();
  }
}

@visibleForTesting
class InvalidTaskException implements Exception {
  const InvalidTaskException(this.message);

  final String message;

  @override
  String toString() => message;
}

@visibleForTesting
class ReservationProvider {
  const ReservationProvider(this.config);

  final Config config;

  /// If another agent has obtained the reservation on the task before we've
  /// been able to secure our reservation, ths will throw a
  /// [ReservationLostException]
  Future<void> secureReservation(Task task, String agentId) async {
    assert(task != null);
    assert(agentId != null);
    return config.db.withTransaction<void>((Transaction transaction) async {
      try {
        List<Task> lookup = await transaction.lookup<Task>(<Key>[task.key]);
        Task lockedTask = lookup.single;

        if (lockedTask.status != Task.statusNew) {
          // Another reservation beat us in a race.
          throw ReservationLostException();
        }

        lockedTask.status = Task.statusInProgress;
        lockedTask.attempts += 1;
        lockedTask.startTimestamp = DateTime.now().millisecondsSinceEpoch;
        lockedTask.reservedForAgentId = agentId;
        transaction.queueMutations(inserts: <Model>[lockedTask]);
        await transaction.commit();
      } catch (error) {
        await transaction.rollback();
      }
    });
  }
}

/// Exception representing an attempt to secure a task reservation that was
/// preempted by another reservation holder.
@visibleForTesting
class ReservationLostException implements Exception {
  /// Creates a new [ReservationLostException].
  const ReservationLostException();
}

@visibleForTesting
class AccessTokenProvider {
  const AccessTokenProvider(this.config);

  final Config config;

  /// Returns an OAuth 2.0 access token for the device lab service account.
  Future<AccessToken> createAccessToken() async {
    if (gae.context.isDevelopmentEnvironment) {
      // No auth token needed.
      return null;
    }

    Map<String, dynamic> json = await config.deviceLabServiceAccount;
    ServiceAccountInfo accountInfo = ServiceAccountInfo.fromJson(json);
    http.Client httpClient = http.Client();
    try {
      AccessCredentials credentials = await obtainAccessCredentialsViaServiceAccount(
        accountInfo.asServiceAccountCredentials(),
        <String>['https://www.googleapis.com/auth/devstorage.read_write'],
        httpClient,
      );
      return credentials.accessToken;
    } finally {
      httpClient.close();
    }
  }
}
