import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/server/authenticated_request_handler.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:shelf/shelf.dart';

class CheckRevertRequest extends AuthenticatedRequestHandler {
  const CheckRevertRequest({
    required super.config,
    required super.cronAuthProvider,
    this.approverProvider = ApproverService.defaultProvider,
    this.pubsub = const PubSub(),
  });

  final PubSub pubsub;
  final ApproverServiceProvider approverProvider;

  static const int kPullMesssageBatchSize = 100;
  static const int kPubsubPullNumber = 5;

  @override
  Future<Response> get() async {
    return Response.ok('Finished processing changes');
  }
}
