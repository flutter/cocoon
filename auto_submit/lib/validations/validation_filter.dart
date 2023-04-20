import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/validations/approval.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/conflicting.dart';
import 'package:auto_submit/validations/empty_checks.dart';
import 'package:auto_submit/validations/required_check_runs.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/unknown_mergeable.dart';
import 'package:auto_submit/validations/validation.dart';

abstract class ValidationFilter {
  factory ValidationFilter(
      Config config, ProcessMethod processMethod, RepositoryConfiguration repositoryConfiguration) {
    switch (processMethod) {
      case ProcessMethod.processAutosubmit:
        return PullRequestValidationFilter(config, repositoryConfiguration);
      case ProcessMethod.processRevert:
        return RevertRequestValidationFilter(config, repositoryConfiguration);
      default:
        return NoOpValidationFilter(config, repositoryConfiguration);
    }
  }

  Set<Validation> getValidations();
}

class NoOpValidationFilter implements ValidationFilter {
  NoOpValidationFilter(this.config, this.repositoryConfiguration);

  final Config config;
  final RepositoryConfiguration repositoryConfiguration;

  @override
  Set<Validation> getValidations() {
    return {};
  }
}

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
    if (repositoryConfiguration.runCi!) {
      validationsToRun.add(CiSuccessful(config: config));
      validationsToRun.add(EmptyChecks(config: config));
    }

    validationsToRun.add(UnknownMergeable(config: config));
    validationsToRun.add(Conflicting(config: config));

    return validationsToRun;
  }
}

class RevertRequestValidationFilter implements ValidationFilter {
  RevertRequestValidationFilter(this.config, this.repositoryConfiguration);

  final Config config;
  final RepositoryConfiguration repositoryConfiguration;

  @override
  Set<Validation> getValidations() {
    final Set<Validation> validationsToRun = {};

    validationsToRun.add(Revert(config: config));
    // TODO add this back when validations for revert have been refactored.
    // Validate required check runs if they are requested.
    // if (repositoryConfiguration.requiredCheckRunsOnRevert!.isNotEmpty) {
    //   validationsToRun.add(RequiredCheckRuns(config: config));
    // }

    return validationsToRun;
  }
}
