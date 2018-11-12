///
//  Generated code. Do not modify.
//  source: google/datastore/v1/datastore.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

import 'dart:async' as $async;

import 'package:grpc/grpc.dart';

import 'datastore.pb.dart';
export 'datastore.pb.dart';

class DatastoreClient extends Client {
  static final _$lookup = new ClientMethod<LookupRequest, LookupResponse>(
      '/google.datastore.v1.Datastore/Lookup',
      (LookupRequest value) => value.writeToBuffer(),
      (List<int> value) => new LookupResponse.fromBuffer(value));
  static final _$runQuery = new ClientMethod<RunQueryRequest, RunQueryResponse>(
      '/google.datastore.v1.Datastore/RunQuery',
      (RunQueryRequest value) => value.writeToBuffer(),
      (List<int> value) => new RunQueryResponse.fromBuffer(value));
  static final _$beginTransaction =
      new ClientMethod<BeginTransactionRequest, BeginTransactionResponse>(
          '/google.datastore.v1.Datastore/BeginTransaction',
          (BeginTransactionRequest value) => value.writeToBuffer(),
          (List<int> value) => new BeginTransactionResponse.fromBuffer(value));
  static final _$commit = new ClientMethod<CommitRequest, CommitResponse>(
      '/google.datastore.v1.Datastore/Commit',
      (CommitRequest value) => value.writeToBuffer(),
      (List<int> value) => new CommitResponse.fromBuffer(value));
  static final _$rollback = new ClientMethod<RollbackRequest, RollbackResponse>(
      '/google.datastore.v1.Datastore/Rollback',
      (RollbackRequest value) => value.writeToBuffer(),
      (List<int> value) => new RollbackResponse.fromBuffer(value));
  static final _$allocateIds =
      new ClientMethod<AllocateIdsRequest, AllocateIdsResponse>(
          '/google.datastore.v1.Datastore/AllocateIds',
          (AllocateIdsRequest value) => value.writeToBuffer(),
          (List<int> value) => new AllocateIdsResponse.fromBuffer(value));
  static final _$reserveIds =
      new ClientMethod<ReserveIdsRequest, ReserveIdsResponse>(
          '/google.datastore.v1.Datastore/ReserveIds',
          (ReserveIdsRequest value) => value.writeToBuffer(),
          (List<int> value) => new ReserveIdsResponse.fromBuffer(value));

  DatastoreClient(ClientChannel channel, {CallOptions options})
      : super(channel, options: options);

  ResponseFuture<LookupResponse> lookup(LookupRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$lookup, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }

  ResponseFuture<RunQueryResponse> runQuery(RunQueryRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$runQuery, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }

  ResponseFuture<BeginTransactionResponse> beginTransaction(
      BeginTransactionRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$beginTransaction, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }

  ResponseFuture<CommitResponse> commit(CommitRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$commit, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }

  ResponseFuture<RollbackResponse> rollback(RollbackRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$rollback, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }

  ResponseFuture<AllocateIdsResponse> allocateIds(AllocateIdsRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$allocateIds, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }

  ResponseFuture<ReserveIdsResponse> reserveIds(ReserveIdsRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$reserveIds, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }
}

abstract class DatastoreServiceBase extends Service {
  String get $name => 'google.datastore.v1.Datastore';

  DatastoreServiceBase() {
    $addMethod(new ServiceMethod<LookupRequest, LookupResponse>(
        'Lookup',
        lookup_Pre,
        false,
        false,
        (List<int> value) => new LookupRequest.fromBuffer(value),
        (LookupResponse value) => value.writeToBuffer()));
    $addMethod(new ServiceMethod<RunQueryRequest, RunQueryResponse>(
        'RunQuery',
        runQuery_Pre,
        false,
        false,
        (List<int> value) => new RunQueryRequest.fromBuffer(value),
        (RunQueryResponse value) => value.writeToBuffer()));
    $addMethod(
        new ServiceMethod<BeginTransactionRequest, BeginTransactionResponse>(
            'BeginTransaction',
            beginTransaction_Pre,
            false,
            false,
            (List<int> value) => new BeginTransactionRequest.fromBuffer(value),
            (BeginTransactionResponse value) => value.writeToBuffer()));
    $addMethod(new ServiceMethod<CommitRequest, CommitResponse>(
        'Commit',
        commit_Pre,
        false,
        false,
        (List<int> value) => new CommitRequest.fromBuffer(value),
        (CommitResponse value) => value.writeToBuffer()));
    $addMethod(new ServiceMethod<RollbackRequest, RollbackResponse>(
        'Rollback',
        rollback_Pre,
        false,
        false,
        (List<int> value) => new RollbackRequest.fromBuffer(value),
        (RollbackResponse value) => value.writeToBuffer()));
    $addMethod(new ServiceMethod<AllocateIdsRequest, AllocateIdsResponse>(
        'AllocateIds',
        allocateIds_Pre,
        false,
        false,
        (List<int> value) => new AllocateIdsRequest.fromBuffer(value),
        (AllocateIdsResponse value) => value.writeToBuffer()));
    $addMethod(new ServiceMethod<ReserveIdsRequest, ReserveIdsResponse>(
        'ReserveIds',
        reserveIds_Pre,
        false,
        false,
        (List<int> value) => new ReserveIdsRequest.fromBuffer(value),
        (ReserveIdsResponse value) => value.writeToBuffer()));
  }

  $async.Future<LookupResponse> lookup_Pre(
      ServiceCall call, $async.Future request) async {
    return lookup(call, await request);
  }

  $async.Future<RunQueryResponse> runQuery_Pre(
      ServiceCall call, $async.Future request) async {
    return runQuery(call, await request);
  }

  $async.Future<BeginTransactionResponse> beginTransaction_Pre(
      ServiceCall call, $async.Future request) async {
    return beginTransaction(call, await request);
  }

  $async.Future<CommitResponse> commit_Pre(
      ServiceCall call, $async.Future request) async {
    return commit(call, await request);
  }

  $async.Future<RollbackResponse> rollback_Pre(
      ServiceCall call, $async.Future request) async {
    return rollback(call, await request);
  }

  $async.Future<AllocateIdsResponse> allocateIds_Pre(
      ServiceCall call, $async.Future request) async {
    return allocateIds(call, await request);
  }

  $async.Future<ReserveIdsResponse> reserveIds_Pre(
      ServiceCall call, $async.Future request) async {
    return reserveIds(call, await request);
  }

  $async.Future<LookupResponse> lookup(ServiceCall call, LookupRequest request);
  $async.Future<RunQueryResponse> runQuery(
      ServiceCall call, RunQueryRequest request);
  $async.Future<BeginTransactionResponse> beginTransaction(
      ServiceCall call, BeginTransactionRequest request);
  $async.Future<CommitResponse> commit(ServiceCall call, CommitRequest request);
  $async.Future<RollbackResponse> rollback(
      ServiceCall call, RollbackRequest request);
  $async.Future<AllocateIdsResponse> allocateIds(
      ServiceCall call, AllocateIdsRequest request);
  $async.Future<ReserveIdsResponse> reserveIds(
      ServiceCall call, ReserveIdsRequest request);
}
