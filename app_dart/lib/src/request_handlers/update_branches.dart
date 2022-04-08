// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/branch.dart' as md;
import 'package:gcloud/db.dart';
import 'package:github/github.dart' show Branch, GitHub, RepositoryCommit, RepositorySlug;
import 'package:process_runner/process_runner.dart';

import '../model/appengine/key_helper.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/config.dart';
import '../service/datastore.dart';

/// Update and return currently active branches across all repos.
///
/// Returns all branches with associated key, branch name and repository name, for branches with recent commit acitivies
/// within the past [GetBranches.kActiveBranchActivityPeriod] days.
///
/// GET: /api/update-branches
///
///
/// Response: Status 200 OK
///[
///      {
///         "key":ahFmbHV0dGVyLWRhc2hib2FyZHIuCxIGQnJhbmNoIiJmbHV0dGVyL2ZsdXR0ZXIvYnJhbmNoLWNyZWF0ZWQtb2xkDKIBCVtkZWZhdWx0XQ,
///         "branch":{
///            "branch":"branch-created-old",
///            "repository":"flutter/flutter"
///         }
///      }
///     {
///        "key":ahFmbHV0dGVyLWRhc2hib2FyZHIuCxIGQnJhbmNoIiJmbHV0dGVyL2ZsdXR0ZXIvYnJhbmNoLWNyZWF0ZWQtbm93DKIBCVtkZWZhdWx0XQ,
///        "branch":{
///           "branch":"branch-created-now",
///           "repository":"flutter/flutter"
///        }
///     }
///]

class UpdateBranches extends RequestHandler<Body> {
  UpdateBranches(
    Config config, {
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.processRunner,
  }) : super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  ProcessRunner? processRunner;

  static const int kActiveBranchActivityPeriod = 7;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final KeyHelper keyHelper = config.keyHelper;

    await _updateBranchesForAllRepos(config, datastore);

    final List<BranchWrapper> branches = await datastore
        .queryBranches()
        .where((md.Branch b) =>
            DateTime.now().millisecondsSinceEpoch - b.lastActivity! <
            const Duration(days: kActiveBranchActivityPeriod).inMilliseconds)
        .map<BranchWrapper>((md.Branch branch) => BranchWrapper(branch, keyHelper.encode(branch.key)))
        .toList();
    return Body.forJson(branches);
  }

  Future<void> _updateBranchesForAllRepos(Config config, DatastoreService datastore) async {
    DateTime timeNow = DateTime.now();

    processRunner ??= ProcessRunner();
    final Set<RepositorySlug> slugs = Config.supportedRepos;
    for (RepositorySlug slug in slugs) {
      ProcessRunnerResult result =
          await processRunner!.runProcess(['git', 'ls-remote', '--heads', 'git@github.com:flutter/${slug.name}']);
      List<String> shaAndName = result.stdout.trim().split(RegExp(' |\t|\r?\n'));
      List<String> branchShas = [];
      List<String> branchNames = [];
      for (int i = 0; i < shaAndName.length; i += 2) {
        branchShas.add(shaAndName[i]);
        branchNames.add(shaAndName[i + 1].replaceAll('refs/heads/', ''));
      }
      final GitHub github = await config.createGitHubClient(slug: slug);
      await _updateBranchesForRepo(branchShas, branchNames, github, slug, datastore, timeNow);
    }
    return;
  }

  Future<void> _updateBranchesForRepo(List<String> branchShas, List<String> branchNames, GitHub github,
      RepositorySlug slug, DatastoreService datastore, DateTime timeNow) async {
    List<md.Branch> updatedBranches = [];
    for (int i = 0; i < branchShas.length; i += 1) {
      final RepositoryCommit branchCommit = await github.repositories.getCommit(slug, branchShas[i]);
      int lastUpdate = branchCommit.commit!.committer!.date!.millisecondsSinceEpoch;
      if (lastUpdate > timeNow.subtract(const Duration(days: kActiveBranchActivityPeriod)).millisecondsSinceEpoch) {
        final String id = '${slug.fullName}/${branchNames[i]}';
        final Key<String> key = datastore.db.emptyKey.append<String>(Branch, id: id);
        updatedBranches.add(md.Branch(key: key, lastActivity: lastUpdate));
      }
    }
    await datastore.insert(updatedBranches);
  }
}

// FOR REVIEW: Probably related to how keyhelper is implementated,
// but I have to add a wrapper class to avoid `Converting object to an encodable object failed: Instance of 'SerializableBranch'` error
class BranchWrapper {
  const BranchWrapper(this.branch, this.key);

  final md.Branch branch;
  final String key;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'branch': md.SerializableBranch(branch).facade,
    };
  }
}
