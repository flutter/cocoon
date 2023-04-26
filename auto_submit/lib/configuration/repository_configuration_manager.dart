// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:typed_data';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:mutex/mutex.dart';
import 'package:neat_cache/neat_cache.dart';

class RepositoryConfigurationManager {
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

  RepositoryConfigurationManager(this.config, this.cache);

  /// Read the configuration from the cache given the slug, if the config is not
  /// in the cache then go and get it from the repository and store it in the
  /// cache.
  ///
  /// Entries will be stored in the cache as config/slug/autosubmit.yaml
  Future<RepositoryConfiguration> readRepositoryConfiguration(
    RepositorySlug slug,
  ) async {
    await _mutex.acquire();
    try {
      // Get the contents from the cache or go to github.
      final cacheValue = await cache['${slug.fullName}$fileSeparator$fileName'].get(
        () async => _getConfiguration(slug),
        const Duration(minutes: 10),
      );
      // final String yamlContents = String.fromCharCodes(cacheValue!);
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
    // 1. We need to get the org level configuration
    final RepositorySlug orgSlug = RepositorySlug(slug.owner, orgRepository);
    final GithubService githubService = await config.createGithubService(orgSlug);
    //autosubmit/autosubmit.yml
    final String orgLevelConfig = await githubService.getFileContents(orgSlug, '$dirName$fileSeparator$fileName');
    final RepositoryConfiguration globalRepositoryConfiguration = RepositoryConfiguration.fromYaml(orgLevelConfig);
    
    log.info('Collecting default branch.');
    if (globalRepositoryConfiguration.defaultBranch!.isEmpty) {
      globalRepositoryConfiguration.defaultBranch = await githubService.getDefaultBranch(slug);
    }
    log.info('Default branch was found to be ${globalRepositoryConfiguration.defaultBranch}');

    // This comparision needs to be made since the config override is nullable.
    if (globalRepositoryConfiguration.allowConfigOverride == true) {
      log.info('Override is set, collecting and merging local repository configuration.');
      final GithubService localGithubService = await config.createGithubService(slug);

      String? localRepositoryConfigurationYaml;
      try {
        localRepositoryConfigurationYaml = await localGithubService.getFileContents(slug, '$dirName$fileSeparator$fileName');
        final RepositoryConfiguration localRepositoryConfiguration = RepositoryConfiguration.fromYaml(localRepositoryConfigurationYaml);
        final RepositoryConfiguration mergedRepositoryConfiguration = mergeConfigurations(globalRepositoryConfiguration, localRepositoryConfiguration,);
        return mergedRepositoryConfiguration.toString().codeUnits;
      } on Exception {
        log.warning('Configuration override was set but no local repository configuration file was found in ${slug.fullName}, using global configuration.');
      }
    } else {
      // TODO remove after testing.
      log.info('Override is not allowed for this configuration, skipping local configuration.');
    }

    // 3. Read the default branch of the repository slug that was passed in.
    // TODO: Need to move this above the configuration merge.
    return globalRepositoryConfiguration.toString().codeUnits;
  }

  // TODO: will need to add a merge configurations, need to determine how the
  // override will happen.

  // The override configuration will allow override of certain non array values.
  // Array values will be additive in that any value supplied in an overridden
  // configuration will added to the main org config.

  RepositoryConfiguration mergeConfigurations(
    RepositoryConfiguration globalConfiguration,
    RepositoryConfiguration localConfiguration,
  ) {
    // TODO migth be worth while to make a copy constructor for this.
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
    if (localConfiguration.autoApprovalAccounts != null && localConfiguration.autoApprovalAccounts!.isNotEmpty) {
      mergedRepositoryConfiguration.autoApprovalAccounts!.addAll(localConfiguration.autoApprovalAccounts!);
    }

    // approving reviews
    // this may not be set lower than the global configuration value
    final int? localApprovingReviews = localConfiguration.approvingReviews;
    if (localApprovingReviews != null && localApprovingReviews > globalConfiguration.approvingReviews!) {
      mergedRepositoryConfiguration.approvingReviews = localApprovingReviews;
    }

    // approval group
    final String? localApprovalGroup = localConfiguration.approvalGroup;
    if (localApprovalGroup != null && localApprovalGroup.isNotEmpty) {
      mergedRepositoryConfiguration.approvalGroup = localApprovalGroup;
    }

    // run ci
    // validates the checks runs
    final bool? localRunCi = localConfiguration.runCi;
    if (localRunCi != null && globalConfiguration.runCi != localRunCi) {
      mergedRepositoryConfiguration.runCi = localRunCi;
    }

    // support no revert reviews - this will be a moot point after revert is updated
    final bool? localSupportNoReviewReverts = localConfiguration.supportNoReviewReverts;
    if (localSupportNoReviewReverts != null &&
        localSupportNoReviewReverts != globalConfiguration.supportNoReviewReverts) {
      mergedRepositoryConfiguration.supportNoReviewReverts = localSupportNoReviewReverts;
    }

    // required checkruns on revert, they should be empty if nothing was defined
    mergedRepositoryConfiguration.requiredCheckRunsOnRevert = globalConfiguration.requiredCheckRunsOnRevert;
    if (localConfiguration.requiredCheckRunsOnRevert != null &&
        localConfiguration.requiredCheckRunsOnRevert!.isNotEmpty) {
      mergedRepositoryConfiguration.requiredCheckRunsOnRevert!.addAll(localConfiguration.requiredCheckRunsOnRevert!);
    }

    return mergedRepositoryConfiguration;
  }
}
