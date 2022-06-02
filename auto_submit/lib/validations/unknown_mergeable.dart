import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';

class UnknownMergeable extends Validation {
  UnknownMergeable({
    required Config config,
  }) : super(config: config);

  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    // This is used to skip landing until we are sure the PR is mergeable.
    final bool unknownMergeableState = messagePullRequest.mergeableState == 'UNKNOWN';
    return ValidationResult(!unknownMergeableState, Action.IGNORE_TEMPORARILY, '');
  }
}
