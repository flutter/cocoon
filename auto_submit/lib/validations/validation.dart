import 'package:auto_submit/model/auto_submit_query_result.dart';

import '../service/config.dart';
import 'package:github/github.dart' as github;

abstract class Validation {
  const Validation({required this.config});

  final Config config;

  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest);
}

enum Action {
  REMOVE_LABEL,
  IGNORE_FAILURE,
  IGNORE_TEMPORARILY,
}

class ValidationResult {
  ValidationResult(this.result, this.action, this.message);
  bool result;
  Action action;
  String message;
}

class FailureDetail {
  const FailureDetail(this.name, this.url);

  final String name;
  final String url;

  String get markdownLink => '[$name]($url)';

  @override
  int get hashCode => 17 * 31 + name.hashCode * 31 + url.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FailureDetail && other.name == name && other.url == url;
  }
}
