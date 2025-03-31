// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

import '../../../ci_yaml.dart';
import '../../../protos.dart' as pb;
import '../../foundation/providers.dart';
import '../../foundation/typedefs.dart';
import '../../foundation/utils.dart';
import '../../model/appengine/commit.dart' as datastore;
import '../../model/firestore/commit.dart' as firestore;
import '../cache_service.dart';
import '../config.dart';

/// Fetches a [CiYamlSet] given the current repository and commit context.
abstract base class CiYamlFetcher {
  /// Creates a [CiYamlFetcher] from the provided configuration.
  factory CiYamlFetcher({
    required CacheService cache,
    required Config config,
    HttpClientProvider httpClientProvider,
    Duration cacheTtl,
    String subcacheName,
    RetryOptions retryOptions,
  }) = _CiYamlFetcher;

  /// Exists so that a fake implementation can re-use `getCiYamlBy*` methods.
  @visibleForTesting
  CiYamlFetcher.forTesting();

  /// Fetches and processes (as appropriate) the `.ci.yaml`(s) for [commit].
  ///
  /// This is a helper method for [getCiYaml] for use with [datastore.Commit].
  Future<CiYamlSet> getCiYamlByDatastoreCommit(
    datastore.Commit commit, {
    bool validate = false,
  }) async {
    return getCiYaml(
      slug: commit.slug,
      commitSha: commit.sha!,
      commitBranch: commit.branch!,
      validate: validate,
    );
  }

  /// Fetches and processes (as appropriate) the `.ci.yaml`(s) for [commit].
  ///
  /// This is a helper method for [getCiYaml] for use with [firestore.Commit].
  Future<CiYamlSet> getCiYamlByFirestoreCommit(
    firestore.Commit commit, {
    bool validate = false,
  }) async {
    return getCiYaml(
      slug: commit.slug,
      commitSha: commit.sha,
      commitBranch: commit.branch,
      validate: validate,
    );
  }

  /// Fetches and processes (as appropriate) the `.ci.yaml`(s) for a commit.
  Future<CiYamlSet> getCiYaml({
    required RepositorySlug slug,
    required String commitSha,
    required String commitBranch,
    bool validate = false,
  });
}

final class _CiYamlFetcher extends CiYamlFetcher {
  _CiYamlFetcher({
    required CacheService cache,
    required Config config,
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
       _config = config,
       _retryOptions = retryOptions,
       _httpClientProvider = httpClientProvider,
       super.forTesting();

  final CacheService _cache;
  final String _subcacheName;
  final Duration _cacheTtl;
  final RetryOptions _retryOptions;
  final Config _config;
  final HttpClientProvider _httpClientProvider;

  @override
  Future<CiYamlSet> getCiYaml({
    required RepositorySlug slug,
    required String commitSha,
    required String commitBranch,
    bool validate = false,
  }) async {
    final isFusion = slug == Config.flutterSlug;
    final totCommit = await _fetchTipOfTreeCommit(slug: slug);
    final totYaml = await _getCiYaml(
      slug: totCommit.slug,
      commitSha: totCommit.sha,
      commitBranch: totCommit.branch,
      validate: validate,
      isFusionCommit: isFusion,
    );
    return _getCiYaml(
      totCiYaml: totYaml,
      slug: slug,
      commitSha: commitSha,
      commitBranch: commitBranch,
      isFusionCommit: isFusion,
      validate: validate,
    );
  }

  /// Creates and returns, using a cache, the `.ci.yaml` file for a commit.
  Future<CiYamlSet> _getCiYaml({
    required RepositorySlug slug,
    required String commitSha,
    required String commitBranch,
    required bool validate,
    CiYamlSet? totCiYaml,
    bool isFusionCommit = false,
  }) async {
    // Fetch the root .ci.yaml.
    final rootConfig = await _getOrFetchCiYaml(
      slug: slug,
      commitSha: commitSha,
      ciYamlPath: kCiYamlPath,
    );

    // And, if in a Fusion repository, the engine .ci.yaml.
    final pb.SchedulerConfig? engineConfig;
    if (isFusionCommit) {
      engineConfig = await _getOrFetchCiYaml(
        slug: slug,
        commitSha: commitSha,
        ciYamlPath: kCiYamlFusionEnginePath,
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
      slug: slug,
      branch: commitBranch,
      totConfig: totCiYaml,
      validate: validate,
      isFusion: isFusionCommit,
    );
  }

  /// Fetches a [ciYamlPath] from cache, or downloads it if missing.
  Future<pb.SchedulerConfig> _getOrFetchCiYaml({
    required RepositorySlug slug,
    required String commitSha,
    required String ciYamlPath,
  }) async {
    final ciYamlBytes = await _cache.getOrCreate(
      _subcacheName,
      p.join(slug.fullName, commitSha, ciYamlPath),
      createFn: () async {
        return (await _downloadCiYaml(
          slug: slug,
          commitSha: commitSha,
          ciYamlPath: ciYamlPath,
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
  }) async {
    final content = await githubFileContent(
      slug,
      ciYamlPath,
      ref: commitSha,
      httpClientProvider: _httpClientProvider,
      retryOptions: _retryOptions,
    );
    return pb.SchedulerConfig()..mergeFromProto3Json(loadYaml(content));
  }

  /// Fetches the latest (tip-of-tree) commit for [slug] and [commitBranch].
  ///
  /// A tip of tree commit is used to help generate the tip of tree [CiYamlSet],
  /// where it is compared against presubmit targets to ensure new targets
  /// (without `bringup: true`) are not added to the build.
  Future<firestore.Commit> _fetchTipOfTreeCommit({
    required RepositorySlug slug,
  }) async {
    final firestore = await _config.createFirestoreService();
    final recentCommits = await firestore.queryRecentCommits(
      slug: slug,
      branch: Config.defaultBranch(slug),
      limit: 1,
    );
    if (recentCommits.length != 1) {
      throw StateError('Expected a single commit, got ${recentCommits.length}');
    }
    return recentCommits.first;
  }
}
