// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart' as gh;
import 'package:retry/retry.dart';

import '../model/appengine/branch.dart';
import '../model/gerrit/commit.dart';
import '../request_handling/exceptions.dart';
import 'gerrit_service.dart';
import 'logging.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/hooks.dart';

class RetryException implements Exception {}

/// A class to manage GitHub branches.
///
/// Track branch activities such as branch creation, and helps manage release branches.
class BranchService {
  BranchService({
    required this.config,
    required this.gerritService,
    this.retryOptions = const RetryOptions(maxAttempts: 3),
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
      log.fine('Branch is null, exiting early');
      return;
    }
    final gh.RepositorySlug slug = createEvent.repository!.slug();
    final int lastActivity = createEvent.repository!.pushedAt!.millisecondsSinceEpoch;
    final bool forked = createEvent.repository!.isFork;

    if (forked) {
      log.info('create branch event was rejected because the branch is a fork');
      return;
    }

    final String id = '${slug.fullName}/$branch';
    log.info('the id used to create branch key was $id');
    final DatastoreService datastore = DatastoreService.defaultProvider(config.db);
    final Key<String> key = datastore.db.emptyKey.append<String>(Branch, id: id);
    final Branch currentBranch = Branch(key: key, lastActivity: lastActivity);
    try {
      await datastore.lookupByValue<Branch>(currentBranch.key);
    } on KeyNotFoundException {
      log.info('create branch event was successful since the key is unique');
      await datastore.insert(<Branch>[currentBranch]);
    }
  }

  /// Creates a flutter/recipes branch that aligns to a flutter/engine commit.
  ///
  /// Take the example repo history:
  ///   flutter/engine: A -> B -> C -> D -> E
  ///   flutter/recipes: V -> W -> X -> Y -> Z
  ///
  /// If flutter/engine branches at C, this finds the flutter/recipes commit that should be used for C.
  /// The best guess for a flutter/recipes commit that aligns with C is whatever was the most recently committed
  /// before C was committed.
  ///
  /// Once the flutter/recipes commit is found, it is branched to match flutter/engine.
  ///
  /// Generally, this should work. However, some edge cases may require CPs. Such as when commits land in a
  /// short timespan, and require the release manager to CP onto the recipes branch (in the case of reverts).
  Future<void> branchFlutterRecipes(String branch, String engineSha) async {
    final gh.RepositorySlug recipesSlug = gh.RepositorySlug('flutter', 'recipes');
    if ((await gerritService.branches(
      '${recipesSlug.owner}-review.googlesource.com',
      recipesSlug.name,
      filterRegex: branch,
    ))
        .contains(branch)) {
      // subString is a regex, and can return multiple matches
      log.warning('$branch already exists for $recipesSlug');
      throw BadRequestException('$branch already exists');
    }
    final Iterable<GerritCommit> recipeCommits =
        await gerritService.commits(recipesSlug, Config.defaultBranch(recipesSlug));
    log.info('$recipesSlug commits: $recipeCommits');
    final gh.RepositoryCommit engineCommit = await retryOptions.retry(
      () async {
        final GithubService githubService = await config.createDefaultGitHubService();
        return githubService.github.repositories.getCommit(Config.engineSlug, engineSha);
      },
      retryIf: (Exception e) => e is gh.GitHubError,
    );
    log.info('${Config.engineSlug} commit: $engineCommit');
    final DateTime? branchTime = engineCommit.commit?.committer?.date;
    if (branchTime == null) {
      throw BadRequestException('$engineSha has no commit time');
    }
    log.info('Searching for a recipe commit before $branchTime');
    for (GerritCommit recipeCommit in recipeCommits) {
      final DateTime? recipeTime = recipeCommit.author?.time;

      if (recipeTime != null && recipeTime.isBefore(branchTime)) {
        final String revision = recipeCommit.commit!;
        return gerritService.createBranch(recipesSlug, branch, revision);
      }
    }

    throw InternalServerError('Failed to find a revision to flutter/recipes for $branch before $branchTime');
  }

  /// Returns a Map that contains the latest google3 roll, beta, and stable branches.
  ///
  /// Latest beta and stable branches are retrieved based on 'beta' and 'stable' tags. Dev branch is retrived
  /// as the latest flutter candidate branch.
  Future<List<Map<String, String>>> getReleaseBranches({
    required GithubService githubService,
    required gh.RepositorySlug slug,
  }) async {
    final List<gh.Branch> branches = await githubService.github.repositories.listBranches(slug).toList();
    final String latestCandidateBranch = await _getLatestCandidateBranch(
      github: githubService.github,
      slug: slug,
      branches: branches,
    );

    final String betaName = await _getBranchNameFromFile(
      githubService: githubService,
      slug: slug,
      branchName: "beta",
    );
    final String stableName = await _getBranchNameFromFile(
      githubService: githubService,
      slug: slug,
      branchName: "stable",
    );
    return <Map<String, String>>[
      {
        "branch": stableName,
        "name": "stable",
      },
      {
        "branch": betaName,
        "name": "beta",
      },
      {
        "branch": latestCandidateBranch,
        "name": "latestCandidateBranch",
      }
    ];
  }

  Future<String> _getBranchNameFromFile({
    required GithubService githubService,
    required gh.RepositorySlug slug,
    required String branchName,
  }) async {
    return (await githubService.getFileContent(
      slug,
      'bin/internal/release-candidate-branch.version',
      ref: branchName,
    ))
        .trim();
  }

  /// Retrieve the latest canidate branch from all candidate branches.
  Future<String> _getLatestCandidateBranch({
    required gh.GitHub github,
    required gh.RepositorySlug slug,
    required List<gh.Branch> branches,
  }) async {
    final RegExp candidateBranchName = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
    final List<gh.Branch> devBranches = branches.where((gh.Branch b) => candidateBranchName.hasMatch(b.name!)).toList();
    devBranches.sort((b, a) => (_versionSum(a.name!)).compareTo(_versionSum(b.name!)));
    final String devBranchName = devBranches.take(1).single.name!;
    return devBranchName;
  }

  /// Helper function to convert candidate branch versions to numbers for comparison.
  int _versionSum(String tagOrBranchName) {
    final List<String> digits = tagOrBranchName.replaceAll(r'flutter|candidate', '0').split(RegExp(r'\.|\-'));
    int versionSum = 0;
    for (String digit in digits) {
      final int? d = int.tryParse(digit);
      if (d == null) {
        continue;
      }
      versionSum = versionSum * 100 + d;
    }
    return versionSum;
  }
}
