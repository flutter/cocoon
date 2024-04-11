// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/key_helper.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/firestore.dart';

@immutable
class GetStatusFirestore extends RequestHandler<Body> {
  const GetStatusFirestore({
    required super.config,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting this.buildStatusProvider = BuildStatusService.defaultProvider,
  });

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String kLastCommitKeyParam = 'lastCommitKey';
  static const String kBranchParam = 'branch';
  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final String? encodedLastCommitKey = request!.uri.queryParameters[kLastCommitKeyParam];
    final String repoName = request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final RepositorySlug slug = RepositorySlug('flutter', repoName);
    final String branch = request!.uri.queryParameters[kBranchParam] ?? Config.defaultBranch(slug);
    final DatastoreService datastore = datastoreProvider(config.db);
    final FirestoreService firestoreService = await config.createFirestoreService();
    final BuildStatusService buildStatusService = buildStatusProvider(datastore, firestoreService);
    final KeyHelper keyHelper = config.keyHelper;
    final int commitNumber = config.commitNumber;
    final int lastCommitTimestamp = await _obtainTimestamp(encodedLastCommitKey, keyHelper, datastore);

    final List<SerializableCommitTasksStatus> statuses = await buildStatusService
        .retrieveCommitStatusFirestore(
          limit: commitNumber,
          timestamp: lastCommitTimestamp,
          branch: branch,
          slug: slug,
        )
        .map<SerializableCommitTasksStatus>(
          (CommitTasksStatus status) => SerializableCommitTasksStatus(status),
        )
        .toList();

    return Body.forJson(<String, dynamic>{
      'Statuses': statuses,
    });
  }

  Future<int> _obtainTimestamp(String? encodedLastCommitKey, KeyHelper keyHelper, DatastoreService datastore) async {
    /// [lastCommitTimestamp] is initially set as the current time, which allows query return
    /// latest commit list. If [owerKeyParam] is not empty, [lastCommitTimestamp] will be set
    /// as the timestamp of that [commit], and the query will return lastest commit
    /// list whose timestamp is smaller than [lastCommitTimestamp].
    int lastCommitTimestamp = DateTime.now().millisecondsSinceEpoch;

    if (encodedLastCommitKey != null) {
      final Key<String> ownerKey = keyHelper.decode(encodedLastCommitKey) as Key<String>;
      final Commit commit = await datastore.db.lookupValue<Commit>(
        ownerKey,
        orElse: () => throw NotFoundException('Failed to find commit with key $ownerKey'),
      );

      lastCommitTimestamp = commit.timestamp!;
    }
    return lastCommitTimestamp;
  }
}

/// The serialized representation of a [CommitStatus].
// TODO(tvolkert): Directly serialize [CommitStatus] once frontends migrate to new format.
class SerializableCommitTasksStatus {
  const SerializableCommitTasksStatus(this.status);

  final CommitTasksStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Commit': status.commit.toJson(),
      'Tasks': status.tasks,
    };
  }
}
