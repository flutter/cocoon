// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../model/firestore/commit.dart';
import '../model/firestore/commit_tasks_status.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';
import '../service/datastore.dart';

@immutable
final class GetStatus extends RequestHandler<Body> {
  const GetStatus({
    required super.config,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting
    this.buildStatusProvider = BuildStatusService.defaultProvider,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _now = now;

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;
  final DateTime Function() _now;

  static const String kLastCommitShaParam = 'lastCommitSha';
  static const String kBranchParam = 'branch';
  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final lastCommitSha = request!.uri.queryParameters[kLastCommitShaParam];

    final repoName =
        request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final slug = RepositorySlug('flutter', repoName);
    final branch =
        request!.uri.queryParameters[kBranchParam] ??
        Config.defaultBranch(slug);
    final datastore = datastoreProvider(config.db);
    final firestoreService = await config.createFirestoreService();
    final buildStatusService = buildStatusProvider(datastore, firestoreService);
    final commitNumber = config.commitNumber;
    final lastCommitTimestamp =
        lastCommitSha != null
            ? (await Commit.fromFirestoreBySha(
              firestoreService,
              sha: lastCommitSha,
            )).createTimestamp
            : _now().millisecondsSinceEpoch;

    final statuses =
        await buildStatusService
            .retrieveCommitStatusFirestore(
              limit: commitNumber,
              timestamp: lastCommitTimestamp,
              branch: branch,
              slug: slug,
            )
            .map(_SerializableCommitStatus.new)
            .toList();

    return Body.forJson(<String, dynamic>{'Statuses': statuses});
  }
}

/// The serialized representation of a [CommitStatus].
final class _SerializableCommitStatus {
  const _SerializableCommitStatus(this.status);

  final CommitTasksStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Commit': _SerializableCommit(status.commit).facade,
      'Status': '',
    };
  }
}

/// The serialized representation of a [Commit].
final class _SerializableCommit {
  const _SerializableCommit(this.commit);

  final Commit commit;

  @JsonKey(name: 'Checklist')
  Map<String, dynamic> get facade {
    return <String, dynamic>{
      'FlutterRepositoryPath': commit.repositoryPath,
      'CreateTimestamp': commit.createTimestamp,
      'Commit': <String, dynamic>{
        'Sha': commit.sha,
        'Message': commit.message,
        'Author': <String, dynamic>{
          'Login': commit.author,
          'avatar_url': commit.avatar,
        },
      },
      'Branch': commit.branch,
    };
  }
}
