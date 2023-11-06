import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_web.dart';

class BuildBucketGrpc {
  ClientChannel? clientChannelStub;
  GrpcWebClientChannel? grpcWebClientChannel;

  BuildBucketGrpc();

  void makeRequest() {
    // clientChannelStub = ClientChannel(host)
    grpcWebClientChannel = GrpcWebClientChannel.xhr(Uri());
    // grpcWebClientChannel.
  }
}