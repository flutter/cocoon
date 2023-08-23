// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:truncate/truncate.dart';

import 'logging.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/hooks.dart';

/// A class for doing various actions related to Github commits.
class CommitService {
  CommitService({
    required this.config,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  });

  final Config config;
  final DatastoreServiceProvider datastoreProvider;

  /// Add a commit based on a [CreateEvent] to the Datastore.
  Future<void> handleCreateGithubRequest(CreateEvent createEvent) async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final RepositorySlug slug = RepositorySlug.full(createEvent.repository!.fullName);
    final String branch = createEvent.ref!;
    final Commit commit = await _createCommitFromBranchEvent(datastore, slug, branch);

    try {
      await datastore.lookupByValue<Commit>(commit.key);
    } on KeyNotFoundException {
      log.info('commit does not exist in datastore, inserting into datastore');
      await datastore.insert(<Commit>[commit]);
    }
  }

  Future<Commit> _createCommitFromBranchEvent(DatastoreService datastore, RepositorySlug slug, String branch) async {
    final GithubService githubService = await config.createDefaultGitHubService();
    final GitReference gitRef = await githubService.getReference(slug, 'heads/$branch');
    final String sha = gitRef.object!.sha!;
    final RepositoryCommit commit = await githubService.github.repositories.getCommit(slug, sha);

    final String id = '${slug.fullName}/$branch/$sha';
    final Key<String> key = datastore.db.emptyKey.append<String>(Commit, id: id);
    return Commit(
      key: key,
      timestamp: commit.author?.createdAt?.millisecondsSinceEpoch,
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
}
