// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class MigrateChecklist extends ApiRequestHandler<MigrateChecklistResponse> {
  const MigrateChecklist(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting
        this.datastoreProvider = DatastoreService.defaultProvider,
    TabledataResourceApi tabledataResourceApi,
  })  : assert(datastoreProvider != null),
        tabledataResourceApi = tabledataResourceApi ?? TabledataResourceApi,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final TabledataResourceApi tabledataResourceApi;

  @override
  Future<MigrateChecklistResponse> get() async {
    /// Current daily commit number is at most of 30s
    /// 
    /// [maxRecord] 100 should be big enough for different scenarios
    const int maxRecords = 100;
    const String projectId = 'flutter-dashboard';
    const String dataset = 'cocoon';
    const String table = 'Checklist';

    final DatastoreService datastore = datastoreProvider();
    final List<Commit> commits = await datastore
        .queryRecentUnexportedCommits(limit: maxRecords)
        .toList();

    if (commits.isEmpty) {
      return const MigrateChecklistResponse(<Commit>[]);
    }

    for (Commit commit in commits) {
      final TableDataInsertAllRequest rows =
          TableDataInsertAllRequest.fromJson(<String, Object>{
        'rows': <Map<String, Object>>[
          <String, Object>{
            'json': <String, Object>{
              'ID': commit.id,
              'CreateTimestamp': commit.timestamp,
              'FlutterRepositoryPath': commit.repository,
              'CommitSha': commit.sha,
              'CommitAuthorLogin': commit.author,
              'CommitAuthorAvatarURL': commit.authorAvatarUrl,
            },
          }
        ],
      });
      await tabledataResourceApi.insertAll(rows, projectId, dataset, table);

      commit.isExported = true;
      await datastore.db.commit(inserts: <Commit>[commit]);
    }

    return MigrateChecklistResponse(commits);
  }
}

class MigrateChecklistResponse extends JsonBody {
  const MigrateChecklistResponse(this.response);

  final List<Commit> response;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Exported Commits Number:': response.length,
      'SHA List':
          response.map((Commit commit) => commit.sha).toList().join(','),
    };
  }
}
