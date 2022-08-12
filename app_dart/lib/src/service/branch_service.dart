// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' show GitHubError, RepositoryCommit, RepositorySlug;
import 'package:github/hooks.dart';
import 'package:retry/retry.dart';

import '../model/appengine/branch.dart';
import '../model/gerrit/commit.dart';
import '../request_handling/exceptions.dart';
import 'gerrit_service.dart';
import 'logging.dart';

class RetryException implements Exception {}

/// A class to manage GitHub branches.
///
/// Track branch activities such as branch creation, and helps manage release branches.
class BranchService {
  BranchService({
    required this.config,
    required this.gerritService,
    this.retryOptions = const RetryOptions(),
  });

  final Config config;
  final GerritService gerritService;
  final RetryOptions retryOptions;

  /// Add a [CreateEvent] branch to Datastore.
  Future<void> handleCreateRequest(CreateEvent createEvent) async {
    log.info('the branch parsed from string request is ${createEvent.ref}');

    final String? refType = createEvent.refType;
    if (refType == 'tag') {
      log.info('create branch event was rejected because it is a tag');
      return;
    }
    final String? branch = createEvent.ref;
    if (branch == null) {
      log.warning('Branch is null, exiting early');
      return;
    }
    final String repository = createEvent.repository!.slug().fullName;
    final int lastActivity = createEvent.repository!.pushedAt!.millisecondsSinceEpoch;
    final bool forked = createEvent.repository!.isFork;

    if (forked) {
      log.info('create branch event was rejected because the branch is a fork');
      return;
    }

    final String id = '$repository/$branch';
    log.info('the id used to create branch key was $id');
    final DatastoreService datastore = DatastoreService.defaultProvider(config.db);
    final Key<String> key = datastore.db.emptyKey.append<String>(Branch, id: id);
    final Branch currentBranch = Branch(key: key, lastActivity: lastActivity);
    try {
      await datastore.lookupByValue<Branch>(currentBranch.key);
    } on KeyNotFoundException {
      log.info('create branch event was successful since the key is unique');
      await datastore.insert(<Branch>[currentBranch]);
    } catch (e) {
      log.severe('Unexpected exception was encountered while inserting branch into database: $e');
    }
  }

  /// Creates a flutter/recipes branch that aligns to a flutter/flutter branch.
  ///
  /// Take the example repo history:
  ///   flutter/flutter: A -> B -> C -> D -> E
  ///   flutter/recipes: V -> W -> X -> Y -> Z
  ///
  /// If flutter/flutter branches at C, this finds the flutter/recipes commit that should be used for C.
  /// The best guess for a flutter/recipes commit that aligns with C is whatever was the most recently committed
  /// before C was committed.
  ///
  /// Once the flutter/recipes commit is found, it is branched to match flutter/flutter.
  ///
  /// Generally, this should work. However, some edge cases may require CPs. Such as when commits land in a
  /// short timespan, and require the release manager to CP onto the recipes branch (in the case of reverts).
  Future<void> branchFlutterRecipes(String branch) async {
    final RepositorySlug recipesSlug = RepositorySlug('flutter', 'recipes');
    if ((await gerritService.branches('${recipesSlug.owner}-review.googlesource.com', recipesSlug.name,
            subString: branch))
        .contains(branch)) {
      // subString is a regex, and can return multiple matches
      log.warning('$branch already exists for $recipesSlug');
      throw BadRequestException('$branch already exists');
    }
    final Iterable<GerritCommit> recipeCommits =
        await gerritService.commits(recipesSlug, Config.defaultBranch(recipesSlug));
    log.info('$recipesSlug commits: $recipeCommits');
    final GithubService githubService = await config.createDefaultGitHubService();
    final List<RepositoryCommit> githubCommits = await retryOptions.retry(
      () async => await githubService.listCommits(Config.flutterSlug, branch, null),
      retryIf: (Exception e) => e is GitHubError,
    );
    log.info('${Config.flutterSlug} branch commits: $githubCommits');
    for (GerritCommit recipeCommit in recipeCommits) {
      if (recipeCommit.author!.time!.isBefore(githubCommits.first.commit!.committer!.date!)) {
        final String revision = recipeCommit.commit!;
        return await gerritService.createBranch(recipesSlug, branch, revision);
      }
    }

    throw InternalServerError('Failed to find a revision to branch Flutter recipes for $branch');
  }
}
