//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/sink.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../../google/protobuf/empty.pb.dart' as $1;
import 'sink.pb.dart' as $0;

export 'sink.pb.dart';

@$pb.GrpcServiceName('luci.resultsink.v1.Sink')
class SinkClient extends $grpc.Client {
  static final _$reportTestResults = $grpc.ClientMethod<$0.ReportTestResultsRequest, $0.ReportTestResultsResponse>(
      '/luci.resultsink.v1.Sink/ReportTestResults',
      ($0.ReportTestResultsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ReportTestResultsResponse.fromBuffer(value));
  static final _$reportInvocationLevelArtifacts = $grpc.ClientMethod<$0.ReportInvocationLevelArtifactsRequest, $1.Empty>(
      '/luci.resultsink.v1.Sink/ReportInvocationLevelArtifacts',
      ($0.ReportInvocationLevelArtifactsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));

  SinkClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.ReportTestResultsResponse> reportTestResults($0.ReportTestResultsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$reportTestResults, request, options: options);
  }

  $grpc.ResponseFuture<$1.Empty> reportInvocationLevelArtifacts($0.ReportInvocationLevelArtifactsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$reportInvocationLevelArtifacts, request, options: options);
  }
}

@$pb.GrpcServiceName('luci.resultsink.v1.Sink')
abstract class SinkServiceBase extends $grpc.Service {
  $core.String get $name => 'luci.resultsink.v1.Sink';

  SinkServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ReportTestResultsRequest, $0.ReportTestResultsResponse>(
        'ReportTestResults',
        reportTestResults_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReportTestResultsRequest.fromBuffer(value),
        ($0.ReportTestResultsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReportInvocationLevelArtifactsRequest, $1.Empty>(
        'ReportInvocationLevelArtifacts',
        reportInvocationLevelArtifacts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReportInvocationLevelArtifactsRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$0.ReportTestResultsResponse> reportTestResults_Pre($grpc.ServiceCall call, $async.Future<$0.ReportTestResultsRequest> request) async {
    return reportTestResults(call, await request);
  }

  $async.Future<$1.Empty> reportInvocationLevelArtifacts_Pre($grpc.ServiceCall call, $async.Future<$0.ReportInvocationLevelArtifactsRequest> request) async {
    return reportInvocationLevelArtifacts(call, await request);
  }

  $async.Future<$0.ReportTestResultsResponse> reportTestResults($grpc.ServiceCall call, $0.ReportTestResultsRequest request);
  $async.Future<$1.Empty> reportInvocationLevelArtifacts($grpc.ServiceCall call, $0.ReportInvocationLevelArtifactsRequest request);
}
