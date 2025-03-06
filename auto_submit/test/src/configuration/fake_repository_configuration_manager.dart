// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_manager.dart';
import 'package:auto_submit/service/config.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:neat_cache/neat_cache.dart';

class FakeRepositoryConfigurationManager
    implements RepositoryConfigurationManager {
  FakeRepositoryConfigurationManager(this.config, this.cache);

  String? yamlConfig;

  @override
  final Cache cache;

  @override
  final Config config;

  late RepositoryConfiguration? repositoryConfigurationMock;

  late RepositoryConfiguration? mergedRepositoryConfigurationMock;

  @override
  Future<RepositoryConfiguration> readRepositoryConfiguration(
    RepositorySlug slug,
  ) async {
    return repositoryConfigurationMock!;
  }

  @override
  RepositoryConfiguration mergeConfigurations(
    RepositoryConfiguration globalConfiguration,
    RepositoryConfiguration localConfiguration,
  ) {
    return mergedRepositoryConfigurationMock!;
  }
}
