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
  Stream<CommitStatus> retrieveCommitStatus({
    int numberOfCommitsToReference = 100,
  }) {
    if (commitStatuses == null) {
      throw AssertionError();
    }
    return Stream<CommitStatus>.fromIterable(commitStatuses);
  }
}
