// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import '../service/firestore.dart';
import '../service/logging.dart';

/// Endpoint for task runners to update Cocoon with test run information.
///
/// This handler requires (1) task identifier and (2) task status information.
///
/// 1. Tasks are identified by:
///  [gitBranchParam], [gitShaParam], [builderNameParam]
///
/// 2. Task status information
///  A. Required: [newStatusParam], either [Task.statusSucceeded] or [Task.statusFailed].
///  B. Optional: [resultsParam] and [scoreKeysParam] which hold performance benchmark data.
@immutable
class UpdateTaskStatus extends ApiRequestHandler<UpdateTaskStatusResponse> {
  const UpdateTaskStatus({
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  });

  final DatastoreServiceProvider datastoreProvider;

  static const String gitBranchParam = 'CommitBranch';
  static const String gitShaParam = 'CommitSha';
  static const String newStatusParam = 'NewStatus';
  static const String builderNameParam = 'BuilderName';
  static const String testFlayParam = 'TestFlaky';

  @override
  Future<UpdateTaskStatusResponse> post() async {
    checkRequiredParameters(<String>[newStatusParam, gitBranchParam, gitShaParam, builderNameParam]);

    final DatastoreService datastore = datastoreProvider(config.db);
    final String newStatus = requestData![newStatusParam] as String;
    final bool isTestFlaky = (requestData![testFlayParam] as bool?) ?? false;

    if (newStatus != Task.statusSucceeded && newStatus != Task.statusFailed) {
      throw const BadRequestException('NewStatus can be one of "Succeeded", "Failed"');
    }

    final Task task = await _getTaskFromNamedParams(datastore);

    task.status = newStatus;
    task.endTimestamp = DateTime.now().millisecondsSinceEpoch;
    task.isTestFlaky = isTestFlaky;

    await datastore.insert(<Task>[task]);

    try {
      await updateTaskDocument(task.status, task.endTimestamp!, task.isTestFlaky!);
    } catch (error) {
      log.warning('Failed to update task in Firestore: $error');
    }
    return UpdateTaskStatusResponse(task);
  }

  Future<void> updateTaskDocument(String status, int endTimestamp, bool isTestFlaky) async {
    final FirestoreService firestoreService = await config.createFirestoreService();
    final String sha = (requestData![gitShaParam] as String).trim();
    final String? taskName = requestData![builderNameParam] as String?;
    final String documentName = '$kDatabase/documents/tasks/${sha}_${taskName}_1';
    log.info('getting firestore document: $documentName');
    final List<firestore.Task> initialTasks = await firestoreService.queryCommitTasks(sha);
    final firestore.Task firestoreTask = initialTasks.where((firestore.Task task) => task.taskName == taskName).reduce(
          (firestore.Task current, firestore.Task next) => current.name!.compareTo(next.name!) > 0 ? current : next,
        );
    firestoreTask.setStatus(status);
    firestoreTask.setEndTimestamp(endTimestamp);
    firestoreTask.setTestFlaky(isTestFlaky);
    final List<Write> writes = documentsToWrites([firestoreTask], exists: true);
    await firestoreService.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
  }

  /// Retrieve [Task] from [DatastoreService] when given [gitShaParam], [gitBranchParam], and [builderNameParam].
  ///
  /// This is used when the DeviceLab test runner is uploading results to Cocoon for runs on LUCI.
  /// LUCI does not know the [Key] assigned to task when scheduling the build, but Cocoon can
  /// lookup the task based on these key values.
  ///
  /// To lookup the value, we construct the ancestor key, which corresponds to the [Commit].
  /// Then we query the tasks with that ancestor key and search for the one that matches the builder name.
  Future<Task> _getTaskFromNamedParams(DatastoreService datastore) async {
    final Key<String> commitKey = await _constructCommitKey(datastore);

    final String? builderName = requestData![builderNameParam] as String?;
    final Query<Task> query = datastore.db.query<Task>(ancestorKey: commitKey);
    final List<Task> initialTasks = await query.run().toList();
    log.fine('Found ${initialTasks.length} tasks for commit');
    final List<Task> tasks = <Task>[];
    log.fine('Searching for task with builderName=$builderName');
    for (Task task in initialTasks) {
      if (task.builderName == builderName || task.name == builderName) {
        tasks.add(task);
      }
    }

    if (tasks.length != 1) {
      log.severe('Found ${tasks.length} entries for builder $builderName');
      throw InternalServerError('Expected to find 1 task for $builderName, but found ${tasks.length}');
    }

    return tasks.first;
  }

  /// Construct the Datastore key for [Commit] that is the ancestor to this [Task].
  ///
  /// Throws [BadRequestException] if the given git branch does not exist in [CocoonConfig].
  Future<Key<String>> _constructCommitKey(DatastoreService datastore) async {
    final String gitBranch = (requestData![gitBranchParam] as String).trim();
    final String gitSha = (requestData![gitShaParam] as String).trim();

    final String id = 'flutter/flutter/$gitBranch/$gitSha';
    final Key<String> commitKey = datastore.db.emptyKey.append<String>(Commit, id: id);
    log.fine('Constructed commit key=$id');
    // Return the official key from Datastore for task lookups.
    final Commit commit = await config.db.lookupValue<Commit>(commitKey);
    return commit.key;
  }
}

@immutable
class UpdateTaskStatusResponse extends JsonBody {
  const UpdateTaskStatusResponse(this.task);

  final Task task;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Name': task.name,
      'Status': task.status,
    };
  }
}
