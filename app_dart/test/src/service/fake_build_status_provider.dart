// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/datastore.dart';

class FakeBuildStatusProvider implements BuildStatusProvider {
  FakeBuildStatusProvider({
    this.cumulativeStatus,
    this.commitStatuses,
  });

  BuildStatus cumulativeStatus;
  List<CommitStatus> commitStatuses;

  @override
  DatastoreServiceProvider get datastoreProvider =>
      throw UnsupportedError('Unsupported');

  @override
  Future<BuildStatus> calculateCumulativeStatus() async {
    if (cumulativeStatus == null) {
      throw AssertionError();
    }
    return cumulativeStatus;
  }

  @override
  Stream<CommitStatus> retrieveCommitStatus(
      {int limit = 100, int timestamp, String branch}) {
    if (commitStatuses == null) {
      throw AssertionError();
    }
    commitStatuses.sort((CommitStatus a, CommitStatus b) =>
        a.commit.timestamp.compareTo(b.commit.timestamp));

    return Stream<CommitStatus>.fromIterable(commitStatuses.where(
        (CommitStatus commitStatus) =>
            commitStatus.commit.timestamp < timestamp &&
            commitStatus.commit.branch == branch));
  }
}
