import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/requests/check_request.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:shelf/shelf.dart';

// TODO (ricardoamador): provide implementation in https://github.com/flutter/flutter/issues/113867

/// Handler for processing pull requests with 'revert' label.
///
/// For pull requests where an 'revert' label was added in pubsub,
/// check if the revert request is mergable.
class CheckRevertRequest extends CheckRequest {
  const CheckRevertRequest({
    required super.config,
    required super.cronAuthProvider,
    super.approverProvider = ApproverService.defaultProvider,
    super.pubsub = const PubSub(),
  });

  @override
  Future<Response> get() async {
    /// Currently this is unused and cannot be called.
    return process(
      config.pubsubRevertRequestSubscription,
      config.kPubsubPullNumber,
      config.kPullMesssageBatchSize,
    );
  }
}
