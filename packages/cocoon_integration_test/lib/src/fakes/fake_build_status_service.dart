// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_service/src/service/build_status_provider/commit_tasks_status.dart';
import 'package:cocoon_service/src/service/build_status_service.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';

// TODO(matanlurey): Remove this shim over Firestore and use FakeFirestore instead.
class FakeBuildStatusService implements BuildStatusService {
  FakeBuildStatusService({this.cumulativeStatus, this.commitTasksStatuses});

  BuildStatus? cumulativeStatus;
  List<CommitTasksStatus>? commitTasksStatuses;

  @override
  Future<BuildStatus> calculateCumulativeStatus(
    RepositorySlug slug, {
    String? branch,
  }) async {
    if (cumulativeStatus == null) {
      throw AssertionError();
    }
    return cumulativeStatus!;
  }

  @override
  Future<List<CommitTasksStatus>> retrieveCommitStatusFirestore({
    int limit = 100,
    TimeRange? created,
    String? branch,
    required RepositorySlug slug,
  }) async {
    commitTasksStatuses!.sortBy((c) => c.commit.createTimestamp);
    return commitTasksStatuses!.where((status) {
      if (status.commit.branch != branch) {
        return false;
      }
      if (created != null) {
        return created.contains(
          DateTime.fromMillisecondsSinceEpoch(status.commit.createTimestamp),
        );
      }
      return true;
    }).toList();
  }
}
