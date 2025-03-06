// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:github/hooks.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';
import 'package:truncate/truncate.dart';

import '../../cocoon_service.dart';
import '../model/appengine/commit.dart';
import '../model/firestore/commit.dart' as firestore;
import 'datastore.dart';

/// A class for doing various actions related to Github commits.
class CommitService {
  CommitService({
    required this.config,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
  });

  final Config config;
  final DatastoreServiceProvider datastoreProvider;

  /// Add a commit based on a [CreateEvent] to the Datastore.
  Future<void> handleCreateGithubRequest(CreateEvent createEvent) async {
    final datastore = datastoreProvider(config.db);
    final slug = RepositorySlug.full(createEvent.repository!.fullName);
    final branch = createEvent.ref!;
    log.info(
      'Creating commit object for branch $branch in repository ${slug.fullName}',
    );
    final commit = await _createCommitFromBranchEvent(datastore, slug, branch);
    await _insertCommitIntoDatastore(datastore, commit);
  }

  /// Add a commit based on a Push event to the Datastore.
  /// https://docs.github.com/en/webhooks/webhook-events-and-payloads#push
  Future<void> handlePushGithubRequest(Map<String, dynamic> pushEvent) async {
    final datastore = datastoreProvider(config.db);
    final slug = RepositorySlug.full(pushEvent['repository']['full_name']);
    final sha = pushEvent['head_commit']['id'] as String;
    final branch = pushEvent['ref'].split('/')[2] as String;
    final id = '${slug.fullName}/$branch/$sha';
    final key = datastore.db.emptyKey.append<String>(Commit, id: id);
    final commit = Commit(
      key: key,
      timestamp:
          DateTime.parse(
            pushEvent['head_commit']['timestamp'],
          ).millisecondsSinceEpoch,
      repository: slug.fullName,
      sha: sha,
      author: pushEvent['sender']['login'],
      authorAvatarUrl: pushEvent['sender']['avatar_url'],
      // The field has a size of 1500 we need to ensure the commit message
      // is at most 1500 chars long.
      message: truncate(
        pushEvent['head_commit']['message'],
        1490,
        omission: '...',
      ),
      branch: branch,
    );
    await _insertCommitIntoDatastore(datastore, commit);
  }

  Future<Commit> _createCommitFromBranchEvent(
    DatastoreService datastore,
    RepositorySlug slug,
    String branch,
  ) async {
    final githubService = await config.createDefaultGitHubService();
    final gitRef = await githubService.getReference(slug, 'heads/$branch');
    final sha = gitRef.object!.sha!;
    final commit = await githubService.github.repositories.getCommit(slug, sha);

    final id = '${slug.fullName}/$branch/$sha';
    final key = datastore.db.emptyKey.append<String>(Commit, id: id);
    return Commit(
      key: key,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      repository: slug.fullName,
      sha: commit.sha,
      author: commit.author?.login,
      authorAvatarUrl: commit.author?.avatarUrl,
      // The field has a size of 1500 we need to ensure the commit message
      // is at most 1500 chars long.
      message: truncate(commit.commit!.message!, 1490, omission: '...'),
      branch: branch,
    );
  }

  Future<void> _insertCommitIntoDatastore(
    DatastoreService datastore,
    Commit commit,
  ) async {
    final firestoreService = await config.createFirestoreService();
    final datastore = datastoreProvider(config.db);
    try {
      log.info('Checking for existing commit in the datastore');
      await datastore.lookupByValue<Commit>(commit.key);
    } on KeyNotFoundException {
      log.info('Commit does not exist in datastore, inserting into datastore');
      await datastore.insert(<Commit>[commit]);
      try {
        final commitDocument = firestore.commitToCommitDocument(commit);
        final writes = documentsToWrites([commitDocument], exists: false);
        await firestoreService.batchWriteDocuments(
          BatchWriteRequest(writes: writes),
          kDatabase,
        );
      } catch (error) {
        log.warning(
          'Failed to insert new branched commit in Firestore: $error',
        );
      }
    }
  }
}
