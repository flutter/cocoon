// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:typed_data';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_pointer.dart';
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
  static const String rootDir = '.github';
  static const String fileName = 'autosubmit.yml';

  final Cache cache;

  RepositoryConfigurationManager(this.cache);

  /// Read the configuration from the cache given the slug, if the config is not
  /// in the cache then go and get it from the repository and store it in the
  /// cache.
  ///
  /// Entries will be stored in the cache as config/slug/autosubmit.yaml
  Future<RepositoryConfiguration> readRepositoryConfiguration(
    GithubService githubService,
    RepositorySlug slug,
  ) async {
    await _mutex.acquire();
    try {
      // Get the contents from the cache or go to github.
      final cacheValue = await cache['${slug.fullName}$fileSeparator$fileName'].get(
        () async => _getConfiguration(
          githubService,
          slug,
        ),
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
    GithubService githubService,
    RepositorySlug slug,
  ) async {
    // Read the org level configuraiton file first.
    log.info('Getting org level configuration.');
    // This looks like org/.github, ex flutter/.github
    // RepositorySlug orgSlug = RepositorySlug(slug.owner, rootDir);
    // final String orgLevelConfig = await githubService.getFileContents(slug, path)









    // Read the local config file for the pointer
    log.info('Getting local file contents from $slug.');
    final String localPointerFileContents = await githubService.getFileContents(
      slug,
      '$rootDir$fileSeparator$fileName',
    );
    log.info('local pointer file contents: $localPointerFileContents');
    final RepositoryConfigurationPointer configPointer =
        RepositoryConfigurationPointer.fromYaml(localPointerFileContents);

    log.info('Getting config from github for: ${slug.fullName}');
    final String fileContents = await githubService.getFileContents(
      githubRepo,
      configPointer.filePath,
    );
    log.info('.github file contents: $fileContents');
    return fileContents.codeUnits;
  }
}
