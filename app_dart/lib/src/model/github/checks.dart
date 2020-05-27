import 'package:github/github.dart' hide CheckSuite;
import 'package:github/hooks.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checks.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckSuiteEvent extends HookEvent {
  CheckSuiteEvent({
    this.action,
    this.checkSuite,
    this.sender,
    this.repository,
  });

  factory CheckSuiteEvent.fromJson(Map<String, dynamic> input) =>
      _$CheckSuiteEventFromJson(input);
  CheckSuite checkSuite;
  String action;
  User sender;
  Repository repository;

  Map<String, dynamic> toJson() => _$CheckSuiteEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckSuite {
  const CheckSuite({
    this.conclusion,
    this.headSha,
    this.id,
    this.pullRequests,
    this.headBranch,
  });

  factory CheckSuite.fromJson(Map<String, dynamic> input) =>
      _$CheckSuiteFromJson(input);
  final int id;
  final String headSha;
  final String conclusion;
  final String headBranch;
  @JsonKey(name: 'pull_requests', defaultValue: <PullRequest>[])
  final List<PullRequest> pullRequests;

  Map<String, dynamic> toJson() => _$CheckSuiteToJson(this);
}
