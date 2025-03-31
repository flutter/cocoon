// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/build_status_provider/commit_tasks_status.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';

class FakeBuildStatusService implements BuildStatusService {
  FakeBuildStatusService({this.cumulativeStatus, this.commitTasksStatuses});

  BuildStatus? cumulativeStatus;
  List<CommitTasksStatus>? commitTasksStatuses;

  @override
  Future<BuildStatus?> calculateCumulativeStatus(RepositorySlug slug) async {
    if (cumulativeStatus == null) {
      throw AssertionError();
    }
    return cumulativeStatus;
  }

  @override
  Stream<CommitTasksStatus> retrieveCommitStatusFirestore({
    int limit = 100,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) {
    commitTasksStatuses!.sortBy((c) => c.commit.createTimestamp);
    return Stream<CommitTasksStatus>.fromIterable(
      commitTasksStatuses!.where(
        (CommitTasksStatus commitTasksStatus) =>
            ((timestamp == null)
                ? true
                : commitTasksStatus.commit.createTimestamp < timestamp) &&
            commitTasksStatus.commit.branch == branch,
      ),
    );
  }
}
