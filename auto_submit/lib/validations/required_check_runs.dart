// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note that we need this file because Github does not expose a field within the
// checks that states whether or not a particular check is required or not.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/exception/retryable_exception.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:retry/retry.dart';

const String ciyamlValidation = 'ci.yaml validation';

/// flutter, engine, cocoon, plugins, packages, buildroot and tests
// const Map<String, List<String>> requiredCheckRunsMapping = {
//   'flutter': [ciyamlValidation],
//   'engine': [ciyamlValidation],
//   'cocoon': [ciyamlValidation],
//   'plugins': [ciyamlValidation],
//   'packages': [ciyamlValidation],
//   'buildroot': [ciyamlValidation],
//   'tests': [ciyamlValidation],
// };

class RequiredCheckRuns {
  const RequiredCheckRuns({
    required this.config,
    RetryOptions? retryOptions,
  }) : retryOptions = retryOptions ?? Config.requiredChecksRetryOptions;

  final Config config;
  final RetryOptions retryOptions;

  Future<bool> waitForRequiredChecks({
    // required GithubService githubService,
    required RepositorySlug slug,
    required String sha,
    // required List<String> checkNames,
  }) async {
    final GithubService githubService = await config.createGithubService(slug);
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    final List<CheckRun> targetCheckRuns = [];
    for (String checkRun in repositoryConfiguration.requiredCheckRuns) {
      targetCheckRuns.addAll(
        await githubService.getCheckRunsFiltered(
          slug: slug,
          ref: sha,
          checkName: checkRun,
        ),
      );
    }

    bool checksCompleted = true;

    try {
      for (CheckRun checkRun in targetCheckRuns) {
        await retryOptions.retry(
          () async {
            await _verifyCheckRunCompleted(
              slug,
              githubService,
              checkRun,
            );
          },
          retryIf: (Exception e) => e is RetryableException,
        );
      }
    } catch (e) {
      log.warning('Required check has not completed in time. ${e.toString()}');
      checksCompleted = false;
    }

    return checksCompleted;
  }
}

/// Function signature that will be executed with retries.
typedef RetryHandler = Function();

/// Simple function to wait on completed checkRuns with retries.
Future<void> _verifyCheckRunCompleted(
  RepositorySlug slug,
  GithubService githubService,
  CheckRun targetCheckRun,
) async {
  final List<CheckRun> checkRuns = await githubService.getCheckRunsFiltered(
    slug: slug,
    ref: targetCheckRun.headSha!,
    checkName: targetCheckRun.name,
  );

  if (checkRuns.first.name != targetCheckRun.name || checkRuns.first.conclusion != CheckRunConclusion.success) {
    throw RetryableException('${targetCheckRun.name} has not yet completed.');
  }
}
