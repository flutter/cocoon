//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_service.proto
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

import 'builder_common.pb.dart' as $1;
import 'builder_service.pb.dart' as $0;

export 'builder_service.pb.dart';

@$pb.GrpcServiceName('buildbucket.v2.Builders')
class BuildersClient extends $grpc.Client {
  static final _$getBuilder = $grpc.ClientMethod<$0.GetBuilderRequest, $1.BuilderItem>(
      '/buildbucket.v2.Builders/GetBuilder',
      ($0.GetBuilderRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $1.BuilderItem.fromBuffer(value));
  static final _$listBuilders = $grpc.ClientMethod<$0.ListBuildersRequest, $0.ListBuildersResponse>(
      '/buildbucket.v2.Builders/ListBuilders',
      ($0.ListBuildersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ListBuildersResponse.fromBuffer(value));
  static final _$setBuilderHealth = $grpc.ClientMethod<$0.SetBuilderHealthRequest, $0.SetBuilderHealthResponse>(
      '/buildbucket.v2.Builders/SetBuilderHealth',
      ($0.SetBuilderHealthRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SetBuilderHealthResponse.fromBuffer(value));

  BuildersClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options, $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.BuilderItem> getBuilder($0.GetBuilderRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getBuilder, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListBuildersResponse> listBuilders($0.ListBuildersRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listBuilders, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetBuilderHealthResponse> setBuilderHealth($0.SetBuilderHealthRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setBuilderHealth, request, options: options);
  }
}

@$pb.GrpcServiceName('buildbucket.v2.Builders')
abstract class BuildersServiceBase extends $grpc.Service {
  $core.String get $name => 'buildbucket.v2.Builders';

  BuildersServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetBuilderRequest, $1.BuilderItem>(
        'GetBuilder',
        getBuilder_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetBuilderRequest.fromBuffer(value),
        ($1.BuilderItem value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListBuildersRequest, $0.ListBuildersResponse>(
        'ListBuilders',
        listBuilders_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListBuildersRequest.fromBuffer(value),
        ($0.ListBuildersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetBuilderHealthRequest, $0.SetBuilderHealthResponse>(
        'SetBuilderHealth',
        setBuilderHealth_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetBuilderHealthRequest.fromBuffer(value),
        ($0.SetBuilderHealthResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.BuilderItem> getBuilder_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetBuilderRequest> request) async {
    return getBuilder(call, await request);
  }

  $async.Future<$0.ListBuildersResponse> listBuilders_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ListBuildersRequest> request) async {
    return listBuilders(call, await request);
  }

  $async.Future<$0.SetBuilderHealthResponse> setBuilderHealth_Pre(
      $grpc.ServiceCall call, $async.Future<$0.SetBuilderHealthRequest> request) async {
    return setBuilderHealth(call, await request);
  }

  $async.Future<$1.BuilderItem> getBuilder($grpc.ServiceCall call, $0.GetBuilderRequest request);
  $async.Future<$0.ListBuildersResponse> listBuilders($grpc.ServiceCall call, $0.ListBuildersRequest request);
  $async.Future<$0.SetBuilderHealthResponse> setBuilderHealth(
      $grpc.ServiceCall call, $0.SetBuilderHealthRequest request);
}
