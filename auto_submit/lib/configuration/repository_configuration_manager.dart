// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:typed_data';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
// import 'package:mutex/mutex.dart';
import 'package:neat_cache/neat_cache.dart';

class RepositoryConfigurationManager {
  // final Mutex _mutex = Mutex();

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
    // Get the contents from the cache or go to github.
    final cacheValue = await cache['${slug.fullName}$fileSeparator$fileName'].get(
      () async => _getConfiguration(slug),
      const Duration(minutes: 10),
    );
    // final String yamlContents = String.fromCharCodes(cacheValue!);
    final String cacheYaml = String.fromCharCodes(cacheValue);
    log.info('Converting yaml to RepositoryConfiguration: $cacheYaml');
    return RepositoryConfiguration.fromYaml(cacheYaml);
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
    final RepositoryConfiguration repositoryConfiguration = RepositoryConfiguration.fromYaml(orgLevelConfig);

    // TODO: ignore this for now
    // 2. if it has the override configuration flag and it is true we need to
    // read the local configuraiton file.
    // final GithubService localGithubService = await config.createGithubService(slug);
    // final String localRepositoryConfigurationStr = await localGithubService.getFileContents(slug, '$dirName$fileSeparator$fileName');
    // final RepositoryConfiguration localRepositoryConfiguration = RepositoryConfiguration.fromYaml(localRepositoryConfigurationStr);
    
    // This comparision needs to be made since the config override is nullable.
    if (repositoryConfiguration.allowConfigOverride == true) {
      log.info('Override is set, collecting and merging local repository configuration.');
    } else {
      // TODO remove after testing.
      log.info('Overrid is not allowed for this configuration, skipping local configuration.');
    }

    // 3. Read the default branch of the repository slug that was passed in.
    log.info('Collecting default branch.');
    if (repositoryConfiguration.defaultBranch!.isEmpty) { 
      repositoryConfiguration.defaultBranch = await githubService.getDefaultBranch(slug);
    }
    
    log.info('Default branch was found to be ${repositoryConfiguration.defaultBranch}');
    return repositoryConfiguration.toString().codeUnits;
  }

  // TODO: will need to add a merge configurations, need to determine how the
  // override will happen.

  // The override configuration will allow override of certain non array values.
  // Array values will be additive in that any value supplied in an overridden 
  // configuration will added to the main org config.
}
