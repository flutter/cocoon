// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:github/github.dart';

class FakeBuildStatusService implements BuildStatusService {
  FakeBuildStatusService({
    this.cumulativeStatus,
    this.commitStatuses,
  });

  BuildStatus? cumulativeStatus;
  List<CommitStatus>? commitStatuses;

  @override
  Future<BuildStatus?> calculateCumulativeStatus(RepositorySlug slug) async {
    if (cumulativeStatus == null) {
      throw AssertionError();
    }
    return cumulativeStatus;
  }

  @override
  Stream<CommitStatus> retrieveCommitStatus({
    int limit = 100,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) {
    if (commitStatuses == null) {
      throw AssertionError();
    }
    commitStatuses!.sort((CommitStatus a, CommitStatus b) => a.commit.timestamp!.compareTo(b.commit.timestamp!));

    return Stream<CommitStatus>.fromIterable(commitStatuses!.where((CommitStatus commitStatus) =>
        ((commitStatus.commit.timestamp == null || timestamp == null)
            ? true
            : commitStatus.commit.timestamp! < timestamp) &&
        commitStatus.commit.branch == branch));
  }

  @override
  Future<Map<String, int>> retrieveActiveBranchIds({
    int? timestamp,
  }) async {
    Map<String, int> branchIdToActivity = {};
    List<Commit>? commits = commitStatuses?.map((CommitStatus s) => s.commit).toList();
    if (commits == null) {
      return branchIdToActivity;
    }
    for (Commit commit in commits) {
      String branchId = '${commit.repository!}/${commit.branch}';
      int lastAcitivity = commit.timestamp!;
      if (branchIdToActivity.containsKey(branchId)) {
        branchIdToActivity[branchId] = max(branchIdToActivity[branchId]!, lastAcitivity);
      } else {
        branchIdToActivity[branchId] = lastAcitivity;
      }
    }
    return branchIdToActivity;
  }

  @override
  DatastoreService get datastoreService => throw UnimplementedError();
}
