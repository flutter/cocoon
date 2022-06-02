import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';

class Conflicting extends Validation {
  Conflicting({
    required Config config,
  }) : super(config: config);

  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    // This is used to remove the bot label as it requires manual intervention.
    bool result = !(messagePullRequest.mergeable == false);
    String message = '- This commit is not mergeable and has conflicts. Please'
        ' rebase your PR and fix all the conflicts.';
    return ValidationResult(result, Action.REMOVE_LABEL, message);
  }
}
