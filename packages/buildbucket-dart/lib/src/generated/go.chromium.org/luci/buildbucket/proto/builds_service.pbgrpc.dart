//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builds_service.proto
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

import 'build.pb.dart' as $1;
import 'builds_service.pb.dart' as $0;

export 'builds_service.pb.dart';

@$pb.GrpcServiceName('buildbucket.v2.Builds')
class BuildsClient extends $grpc.Client {
  static final _$getBuild = $grpc.ClientMethod<$0.GetBuildRequest, $1.Build>(
      '/buildbucket.v2.Builds/GetBuild',
      ($0.GetBuildRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$searchBuilds =
      $grpc.ClientMethod<$0.SearchBuildsRequest, $0.SearchBuildsResponse>(
          '/buildbucket.v2.Builds/SearchBuilds',
          ($0.SearchBuildsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.SearchBuildsResponse.fromBuffer(value));
  static final _$updateBuild =
      $grpc.ClientMethod<$0.UpdateBuildRequest, $1.Build>(
          '/buildbucket.v2.Builds/UpdateBuild',
          ($0.UpdateBuildRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$scheduleBuild =
      $grpc.ClientMethod<$0.ScheduleBuildRequest, $1.Build>(
          '/buildbucket.v2.Builds/ScheduleBuild',
          ($0.ScheduleBuildRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$cancelBuild =
      $grpc.ClientMethod<$0.CancelBuildRequest, $1.Build>(
          '/buildbucket.v2.Builds/CancelBuild',
          ($0.CancelBuildRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$batch = $grpc.ClientMethod<$0.BatchRequest, $0.BatchResponse>(
      '/buildbucket.v2.Builds/Batch',
      ($0.BatchRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.BatchResponse.fromBuffer(value));
  static final _$createBuild =
      $grpc.ClientMethod<$0.CreateBuildRequest, $1.Build>(
          '/buildbucket.v2.Builds/CreateBuild',
          ($0.CreateBuildRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$synthesizeBuild =
      $grpc.ClientMethod<$0.SynthesizeBuildRequest, $1.Build>(
          '/buildbucket.v2.Builds/SynthesizeBuild',
          ($0.SynthesizeBuildRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$getBuildStatus =
      $grpc.ClientMethod<$0.GetBuildStatusRequest, $1.Build>(
          '/buildbucket.v2.Builds/GetBuildStatus',
          ($0.GetBuildStatusRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Build.fromBuffer(value));
  static final _$startBuild =
      $grpc.ClientMethod<$0.StartBuildRequest, $0.StartBuildResponse>(
          '/buildbucket.v2.Builds/StartBuild',
          ($0.StartBuildRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.StartBuildResponse.fromBuffer(value));

  BuildsClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.Build> getBuild($0.GetBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBuild, request, options: options);
  }

  $grpc.ResponseFuture<$0.SearchBuildsResponse> searchBuilds(
      $0.SearchBuildsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$searchBuilds, request, options: options);
  }

  $grpc.ResponseFuture<$1.Build> updateBuild($0.UpdateBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateBuild, request, options: options);
  }

  $grpc.ResponseFuture<$1.Build> scheduleBuild($0.ScheduleBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$scheduleBuild, request, options: options);
  }

  $grpc.ResponseFuture<$1.Build> cancelBuild($0.CancelBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$cancelBuild, request, options: options);
  }

  $grpc.ResponseFuture<$0.BatchResponse> batch($0.BatchRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$batch, request, options: options);
  }

  $grpc.ResponseFuture<$1.Build> createBuild($0.CreateBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createBuild, request, options: options);
  }

  $grpc.ResponseFuture<$1.Build> synthesizeBuild(
      $0.SynthesizeBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$synthesizeBuild, request, options: options);
  }

  $grpc.ResponseFuture<$1.Build> getBuildStatus(
      $0.GetBuildStatusRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBuildStatus, request, options: options);
  }

  $grpc.ResponseFuture<$0.StartBuildResponse> startBuild(
      $0.StartBuildRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$startBuild, request, options: options);
  }
}

@$pb.GrpcServiceName('buildbucket.v2.Builds')
abstract class BuildsServiceBase extends $grpc.Service {
  $core.String get $name => 'buildbucket.v2.Builds';

  BuildsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetBuildRequest, $1.Build>(
        'GetBuild',
        getBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetBuildRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SearchBuildsRequest, $0.SearchBuildsResponse>(
            'SearchBuilds',
            searchBuilds_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SearchBuildsRequest.fromBuffer(value),
            ($0.SearchBuildsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateBuildRequest, $1.Build>(
        'UpdateBuild',
        updateBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateBuildRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ScheduleBuildRequest, $1.Build>(
        'ScheduleBuild',
        scheduleBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ScheduleBuildRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CancelBuildRequest, $1.Build>(
        'CancelBuild',
        cancelBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CancelBuildRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.BatchRequest, $0.BatchResponse>(
        'Batch',
        batch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.BatchRequest.fromBuffer(value),
        ($0.BatchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateBuildRequest, $1.Build>(
        'CreateBuild',
        createBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateBuildRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SynthesizeBuildRequest, $1.Build>(
        'SynthesizeBuild',
        synthesizeBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SynthesizeBuildRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetBuildStatusRequest, $1.Build>(
        'GetBuildStatus',
        getBuildStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetBuildStatusRequest.fromBuffer(value),
        ($1.Build value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartBuildRequest, $0.StartBuildResponse>(
        'StartBuild',
        startBuild_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartBuildRequest.fromBuffer(value),
        ($0.StartBuildResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.Build> getBuild_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetBuildRequest> request) async {
    return getBuild(call, await request);
  }

  $async.Future<$0.SearchBuildsResponse> searchBuilds_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.SearchBuildsRequest> request) async {
    return searchBuilds(call, await request);
  }

  $async.Future<$1.Build> updateBuild_Pre($grpc.ServiceCall call,
      $async.Future<$0.UpdateBuildRequest> request) async {
    return updateBuild(call, await request);
  }

  $async.Future<$1.Build> scheduleBuild_Pre($grpc.ServiceCall call,
      $async.Future<$0.ScheduleBuildRequest> request) async {
    return scheduleBuild(call, await request);
  }

  $async.Future<$1.Build> cancelBuild_Pre($grpc.ServiceCall call,
      $async.Future<$0.CancelBuildRequest> request) async {
    return cancelBuild(call, await request);
  }

  $async.Future<$0.BatchResponse> batch_Pre(
      $grpc.ServiceCall call, $async.Future<$0.BatchRequest> request) async {
    return batch(call, await request);
  }

  $async.Future<$1.Build> createBuild_Pre($grpc.ServiceCall call,
      $async.Future<$0.CreateBuildRequest> request) async {
    return createBuild(call, await request);
  }

  $async.Future<$1.Build> synthesizeBuild_Pre($grpc.ServiceCall call,
      $async.Future<$0.SynthesizeBuildRequest> request) async {
    return synthesizeBuild(call, await request);
  }

  $async.Future<$1.Build> getBuildStatus_Pre($grpc.ServiceCall call,
      $async.Future<$0.GetBuildStatusRequest> request) async {
    return getBuildStatus(call, await request);
  }

  $async.Future<$0.StartBuildResponse> startBuild_Pre($grpc.ServiceCall call,
      $async.Future<$0.StartBuildRequest> request) async {
    return startBuild(call, await request);
  }

  $async.Future<$1.Build> getBuild(
      $grpc.ServiceCall call, $0.GetBuildRequest request);
  $async.Future<$0.SearchBuildsResponse> searchBuilds(
      $grpc.ServiceCall call, $0.SearchBuildsRequest request);
  $async.Future<$1.Build> updateBuild(
      $grpc.ServiceCall call, $0.UpdateBuildRequest request);
  $async.Future<$1.Build> scheduleBuild(
      $grpc.ServiceCall call, $0.ScheduleBuildRequest request);
  $async.Future<$1.Build> cancelBuild(
      $grpc.ServiceCall call, $0.CancelBuildRequest request);
  $async.Future<$0.BatchResponse> batch(
      $grpc.ServiceCall call, $0.BatchRequest request);
  $async.Future<$1.Build> createBuild(
      $grpc.ServiceCall call, $0.CreateBuildRequest request);
  $async.Future<$1.Build> synthesizeBuild(
      $grpc.ServiceCall call, $0.SynthesizeBuildRequest request);
  $async.Future<$1.Build> getBuildStatus(
      $grpc.ServiceCall call, $0.GetBuildStatusRequest request);
  $async.Future<$0.StartBuildResponse> startBuild(
      $grpc.ServiceCall call, $0.StartBuildRequest request);
}
