// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/datastore/v1.dart';
import 'package:meta/meta.dart';

import 'entities.dart';
import 'codec.dart';

class CocoonApi {
  /// Creates a database key for a Checklist.
  ///
  /// `repository` is the path to a repository relative to GitHub in the
  /// "owner/name" GitHub format. For example, `repository` for
  /// https://github.com/flutter/flutter is "flutter/flutter".
  ///
  /// `commit` is the git commit SHA.
  Key createChecklistKey(String repository, String commit) {
    return Key()
      ..path = <PathElement>[
        PathElement()
          ..id = 'Checklist'
          ..name = '$repository/$commit',
      ];
  }
}

DatastoreApi get api => null;

String get projectId => null;

class TaskApi {
  /// Saves a [Task] to database under the given key.
  ///
  /// If `key` is null, a new key is generated and the task entity is inserted
  /// as a new record.
  Future<TaskEntity> putTask({Key key, @required Task task}) async {
    key ??= Key()
      ..path = (<PathElement>[
        PathElement()..kind = 'Task',
      ]..addAll(task.checklistKey.path));
      CommitRequest x;
  }

  Future<TaskEntity> getTask(Key key) async {
    final LookupRequest request = LookupRequest()..keys = <Key>[key];
    final LookupResponse response =
        await api.projects.lookup(request, projectId);
    final EntityResult result = response.found.first;
    return taskCodec.decode(result.entity);
  }
}
