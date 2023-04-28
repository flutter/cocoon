// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:mutex/mutex.dart';
import 'package:neat_cache/neat_cache.dart';

/// The [RepositoryConfigurationManager] is responsible for fetching and merging
/// the autosubmit configuration from the Org level repository and if needed
/// fetching the override configuration from the pull request repository.
///
/// It will attempt to access the cache first before repulling the configuraiton
/// from the repositories. This is currently set at a 10 minute TTL.
class RepositoryConfigurationManager {

  RepositoryConfigurationManager(this.config, this.cache);

  // Mutex protects the calls to cache while the [RepositoryConfiguration] is
  // collected from github.
  final Mutex _mutex = Mutex();

  static const String fileSeparator = '/';
  // This is the well named organization level repository and configuration file
  // we will read before looking to see if there is a local file with
  // overwrites.
  static const String orgRepository = '.github';
  static const String dirName = 'autosubmit';
  static const String fileName = 'autosubmit.yml';

  final Config config;
  final Cache cache;

  /// Read the configuration from the cache given the slug, if the config is not
  /// in the cache then go and get it from the repository and store it in the
  /// cache.
  Future<RepositoryConfiguration> readRepositoryConfiguration(
    RepositorySlug slug,
  ) async {
    await _mutex.acquire();
    try {
      // Get the contents from the cache or go to github.
      final cacheValue = await cache['${slug.fullName}$fileSeparator$fileName'].get(
        () async => _getConfiguration(slug),
        config.repositoryConfigurationTtl,
      );
      final String cacheYaml = String.fromCharCodes(cacheValue);
      log.info('Converting yaml to RepositoryConfiguration: $cacheYaml');
      return RepositoryConfiguration.fromYaml(cacheYaml);
    } finally {
      _mutex.release();
    }
  }

  /// Collect the configuration from github and handle the cache conversion to
  /// bytes.
  Future<List<int>> _getConfiguration(
    RepositorySlug slug,
  ) async {
    // Read the org level configuraiton file first.
    log.info('Getting org level configuration.');
    // Get the Org level configuration.
    final RepositorySlug orgSlug = RepositorySlug(slug.owner, orgRepository);
    GithubService githubService = await config.createGithubService(orgSlug);
    final String orgLevelConfig = await githubService.getFileContents(orgSlug, '$dirName$fileSeparator$fileName');
    final RepositoryConfiguration globalRepositoryConfiguration = RepositoryConfiguration.fromYaml(orgLevelConfig);

    // Collect the default branch if it was not supplied.
    if (globalRepositoryConfiguration.defaultBranch.isEmpty) {
      globalRepositoryConfiguration.defaultBranch = await githubService.getDefaultBranch(slug);
    }
    log.info('Default branch was found to be ${globalRepositoryConfiguration.defaultBranch} for ${slug.fullName}.');

    // If the override flag is set to true we check the pull request's
    // repository to collect any values that will override the global config.
    if (globalRepositoryConfiguration.allowConfigOverride) {
      log.info('Override is set, collecting and merging local repository configuration.');
      githubService = await config.createGithubService(slug);

      String? localRepositoryConfigurationYaml;
      try {
        localRepositoryConfigurationYaml =
            await githubService.getFileContents(slug, '$dirName$fileSeparator$fileName');
        final RepositoryConfiguration localRepositoryConfiguration =
            RepositoryConfiguration.fromYaml(localRepositoryConfigurationYaml);
        final RepositoryConfiguration mergedRepositoryConfiguration = mergeConfigurations(
          globalRepositoryConfiguration,
          localRepositoryConfiguration,
        );
        return mergedRepositoryConfiguration.toString().codeUnits;
      } on GitHubError {
        log.warning(
          'Configuration override was set but no local repository configuration file was found in ${slug.fullName}, using global configuration.',
        );
      }
    }

    return globalRepositoryConfiguration.toString().codeUnits;
  }

  /// Merge the local [RepositoryConfiguration] with the global
  /// [RepositoryConfiguration].
  ///
  /// Values that are lists are additive. Values that are not lists overwrite
  /// the value in the global configuration.
  ///
  /// The number of approving reviews in the local configuration cannot override
  /// the global configuration if it is a lower value.
  ///
  /// We also do not need to allow the default branch override as it is
  /// collected from the repository directly.
  RepositoryConfiguration mergeConfigurations(
    RepositoryConfiguration globalConfiguration,
    RepositoryConfiguration localConfiguration,
  ) {
    final RepositoryConfiguration mergedRepositoryConfiguration = RepositoryConfiguration(
      allowConfigOverride: globalConfiguration.allowConfigOverride,
      defaultBranch: globalConfiguration.defaultBranch,
      autoApprovalAccounts: globalConfiguration.autoApprovalAccounts,
      approvingReviews: globalConfiguration.approvingReviews,
      approvalGroup: globalConfiguration.approvalGroup,
      runCi: globalConfiguration.runCi,
      supportNoReviewReverts: globalConfiguration.supportNoReviewReverts,
      requiredCheckRunsOnRevert: globalConfiguration.requiredCheckRunsOnRevert,
    );

    // auto approval accounts, they should be empty if nothing was defined
    mergedRepositoryConfiguration.autoApprovalAccounts = globalConfiguration.autoApprovalAccounts;
    if (localConfiguration.autoApprovalAccounts.isNotEmpty) {
      mergedRepositoryConfiguration.autoApprovalAccounts.addAll(localConfiguration.autoApprovalAccounts);
    }

    // approving reviews
    // this may not be set lower than the global configuration value
    final int localApprovingReviews = localConfiguration.approvingReviews;
    if (localApprovingReviews > globalConfiguration.approvingReviews) {
      mergedRepositoryConfiguration.approvingReviews = localApprovingReviews;
    }

    // approval group
    final String localApprovalGroup = localConfiguration.approvalGroup;
    if (localApprovalGroup.isNotEmpty) {
      mergedRepositoryConfiguration.approvalGroup = localApprovalGroup;
    }

    // run ci
    // validates the checks runs
    final bool localRunCi = localConfiguration.runCi;
    if (globalConfiguration.runCi != localRunCi) {
      mergedRepositoryConfiguration.runCi = localRunCi;
    }

    // support no revert reviews - this will be a moot point after revert is updated
    final bool localSupportNoReviewReverts = localConfiguration.supportNoReviewReverts;
    if (localSupportNoReviewReverts != globalConfiguration.supportNoReviewReverts) {
      mergedRepositoryConfiguration.supportNoReviewReverts = localSupportNoReviewReverts;
    }

    // required checkruns on revert, they should be empty if nothing was defined
    mergedRepositoryConfiguration.requiredCheckRunsOnRevert = globalConfiguration.requiredCheckRunsOnRevert;
    if (localConfiguration.requiredCheckRunsOnRevert.isNotEmpty) {
      mergedRepositoryConfiguration.requiredCheckRunsOnRevert.addAll(localConfiguration.requiredCheckRunsOnRevert);
    }

    return mergedRepositoryConfiguration;
  }
}
