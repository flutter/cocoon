// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';

/// Function signature for a [ReservationService] provider.
typedef ReservationServiceProvider = ReservationService Function(
    DatastoreService datastoreService);

class ReservationService {
  const ReservationService(this.datastore);

  final DatastoreService datastore;

  /// Creates and returns a [ReservationService] using [datastore].
  static ReservationService defaultProvider(DatastoreService datastore) {
    return ReservationService(datastore);
  }

  /// If another agent has obtained the reservation on the task before we've
  /// been able to secure our reservation, ths will throw a
  /// [ReservationLostException]
  Future<void> secureReservation(Task task, String agentId) async {
    assert(task != null);
    assert(agentId != null);
    try {
      final Task lockedTask = await datastore.lookupByValue<Task>(task.key);
      if (lockedTask.status != Task.statusNew) {
        // Another reservation beat us in a race.
        throw const ReservationLostException();
      }
      lockedTask.status = Task.statusInProgress;
      lockedTask.attempts += 1;
      lockedTask.startTimestamp = DateTime.now().millisecondsSinceEpoch;
      lockedTask.reservedForAgentId = agentId;
      await datastore.insert(<Task>[lockedTask]);
    } catch (error) {
      throw const ReservationLostException();
    }
  }
}

/// Exception representing an attempt to secure a task reservation that was
/// preempted by another reservation holder.
class ReservationLostException implements Exception {
  /// Creates a new [ReservationLostException].
  const ReservationLostException();
}
