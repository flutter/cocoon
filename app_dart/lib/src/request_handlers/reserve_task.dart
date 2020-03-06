// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/agent.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/access_token_provider.dart';
import '../service/datastore.dart';

/// Reserves a pending task so that an agent may run the task.
@immutable
class ReserveTask extends ApiRequestHandler<ReserveTaskResponse> {
  ReserveTask(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting TaskProvider taskProvider,
    @visibleForTesting ReservationProvider reservationProvider,
    @visibleForTesting AccessTokenProvider accessTokenProvider,
  })  : taskProvider = taskProvider ??
            TaskProvider(datastore: DatastoreService(db: config.db)),
        reservationProvider =
            reservationProvider ?? ReservationProvider(config),
        accessTokenProvider =
            accessTokenProvider ?? AccessTokenProvider(config),
        super(config: config, authenticationProvider: authenticationProvider);

  final TaskProvider taskProvider;
  final ReservationProvider reservationProvider;
  final AccessTokenProvider accessTokenProvider;

  @override
  Future<ReserveTaskResponse> post() async {
    final Map<String, dynamic> params = requestData;
    Agent agent = authContext.agent;
    if (agent != null) {
      if (agent.agentId != params['AgentID']) {
        throw BadRequestException(
          'Authenticated agent (${agent.agentId}) does not match agent '
              'supplied in the request (${params['AgentID']})',
        );
      }
    } else {
      final String agentId = params['AgentID'];
      if (agentId == null) {
        throw const BadRequestException('AgentID not specified in request');
      }
      final Key key = config.db.emptyKey.append(Agent, id: agentId);
      agent = await config.db.lookupValue<Agent>(key, orElse: () {
        throw BadRequestException('Invalid agent ID: $agentId');
      });
    }

    const int maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final FullTask task = await taskProvider.findNextTask(agent);

      if (task == null) {
        return const ReserveTaskResponse.empty();
      }

      try {
        await reservationProvider.secureReservation(task.task, agent.id);
        final ClientContext clientContext = authContext.clientContext;
        final AccessToken token = await accessTokenProvider.createAccessToken(
          scopes: const <String>[
            'https://www.googleapis.com/auth/devstorage.read_write'
          ],
        );
        final KeyHelper keyHelper =
            KeyHelper(applicationContext: clientContext.applicationContext);
        return ReserveTaskResponse(task.task, task.commit, token, keyHelper);
      } on ReservationLostException {
        // Keep looking for another task.
        log.debug(
            'Reservation lost for task ${task.task.name} on commit ${task.commit.sha}');
        continue;
      }
    }

    log.warning('Could not secure reservation after $maxAttempts; giving up');
    return const ReserveTaskResponse.empty();
  }
}

@immutable
class ReserveTaskResponse extends JsonBody {
  const ReserveTaskResponse(
      this.task, this.commit, this.accessToken, this.keyHelper)
      : assert(task != null),
        assert(commit != null),
        assert(accessToken != null),
        assert(keyHelper != null);

  const ReserveTaskResponse.empty()
      : task = null,
        commit = null,
        accessToken = null,
        keyHelper = null;

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

  /// Used to serialize keys in the response.
  final KeyHelper keyHelper;

  @override
  Map<String, dynamic> toJson() {
    // package:json_serializable would work here, but only if we adjust the
    // agent to match what's output here. Since the agent needs to work against
    // the Go backend as well (temporarily), we hand-code the JSON format here.
    final Map<String, dynamic> taskMap = task == null
        ? null
        : <String, dynamic>{
            'Task': <String, dynamic>{
              'TimeoutInMinutes': task.timeoutInMinutes,
              'Name': task.name,
            },
            'Key': keyHelper.encode(task.key),
          };
    final Map<String, dynamic> commitMap = commit == null
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
class TaskProvider {
  TaskProvider({
    @required this.datastore,
  }) : assert(datastore != null);

  /// The backing datastore. Guaranteed to be non-null.
  final DatastoreService datastore;

  Future<FullTask> findNextTask(Agent agent) async {
    await for (Commit commit in datastore.queryRecentCommits()) {
      final List<Stage> stages =
          await datastore.queryTasksGroupedByStage(commit);
      for (Stage stage in stages) {
        if (!stage.isManagedByDeviceLab) {
          continue;
        }
        for (Task task in List<Task>.from(stage.tasks)..sort(Task.byAttempts)) {
          if (task.requiredCapabilities.isEmpty) {
            throw InvalidTaskException(
                'Task ${task.name} has no required capabilities');
          }
          if (task.status == Task.statusNew &&
              agent.isCapableOfPerformingTask(task)) {
            return FullTask(task, commit);
          }
        }
      }
    }

    return null;
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
  Future<void> secureReservation(Task task, String agentId) {
    assert(task != null);
    assert(agentId != null);
    try {
      return config.db.withTransaction<void>((Transaction transaction) async {
        final Task lockedTask = await transaction.lookupValue<Task>(task.key);

        if (lockedTask.status != Task.statusNew) {
          // Another reservation beat us in a race.
          throw const ReservationLostException();
        }

        lockedTask.status = Task.statusInProgress;
        lockedTask.attempts += 1;
        lockedTask.startTimestamp = DateTime.now().millisecondsSinceEpoch;
        lockedTask.reservedForAgentId = agentId;
        transaction.queueMutations(inserts: <Task>[lockedTask]);
        await transaction.commit();
      });
    } catch (error) {
      throw const ReservationLostException();
    }
  }
}

/// Exception representing an attempt to secure a task reservation that was
/// preempted by another reservation holder.
@visibleForTesting
class ReservationLostException implements Exception {
  /// Creates a new [ReservationLostException].
  const ReservationLostException();
}
