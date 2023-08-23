import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/mergeable.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

class FakeMergeable extends Mergeable {
  FakeMergeable({required super.config});

  ValidationResult? validationResult;

  @override
  String get name => 'FakeMergeable';

  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    return validationResult ?? ValidationResult(true, Action.REMOVE_LABEL, '');
  }
}
