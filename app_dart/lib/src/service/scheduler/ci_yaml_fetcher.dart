// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:path/path.dart' as p;
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

import '../../../ci_yaml.dart';
import '../../../protos.dart' as pb;
import '../../foundation/providers.dart';
import '../../foundation/typedefs.dart';
import '../../foundation/utils.dart';
import '../../model/commit_ref.dart';
import '../cache_service.dart';
import '../config.dart';
import '../firestore.dart';

/// Fetches a [CiYamlSet] given the current repository and commit context.
interface class CiYamlFetcher {
  /// Creates a [CiYamlFetcher] from the provided configuration.
  CiYamlFetcher({
    required CacheService cache,
    required FirestoreService firestore,
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
    Duration cacheTtl = const Duration(hours: 1),
    String subcacheName = 'scheduler',
    RetryOptions retryOptions = const RetryOptions(
      delayFactor: Duration(seconds: 2),
      maxAttempts: 4,
    ),
  }) : _cache = cache,
       _cacheTtl = cacheTtl,
       _subcacheName = subcacheName,
       _retryOptions = retryOptions,
       _httpClientProvider = httpClientProvider,
       _firestore = firestore;

  final CacheService _cache;
  final String _subcacheName;
  final Duration _cacheTtl;
  final RetryOptions _retryOptions;
  final HttpClientProvider _httpClientProvider;
  final FirestoreService _firestore;

  /// Fetches and processes (as appropriate) the `.ci.yaml`(s) for a [commit].
  ///
  /// If [validate] is omitted, it defaults to whether [CommitRef.branch] is the
  /// default branch for [CommitRef.slug].
  ///
  /// If [postsubmit] is `true`, will fall back to trying to use Git-on-Borg
  /// (the mirror of GitHub).
  Future<CiYamlSet> getCiYamlByCommit(
    CommitRef commit, {
    bool? validate,
    bool postsubmit = false,
  }) async {
    validate ??= commit.branch == Config.defaultBranch(commit.slug);
    final isFusion = commit.slug == Config.flutterSlug;
    final totCommit = await _fetchTipOfTreeCommit(slug: commit.slug);
    final totYaml = await _getCiYaml(
      commit: totCommit,
      validate: validate,
      isFusionCommit: isFusion,
      useGitOnBorgFallback: true,
    );
    return _getCiYaml(
      commit: commit,
      validate: validate,
      totCiYaml: totYaml,
      isFusionCommit: isFusion,
      useGitOnBorgFallback: postsubmit,
    );
  }

  /// Creates and returns, using a cache, the `.ci.yaml` file for a commit.
  Future<CiYamlSet> _getCiYaml({
    required CommitRef commit,
    required bool validate,
    required bool useGitOnBorgFallback,
    CiYamlSet? totCiYaml,
    bool isFusionCommit = false,
  }) async {
    // Fetch the root .ci.yaml.
    final rootConfig = await _getOrFetchCiYaml(
      commit: commit,
      ciYamlPath: kCiYamlPath,
      useGitOnBorgFallback: useGitOnBorgFallback,
    );

    // And, if in a Fusion repository, the engine .ci.yaml.
    final pb.SchedulerConfig? engineConfig;
    if (isFusionCommit) {
      engineConfig = await _getOrFetchCiYaml(
        commit: commit,
        ciYamlPath: kCiYamlFusionEnginePath,
        useGitOnBorgFallback: useGitOnBorgFallback,
      );
    } else {
      engineConfig = null;
    }

    // If totCiYaml is not null, we assume the caller has verified that the
    // current branch is not a release branch.
    return CiYamlSet(
      yamls: {
        CiType.any: rootConfig,
        if (engineConfig != null) CiType.fusionEngine: engineConfig,
      },
      slug: commit.slug,
      branch: commit.branch,
      totConfig: totCiYaml,
      validate: validate,
    );
  }

  /// Fetches a [ciYamlPath] from cache, or downloads it if missing.
  Future<pb.SchedulerConfig> _getOrFetchCiYaml({
    required CommitRef commit,
    required String ciYamlPath,
    required bool useGitOnBorgFallback,
  }) async {
    final ciYamlBytes = await _cache.getOrCreate(
      _subcacheName,
      p.join(commit.slug.fullName, commit.sha, ciYamlPath),
      createFn: () async {
        return (await _downloadCiYaml(
          slug: commit.slug,
          commitSha: commit.sha,
          ciYamlPath: ciYamlPath,
          useGitOnBorgFallback: useGitOnBorgFallback,
        )).writeToBuffer();
      },
      ttl: _cacheTtl,
    );
    return pb.SchedulerConfig.fromBuffer(ciYamlBytes!);
  }

  /// Downloads the specified [ciYamlPath] file from [slug] and [commitSha].
  Future<pb.SchedulerConfig> _downloadCiYaml({
    required RepositorySlug slug,
    required String commitSha,
    required String ciYamlPath,
    required bool useGitOnBorgFallback,
  }) async {
    final content = await githubFileContent(
      slug,
      ciYamlPath,
      ref: commitSha,
      httpClientProvider: _httpClientProvider,
      retryOptions: _retryOptions,
      useGitOnBorgFallback: useGitOnBorgFallback,
    );
    return pb.SchedulerConfig()..mergeFromProto3Json(loadYaml(content));
  }

  /// Fetches the latest (tip-of-tree) commit for [slug] and [commitBranch].
  ///
  /// A tip of tree commit is used to help generate the tip of tree [CiYamlSet],
  /// where it is compared against presubmit targets to ensure new targets
  /// (without `bringup: true`) are not added to the build, as well that targets
  /// that no longer exist at tip of tree do not run on older branches (such as
  /// release candidates).
  Future<CommitRef> _fetchTipOfTreeCommit({
    required RepositorySlug slug,
  }) async {
    final recentCommits = await _firestore.queryRecentCommits(
      slug: slug,
      branch: Config.defaultBranch(slug),
      limit: 1,
    );
    if (recentCommits.length != 1) {
      throw StateError('Expected a single commit, got ${recentCommits.length}');
    }
    return recentCommits.first.toRef();
  }
}
