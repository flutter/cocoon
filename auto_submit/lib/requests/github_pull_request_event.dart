import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

part 'github_pull_request_event.g.dart';

/// PullRequestMessage is a wrapper that keeps the sender and action of the event
/// sent to the webhook.
@JsonSerializable()
class GithubPullRequestEvent {
  const GithubPullRequestEvent({
    this.object,
    this.action,
    this.sender,
  });

  /// The [PullRequest] object information.
  @JsonKey(name: 'pull_request')
  final PullRequest? object;

  /// The action as used by github for a [PullRequest] event.
  final String? action;

  /// The author login of the person who initiated the event, currently only
  /// useful when processing revert requests.
  final User? sender;

  factory GithubPullRequestEvent.fromJson(Map<String, dynamic> json) => _$GithubPullRequestEventFromJson(json);

  Map<String, dynamic> toJson() => _$GithubPullRequestEventToJson(this);
}