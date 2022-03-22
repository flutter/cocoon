// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/datastore.dart';

import '../../model/appengine/task.dart';

abstract class SchedulingPolicy {
  Future<bool> shouldTrigger({
    required Task task,
    required DatastoreService datastore,
  });
}

class GuranteedPolicy implements SchedulingPolicy {
  @override
  Future<bool> shouldTrigger({required Task task, required DatastoreService datastore,}) async => true;
}

class BatchPolicy implements SchedulingPolicy {
  @override
  Future<bool> shouldTrigger({required Task task, required DatastoreService datastore,}) async {
    // TODO(chillers): Look up column of previous tasks.
    return false;
  }
}

