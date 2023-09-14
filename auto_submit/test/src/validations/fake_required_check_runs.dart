import 'package:auto_submit/validations/required_check_runs.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;

import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

class FakeRequiredCheckRuns extends RequiredCheckRuns {
  FakeRequiredCheckRuns({required super.config});

  ValidationResult? validationResult;

  @override
  String get name => 'FakeRequiredCheckRuns';

  @override
  Future<ValidationResult> validate(auto.QueryResult result, github.PullRequest messagePullRequest) async {
    return validationResult ?? ValidationResult(true, Action.REMOVE_LABEL, '');
  }
}
