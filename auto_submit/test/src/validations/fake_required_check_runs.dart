import 'package:auto_submit/validations/required_check_runs.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;
import 'package:github/github.dart' as github;

class FakeRequiredCheckRuns extends RequiredCheckRuns {
  FakeRequiredCheckRuns({required super.config});
  
  bool isSuccessful = true;

  @override
  Future<ValidationResult> validate(auto.QueryResult result, github.PullRequest messagePullRequest) async => ValidationResult(
      isSuccessful,
      isSuccessful ? Action.REMOVE_LABEL : Action.IGNORE_TEMPORARILY,
      isSuccessful ? 'All required check runs have completed.' : 'Some of the required checks did not complete in time.',
    );
}