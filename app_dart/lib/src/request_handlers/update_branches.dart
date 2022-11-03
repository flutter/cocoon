// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_service/src/model/appengine/branch.dart' as md;
import 'package:gcloud/db.dart';
import 'package:github/github.dart' show Branch, GitHub, RepositoryCommit, RepositorySlug;
import 'package:process/process.dart';

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
  UpdateBranches({
    required super.config,
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.processManager,
  });

  final DatastoreServiceProvider datastoreProvider;
  ProcessManager? processManager;

  static const Duration kActiveBranchActivityPeriod = Duration(days: 60);

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    await _updateBranchesForAllRepos(config, datastore);

    final List<md.Branch> branches = await datastore
        .queryBranches()
        .where(
          (md.Branch b) =>
              DateTime.now().millisecondsSinceEpoch - b.lastActivity! < kActiveBranchActivityPeriod.inMilliseconds,
        )
        .toList();
    return Body.forJson(branches);
  }

  Future<void> _updateBranchesForAllRepos(Config config, DatastoreService datastore) async {
    final DateTime timeNow = DateTime.now();

    processManager ??= const LocalProcessManager();
    final Set<RepositorySlug> slugs = config.supportedRepos;
    for (RepositorySlug slug in slugs) {
      final ProcessResult result =
          processManager!.runSync(['git', 'ls-remote', '--heads', 'git@github.com:flutter/${slug.name}']);
      // https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499- only a exit code of 0 is good for windows
      // for mac or linux, exit code in the range 0 to 255 is good
      if ((Platform.isWindows && result.exitCode != 0) ||
          ((Platform.isMacOS || Platform.isLinux) && result.exitCode < 0)) {
        throw const FormatException('returned exit code from git ls-remote is bad');
      }
      final List<String> shaAndName = (result.stdout as String).trim().split(RegExp(' |\t|\r?\n'));
      final List<String> branchShas = [];
      final List<String> branchNames = [];
      for (int i = 0; i < shaAndName.length; i += 2) {
        branchShas.add(shaAndName[i]);
        branchNames.add(shaAndName[i + 1].replaceAll('refs/heads/', ''));
      }
      final GitHub github = await config.createGitHubClient(slug: slug);
      await _updateBranchesForRepo(branchShas, branchNames, github, slug, datastore, timeNow);
    }
    return;
  }

  Future<void> _updateBranchesForRepo(
    List<String> branchShas,
    List<String> branchNames,
    GitHub github,
    RepositorySlug slug,
    DatastoreService datastore,
    DateTime timeNow,
  ) async {
    final List<md.Branch> updatedBranches = [];
    for (int i = 0; i < branchShas.length; i += 1) {
      final RepositoryCommit branchCommit = await github.repositories.getCommit(slug, branchShas[i]);
      final int lastUpdate = branchCommit.commit!.committer!.date!.millisecondsSinceEpoch;
      if (lastUpdate > timeNow.subtract(kActiveBranchActivityPeriod).millisecondsSinceEpoch) {
        final String id = '${slug.fullName}/${branchNames[i]}';
        final Key<String> key = datastore.db.emptyKey.append<String>(Branch, id: id);
        updatedBranches.add(md.Branch(key: key, lastActivity: lastUpdate));
      }
    }
    await datastore.insert(updatedBranches);
  }
}
