//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/resultdb.proto
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

import 'artifact.pb.dart' as $3;
import 'invocation.pb.dart' as $1;
import 'resultdb.pb.dart' as $0;
import 'test_result.pb.dart' as $2;

export 'resultdb.pb.dart';

@$pb.GrpcServiceName('luci.resultdb.v1.ResultDB')
class ResultDBClient extends $grpc.Client {
  static final _$getInvocation = $grpc.ClientMethod<$0.GetInvocationRequest, $1.Invocation>(
      '/luci.resultdb.v1.ResultDB/GetInvocation',
      ($0.GetInvocationRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Invocation.fromBuffer(value));
  static final _$getTestResult = $grpc.ClientMethod<$0.GetTestResultRequest, $2.TestResult>(
      '/luci.resultdb.v1.ResultDB/GetTestResult',
      ($0.GetTestResultRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.TestResult.fromBuffer(value));
  static final _$listTestResults = $grpc.ClientMethod<$0.ListTestResultsRequest, $0.ListTestResultsResponse>(
      '/luci.resultdb.v1.ResultDB/ListTestResults',
      ($0.ListTestResultsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ListTestResultsResponse.fromBuffer(value));
  static final _$getTestExoneration = $grpc.ClientMethod<$0.GetTestExonerationRequest, $2.TestExoneration>(
      '/luci.resultdb.v1.ResultDB/GetTestExoneration',
      ($0.GetTestExonerationRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.TestExoneration.fromBuffer(value));
  static final _$listTestExonerations =
      $grpc.ClientMethod<$0.ListTestExonerationsRequest, $0.ListTestExonerationsResponse>(
          '/luci.resultdb.v1.ResultDB/ListTestExonerations',
          ($0.ListTestExonerationsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.ListTestExonerationsResponse.fromBuffer(value));
  static final _$queryTestResults = $grpc.ClientMethod<$0.QueryTestResultsRequest, $0.QueryTestResultsResponse>(
      '/luci.resultdb.v1.ResultDB/QueryTestResults',
      ($0.QueryTestResultsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.QueryTestResultsResponse.fromBuffer(value));
  static final _$queryTestExonerations =
      $grpc.ClientMethod<$0.QueryTestExonerationsRequest, $0.QueryTestExonerationsResponse>(
          '/luci.resultdb.v1.ResultDB/QueryTestExonerations',
          ($0.QueryTestExonerationsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.QueryTestExonerationsResponse.fromBuffer(value));
  static final _$queryTestResultStatistics =
      $grpc.ClientMethod<$0.QueryTestResultStatisticsRequest, $0.QueryTestResultStatisticsResponse>(
          '/luci.resultdb.v1.ResultDB/QueryTestResultStatistics',
          ($0.QueryTestResultStatisticsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.QueryTestResultStatisticsResponse.fromBuffer(value));
  static final _$queryNewTestVariants =
      $grpc.ClientMethod<$0.QueryNewTestVariantsRequest, $0.QueryNewTestVariantsResponse>(
          '/luci.resultdb.v1.ResultDB/QueryNewTestVariants',
          ($0.QueryNewTestVariantsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.QueryNewTestVariantsResponse.fromBuffer(value));
  static final _$getArtifact = $grpc.ClientMethod<$0.GetArtifactRequest, $3.Artifact>(
      '/luci.resultdb.v1.ResultDB/GetArtifact',
      ($0.GetArtifactRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $3.Artifact.fromBuffer(value));
  static final _$listArtifacts = $grpc.ClientMethod<$0.ListArtifactsRequest, $0.ListArtifactsResponse>(
      '/luci.resultdb.v1.ResultDB/ListArtifacts',
      ($0.ListArtifactsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ListArtifactsResponse.fromBuffer(value));
  static final _$queryArtifacts = $grpc.ClientMethod<$0.QueryArtifactsRequest, $0.QueryArtifactsResponse>(
      '/luci.resultdb.v1.ResultDB/QueryArtifacts',
      ($0.QueryArtifactsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.QueryArtifactsResponse.fromBuffer(value));
  static final _$queryTestVariants = $grpc.ClientMethod<$0.QueryTestVariantsRequest, $0.QueryTestVariantsResponse>(
      '/luci.resultdb.v1.ResultDB/QueryTestVariants',
      ($0.QueryTestVariantsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.QueryTestVariantsResponse.fromBuffer(value));
  static final _$batchGetTestVariants =
      $grpc.ClientMethod<$0.BatchGetTestVariantsRequest, $0.BatchGetTestVariantsResponse>(
          '/luci.resultdb.v1.ResultDB/BatchGetTestVariants',
          ($0.BatchGetTestVariantsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.BatchGetTestVariantsResponse.fromBuffer(value));
  static final _$queryTestMetadata = $grpc.ClientMethod<$0.QueryTestMetadataRequest, $0.QueryTestMetadataResponse>(
      '/luci.resultdb.v1.ResultDB/QueryTestMetadata',
      ($0.QueryTestMetadataRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.QueryTestMetadataResponse.fromBuffer(value));

  ResultDBClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options, $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.Invocation> getInvocation($0.GetInvocationRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getInvocation, request, options: options);
  }

  $grpc.ResponseFuture<$2.TestResult> getTestResult($0.GetTestResultRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTestResult, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListTestResultsResponse> listTestResults($0.ListTestResultsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listTestResults, request, options: options);
  }

  $grpc.ResponseFuture<$2.TestExoneration> getTestExoneration($0.GetTestExonerationRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTestExoneration, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListTestExonerationsResponse> listTestExonerations($0.ListTestExonerationsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listTestExonerations, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryTestResultsResponse> queryTestResults($0.QueryTestResultsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryTestResults, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryTestExonerationsResponse> queryTestExonerations($0.QueryTestExonerationsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryTestExonerations, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryTestResultStatisticsResponse> queryTestResultStatistics(
      $0.QueryTestResultStatisticsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryTestResultStatistics, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryNewTestVariantsResponse> queryNewTestVariants($0.QueryNewTestVariantsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryNewTestVariants, request, options: options);
  }

  $grpc.ResponseFuture<$3.Artifact> getArtifact($0.GetArtifactRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getArtifact, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListArtifactsResponse> listArtifacts($0.ListArtifactsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listArtifacts, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryArtifactsResponse> queryArtifacts($0.QueryArtifactsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryArtifacts, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryTestVariantsResponse> queryTestVariants($0.QueryTestVariantsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryTestVariants, request, options: options);
  }

  $grpc.ResponseFuture<$0.BatchGetTestVariantsResponse> batchGetTestVariants($0.BatchGetTestVariantsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$batchGetTestVariants, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryTestMetadataResponse> queryTestMetadata($0.QueryTestMetadataRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryTestMetadata, request, options: options);
  }
}

@$pb.GrpcServiceName('luci.resultdb.v1.ResultDB')
abstract class ResultDBServiceBase extends $grpc.Service {
  $core.String get $name => 'luci.resultdb.v1.ResultDB';

  ResultDBServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetInvocationRequest, $1.Invocation>(
        'GetInvocation',
        getInvocation_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetInvocationRequest.fromBuffer(value),
        ($1.Invocation value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTestResultRequest, $2.TestResult>(
        'GetTestResult',
        getTestResult_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetTestResultRequest.fromBuffer(value),
        ($2.TestResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTestResultsRequest, $0.ListTestResultsResponse>(
        'ListTestResults',
        listTestResults_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListTestResultsRequest.fromBuffer(value),
        ($0.ListTestResultsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTestExonerationRequest, $2.TestExoneration>(
        'GetTestExoneration',
        getTestExoneration_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetTestExonerationRequest.fromBuffer(value),
        ($2.TestExoneration value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTestExonerationsRequest, $0.ListTestExonerationsResponse>(
        'ListTestExonerations',
        listTestExonerations_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListTestExonerationsRequest.fromBuffer(value),
        ($0.ListTestExonerationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryTestResultsRequest, $0.QueryTestResultsResponse>(
        'QueryTestResults',
        queryTestResults_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryTestResultsRequest.fromBuffer(value),
        ($0.QueryTestResultsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryTestExonerationsRequest, $0.QueryTestExonerationsResponse>(
        'QueryTestExonerations',
        queryTestExonerations_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryTestExonerationsRequest.fromBuffer(value),
        ($0.QueryTestExonerationsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryTestResultStatisticsRequest, $0.QueryTestResultStatisticsResponse>(
        'QueryTestResultStatistics',
        queryTestResultStatistics_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryTestResultStatisticsRequest.fromBuffer(value),
        ($0.QueryTestResultStatisticsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryNewTestVariantsRequest, $0.QueryNewTestVariantsResponse>(
        'QueryNewTestVariants',
        queryNewTestVariants_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryNewTestVariantsRequest.fromBuffer(value),
        ($0.QueryNewTestVariantsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetArtifactRequest, $3.Artifact>(
        'GetArtifact',
        getArtifact_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetArtifactRequest.fromBuffer(value),
        ($3.Artifact value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListArtifactsRequest, $0.ListArtifactsResponse>(
        'ListArtifacts',
        listArtifacts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListArtifactsRequest.fromBuffer(value),
        ($0.ListArtifactsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryArtifactsRequest, $0.QueryArtifactsResponse>(
        'QueryArtifacts',
        queryArtifacts_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryArtifactsRequest.fromBuffer(value),
        ($0.QueryArtifactsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryTestVariantsRequest, $0.QueryTestVariantsResponse>(
        'QueryTestVariants',
        queryTestVariants_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryTestVariantsRequest.fromBuffer(value),
        ($0.QueryTestVariantsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BatchGetTestVariantsRequest, $0.BatchGetTestVariantsResponse>(
        'BatchGetTestVariants',
        batchGetTestVariants_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.BatchGetTestVariantsRequest.fromBuffer(value),
        ($0.BatchGetTestVariantsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryTestMetadataRequest, $0.QueryTestMetadataResponse>(
        'QueryTestMetadata',
        queryTestMetadata_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryTestMetadataRequest.fromBuffer(value),
        ($0.QueryTestMetadataResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.Invocation> getInvocation_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetInvocationRequest> request) async {
    return getInvocation(call, await request);
  }

  $async.Future<$2.TestResult> getTestResult_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetTestResultRequest> request) async {
    return getTestResult(call, await request);
  }

  $async.Future<$0.ListTestResultsResponse> listTestResults_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ListTestResultsRequest> request) async {
    return listTestResults(call, await request);
  }

  $async.Future<$2.TestExoneration> getTestExoneration_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetTestExonerationRequest> request) async {
    return getTestExoneration(call, await request);
  }

  $async.Future<$0.ListTestExonerationsResponse> listTestExonerations_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ListTestExonerationsRequest> request) async {
    return listTestExonerations(call, await request);
  }

  $async.Future<$0.QueryTestResultsResponse> queryTestResults_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryTestResultsRequest> request) async {
    return queryTestResults(call, await request);
  }

  $async.Future<$0.QueryTestExonerationsResponse> queryTestExonerations_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryTestExonerationsRequest> request) async {
    return queryTestExonerations(call, await request);
  }

  $async.Future<$0.QueryTestResultStatisticsResponse> queryTestResultStatistics_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryTestResultStatisticsRequest> request) async {
    return queryTestResultStatistics(call, await request);
  }

  $async.Future<$0.QueryNewTestVariantsResponse> queryNewTestVariants_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryNewTestVariantsRequest> request) async {
    return queryNewTestVariants(call, await request);
  }

  $async.Future<$3.Artifact> getArtifact_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetArtifactRequest> request) async {
    return getArtifact(call, await request);
  }

  $async.Future<$0.ListArtifactsResponse> listArtifacts_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ListArtifactsRequest> request) async {
    return listArtifacts(call, await request);
  }

  $async.Future<$0.QueryArtifactsResponse> queryArtifacts_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryArtifactsRequest> request) async {
    return queryArtifacts(call, await request);
  }

  $async.Future<$0.QueryTestVariantsResponse> queryTestVariants_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryTestVariantsRequest> request) async {
    return queryTestVariants(call, await request);
  }

  $async.Future<$0.BatchGetTestVariantsResponse> batchGetTestVariants_Pre(
      $grpc.ServiceCall call, $async.Future<$0.BatchGetTestVariantsRequest> request) async {
    return batchGetTestVariants(call, await request);
  }

  $async.Future<$0.QueryTestMetadataResponse> queryTestMetadata_Pre(
      $grpc.ServiceCall call, $async.Future<$0.QueryTestMetadataRequest> request) async {
    return queryTestMetadata(call, await request);
  }

  $async.Future<$1.Invocation> getInvocation($grpc.ServiceCall call, $0.GetInvocationRequest request);
  $async.Future<$2.TestResult> getTestResult($grpc.ServiceCall call, $0.GetTestResultRequest request);
  $async.Future<$0.ListTestResultsResponse> listTestResults($grpc.ServiceCall call, $0.ListTestResultsRequest request);
  $async.Future<$2.TestExoneration> getTestExoneration($grpc.ServiceCall call, $0.GetTestExonerationRequest request);
  $async.Future<$0.ListTestExonerationsResponse> listTestExonerations(
      $grpc.ServiceCall call, $0.ListTestExonerationsRequest request);
  $async.Future<$0.QueryTestResultsResponse> queryTestResults(
      $grpc.ServiceCall call, $0.QueryTestResultsRequest request);
  $async.Future<$0.QueryTestExonerationsResponse> queryTestExonerations(
      $grpc.ServiceCall call, $0.QueryTestExonerationsRequest request);
  $async.Future<$0.QueryTestResultStatisticsResponse> queryTestResultStatistics(
      $grpc.ServiceCall call, $0.QueryTestResultStatisticsRequest request);
  $async.Future<$0.QueryNewTestVariantsResponse> queryNewTestVariants(
      $grpc.ServiceCall call, $0.QueryNewTestVariantsRequest request);
  $async.Future<$3.Artifact> getArtifact($grpc.ServiceCall call, $0.GetArtifactRequest request);
  $async.Future<$0.ListArtifactsResponse> listArtifacts($grpc.ServiceCall call, $0.ListArtifactsRequest request);
  $async.Future<$0.QueryArtifactsResponse> queryArtifacts($grpc.ServiceCall call, $0.QueryArtifactsRequest request);
  $async.Future<$0.QueryTestVariantsResponse> queryTestVariants(
      $grpc.ServiceCall call, $0.QueryTestVariantsRequest request);
  $async.Future<$0.BatchGetTestVariantsResponse> batchGetTestVariants(
      $grpc.ServiceCall call, $0.BatchGetTestVariantsRequest request);
  $async.Future<$0.QueryTestMetadataResponse> queryTestMetadata(
      $grpc.ServiceCall call, $0.QueryTestMetadataRequest request);
}
