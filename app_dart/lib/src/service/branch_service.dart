// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as gh;
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../request_handling/exceptions.dart';
import 'config.dart';
import 'gerrit_service.dart';

part 'branch_service.g.dart';

/// Manages, synchronizes, and associates GitHub branches with branch candidate versions.
interface class BranchService {
  /// Create a new [BranchService]
  BranchService({
    required Config config,
    required GerritService gerritService,
    RetryOptions retryOptions = const RetryOptions(maxAttempts: 3),
  }) : _retryOptions = retryOptions,
       _gerritService = gerritService,
       _config = config;

  final Config _config;
  final GerritService _gerritService;
  final RetryOptions _retryOptions;

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
    final recipesSlug = gh.RepositorySlug('flutter', 'recipes');
    if ((await _gerritService.branches(
      '${recipesSlug.owner}-review.googlesource.com',
      recipesSlug.name,
      filterRegex: branch,
    )).contains(branch)) {
      // subString is a regex, and can return multiple matches
      log2.warn('$branch already exists for $recipesSlug');
      throw BadRequestException('$branch already exists');
    }
    final recipeCommits = await _gerritService.commits(
      recipesSlug,
      Config.defaultBranch(recipesSlug),
    );
    log2.info('$recipesSlug commits: $recipeCommits');
    final engineCommit = await _retryOptions.retry(() async {
      // This attempts to regenerate the OAuth token, which is why it isn't stored as a dependency.
      final githubService = await _config.createDefaultGitHubService();
      return githubService.github.repositories.getCommit(
        Config.flutterSlug,
        engineSha,
      );
    }, retryIf: (Exception e) => e is gh.GitHubError);
    log2.info('${Config.flutterSlug} commit: $engineCommit');
    final branchTime = engineCommit.commit?.committer?.date;
    if (branchTime == null) {
      throw BadRequestException('$engineSha has no commit time');
    }
    log2.info('Searching for a recipe commit before $branchTime');
    for (var recipeCommit in recipeCommits) {
      final recipeTime = recipeCommit.author?.time;

      if (recipeTime != null && recipeTime.isBefore(branchTime)) {
        final revision = recipeCommit.commit!;
        return _gerritService.createBranch(recipesSlug, branch, revision);
      }
    }

    throw InternalServerError(
      'Failed to find a revision to flutter/recipes for $branch before $branchTime',
    );
  }

  /// Returns a Map that contains the latest google3 roll, beta, and stable branches.
  ///
  /// Latest beta and stable branches are retrieved based on 'beta' and 'stable' tags. Dev branch is retrived
  /// as the latest flutter candidate branch.
  Future<List<ReleaseBranch>> getReleaseBranches({
    required gh.RepositorySlug slug,
  }) async {
    final results = [
      // Always include master -> HEAD.
      ReleaseBranch(channel: Config.defaultBranch(slug), reference: 'master'),
    ];

    // And then for each of these channels, lookup
    for (final channel in _config.releaseBranches) {
      final reference = await _getBranchReferenceForChannel(
        slug: slug,
        branchName: channel,
      );
      if (reference == null) {
        log2.warn('Could not resolve release branch for "$channel"');
        continue;
      }
      results.add(ReleaseBranch(channel: channel, reference: reference));
    }

    return results;
  }

  /// Given [slug] and [branchName], returns the value of `bin/internal/release-candidate-branch.version`, if any.
  ///
  /// If the file or branch could not be found, returns `null`.
  Future<String?> _getBranchReferenceForChannel({
    required gh.RepositorySlug slug,
    required String branchName,
  }) async {
    try {
      // This attempts to regenerate the OAuth token, which is why it isn't stored as a dependency.
      final githubService = await _config.createDefaultGitHubService();
      final content = await githubService.getFileContent(
        slug,
        _config.releaseCandidateBranchPath,
        ref: branchName,
      );
      return content.trim();
    } catch (e, s) {
      log2.error('Could not fetch release version file', e, s);
      return null;
    }
  }
}

/// Represents a branch that is synced for flutter/flutter.
@JsonSerializable(checked: true)
@immutable
final class ReleaseBranch {
  /// Creates a release branch association between [channel] and [reference].
  const ReleaseBranch({required this.channel, required this.reference});

  /// Creates a release branch from the inverse of the [toJson] method.
  factory ReleaseBranch.fromJson(Map<String, Object?> json) {
    try {
      return _$ReleaseBranchFromJson(json);
    } on CheckedFromJsonException catch (e) {
      throw FormatException('$e', json);
    }
  }

  /// Name of the release channel, such as `master`, `stable`, `beta`, or `staging`.
  ///
  /// Note that `staging` is intended as a non user-visible channel for team development.
  @JsonKey(name: 'channel')
  final String channel;

  /// The git reference, on `flutter/flutter`, that [channel] ias assocaited with.
  @JsonKey(name: 'reference')
  final String reference;

  @override
  bool operator ==(Object other) {
    return other is ReleaseBranch &&
        channel == other.channel &&
        reference == other.reference;
  }

  @override
  int get hashCode => Object.hash(channel, reference);

  /// Returns a JSON object representation of `this`.
  Map<String, Object?> toJson() => _$ReleaseBranchToJson(this);

  @override
  String toString() =>
      'ReleaseBranch ${const JsonEncoder.withIndent('  ').convert(toJson())}';
}
