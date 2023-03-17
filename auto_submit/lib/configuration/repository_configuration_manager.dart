// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'dart:typed_data';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:neat_cache/neat_cache.dart';

class RepositoryConfigurationManager {
  // repository manager needs a cache and a github service in order to provide the configuration
  // It only provides the configuration read from either the cache or github.

  static const String fileSeparator = '/';
  static const String rootDir = '.github';
  static const String fileName = 'autosubmit.yaml';

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
    // Get the contents from the cache or go to github.
    final cacheValue = await cache['${slug.fullName}$fileSeparator$fileName'].get(
      () async => _getConfiguration(
        githubService,
        slug,
      ),
      const Duration(minutes: 2),
    );
    // final String yamlContents = String.fromCharCodes(cacheValue!);
    final String cacheYaml = String.fromCharCodes(cacheValue);
    log.info('Converting yaml to RepositoryConfiguration: $cacheYaml');
    return RepositoryConfiguration.fromYaml(cacheYaml);
  }

  /// Collect the configuration from github and handle the cache conversion to
  /// bytes.
  Future<List<int>> _getConfiguration(
    GithubService githubService,
    RepositorySlug slug,
  ) async {
    log.info('Getting config from github for ${slug.fullName}');
    final String fileContents = await githubService.getFileContents(
      slug,
      '$rootDir$fileSeparator$fileName',
    );
    return fileContents.codeUnits;
  }
}
