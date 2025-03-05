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

@immutable
class GetStatusFirestore extends RequestHandler<Body> {
  const GetStatusFirestore({
    required super.config,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting
    this.buildStatusProvider = BuildStatusService.defaultProvider,
  });

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String kLastCommitKeyParam = 'lastCommitKey';
  static const String kBranchParam = 'branch';
  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final encodedLastCommitKey =
        request!.uri.queryParameters[kLastCommitKeyParam];
    final repoName =
        request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final slug = RepositorySlug('flutter', repoName);
    final branch =
        request!.uri.queryParameters[kBranchParam] ??
        Config.defaultBranch(slug);
    final datastore = datastoreProvider(config.db);
    final firestoreService = await config.createFirestoreService();
    final buildStatusService = buildStatusProvider(datastore, firestoreService);
    final keyHelper = config.keyHelper;
    final commitNumber = config.commitNumber;
    final lastCommitTimestamp = await _obtainTimestamp(
      encodedLastCommitKey,
      keyHelper,
      datastore,
    );

    final statuses =
        await buildStatusService
            .retrieveCommitStatusFirestore(
              limit: commitNumber,
              timestamp: lastCommitTimestamp,
              branch: branch,
              slug: slug,
            )
            .toList();

    return Body.forJson(<String, dynamic>{'Statuses': statuses});
  }

  Future<int> _obtainTimestamp(
    String? encodedLastCommitKey,
    KeyHelper keyHelper,
    DatastoreService datastore,
  ) async {
    /// [lastCommitTimestamp] is initially set as the current time, which allows query return
    /// latest commit list. If [owerKeyParam] is not empty, [lastCommitTimestamp] will be set
    /// as the timestamp of that [commit], and the query will return lastest commit
    /// list whose timestamp is smaller than [lastCommitTimestamp].
    var lastCommitTimestamp = DateTime.now().millisecondsSinceEpoch;

    if (encodedLastCommitKey != null) {
      final ownerKey = keyHelper.decode(encodedLastCommitKey) as Key<String>;
      final commit = await datastore.db.lookupValue<Commit>(
        ownerKey,
        orElse:
            () =>
                throw NotFoundException(
                  'Failed to find commit with key $ownerKey',
                ),
      );

      lastCommitTimestamp = commit.timestamp!;
    }
    return lastCommitTimestamp;
  }
}
