import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pull_request_message.g.dart';

/// PrRecord allows tracking of the event type on a [PullRequest] and the user
/// who triggered that event type through github.
@JsonSerializable()
class PullRequestMessage {
  const PullRequestMessage({
    this.pullRequest,
    this.action,
    this.sender,
  });

  /// The [PullRequest] object information.
  final PullRequest? pullRequest;

  /// The action as used by github for a [PullRequest] event.
  final String? action;

  /// The author login of the person who initiated the event, currently only
  /// useful when processing revert requests.
  final User? sender;

  factory PullRequestMessage.fromJson(Map<String, dynamic> json) => _$PullRequestMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestMessageToJson(this);
}
