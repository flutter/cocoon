// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/validations/approval.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/empty_checks.dart';
import 'package:auto_submit/validations/mergeable.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/validation.dart';

/// The [ValidationFilter] allows us to pick and choose and the validations to
/// run on a particular type of pull request.
abstract class ValidationFilter {
  factory ValidationFilter(
    Config config,
    ProcessMethod processMethod,
    RepositoryConfiguration repositoryConfiguration,
  ) {
    switch (processMethod) {
      case ProcessMethod.processAutosubmit:
        return PullRequestValidationFilter(config, repositoryConfiguration);
      case ProcessMethod.processRevert:
        return RevertRequestValidationFilter(config, repositoryConfiguration);
      default:
        throw 'No such processMethod enum value';
    }
  }

  Set<Validation> getValidations();
}

/// [PullRequestValidationFilter] returns a Set of validations that we run on
/// all non revert pull requests that will be merged into the mainline branch.
class PullRequestValidationFilter implements ValidationFilter {
  PullRequestValidationFilter(this.config, this.repositoryConfiguration);

  final Config config;
  final RepositoryConfiguration repositoryConfiguration;

  @override
  Set<Validation> getValidations() {
    final Set<Validation> validationsToRun = {};

    validationsToRun.add(Approval(config: config));

    // If we are running ci then we need to check the checkRuns and make sure
    // there are check runs created.
    if (repositoryConfiguration.runCi) {
      validationsToRun.add(CiSuccessful(config: config));
      validationsToRun.add(EmptyChecks(config: config));
    }

    validationsToRun.add(Mergeable(config: config));

    return validationsToRun;
  }
}

/// [RevertRequestValidationFilter] returns a Set of validations that we run on
/// all revert pull requests.
class RevertRequestValidationFilter implements ValidationFilter {
  RevertRequestValidationFilter(this.config, this.repositoryConfiguration);

  final Config config;
  final RepositoryConfiguration repositoryConfiguration;

  @override
  Set<Validation> getValidations() {
    final Set<Validation> validationsToRun = {};

    validationsToRun.add(Revert(config: config));

    return validationsToRun;
  }
}
