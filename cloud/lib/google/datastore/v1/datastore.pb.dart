///
//  Generated code. Do not modify.
//  source: google/datastore/v1/datastore.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'entity.pb.dart' as $0;
import 'query.pb.dart' as $1;

import 'datastore.pbenum.dart';

export 'datastore.pbenum.dart';

class LookupRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('LookupRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<ReadOptions>(1, 'readOptions', $pb.PbFieldType.OM,
        ReadOptions.getDefault, ReadOptions.create)
    ..pp<$0.Key>(
        3, 'keys', $pb.PbFieldType.PM, $0.Key.$checkItem, $0.Key.create)
    ..aOS(8, 'projectId')
    ..hasRequiredFields = false;

  LookupRequest() : super();
  LookupRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LookupRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LookupRequest clone() => new LookupRequest()..mergeFromMessage(this);
  LookupRequest copyWith(void Function(LookupRequest) updates) =>
      super.copyWith((message) => updates(message as LookupRequest));
  $pb.BuilderInfo get info_ => _i;
  static LookupRequest create() => new LookupRequest();
  static $pb.PbList<LookupRequest> createRepeated() =>
      new $pb.PbList<LookupRequest>();
  static LookupRequest getDefault() => _defaultInstance ??= create()..freeze();
  static LookupRequest _defaultInstance;
  static void $checkItem(LookupRequest v) {
    if (v is! LookupRequest) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  ReadOptions get readOptions => $_getN(0);
  set readOptions(ReadOptions v) {
    setField(1, v);
  }

  bool hasReadOptions() => $_has(0);
  void clearReadOptions() => clearField(1);

  List<$0.Key> get keys => $_getList(1);

  String get projectId => $_getS(2, '');
  set projectId(String v) {
    $_setString(2, v);
  }

  bool hasProjectId() => $_has(2);
  void clearProjectId() => clearField(8);
}

class LookupResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('LookupResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<$1.EntityResult>(1, 'found', $pb.PbFieldType.PM,
        $1.EntityResult.$checkItem, $1.EntityResult.create)
    ..pp<$1.EntityResult>(2, 'missing', $pb.PbFieldType.PM,
        $1.EntityResult.$checkItem, $1.EntityResult.create)
    ..pp<$0.Key>(
        3, 'deferred', $pb.PbFieldType.PM, $0.Key.$checkItem, $0.Key.create)
    ..hasRequiredFields = false;

  LookupResponse() : super();
  LookupResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LookupResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LookupResponse clone() => new LookupResponse()..mergeFromMessage(this);
  LookupResponse copyWith(void Function(LookupResponse) updates) =>
      super.copyWith((message) => updates(message as LookupResponse));
  $pb.BuilderInfo get info_ => _i;
  static LookupResponse create() => new LookupResponse();
  static $pb.PbList<LookupResponse> createRepeated() =>
      new $pb.PbList<LookupResponse>();
  static LookupResponse getDefault() => _defaultInstance ??= create()..freeze();
  static LookupResponse _defaultInstance;
  static void $checkItem(LookupResponse v) {
    if (v is! LookupResponse) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<$1.EntityResult> get found => $_getList(0);

  List<$1.EntityResult> get missing => $_getList(1);

  List<$0.Key> get deferred => $_getList(2);
}

class RunQueryRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('RunQueryRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<ReadOptions>(1, 'readOptions', $pb.PbFieldType.OM,
        ReadOptions.getDefault, ReadOptions.create)
    ..a<$0.PartitionId>(2, 'partitionId', $pb.PbFieldType.OM,
        $0.PartitionId.getDefault, $0.PartitionId.create)
    ..a<$1.Query>(
        3, 'query', $pb.PbFieldType.OM, $1.Query.getDefault, $1.Query.create)
    ..a<$1.GqlQuery>(7, 'gqlQuery', $pb.PbFieldType.OM, $1.GqlQuery.getDefault,
        $1.GqlQuery.create)
    ..aOS(8, 'projectId')
    ..hasRequiredFields = false;

  RunQueryRequest() : super();
  RunQueryRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  RunQueryRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  RunQueryRequest clone() => new RunQueryRequest()..mergeFromMessage(this);
  RunQueryRequest copyWith(void Function(RunQueryRequest) updates) =>
      super.copyWith((message) => updates(message as RunQueryRequest));
  $pb.BuilderInfo get info_ => _i;
  static RunQueryRequest create() => new RunQueryRequest();
  static $pb.PbList<RunQueryRequest> createRepeated() =>
      new $pb.PbList<RunQueryRequest>();
  static RunQueryRequest getDefault() =>
      _defaultInstance ??= create()..freeze();
  static RunQueryRequest _defaultInstance;
  static void $checkItem(RunQueryRequest v) {
    if (v is! RunQueryRequest) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  ReadOptions get readOptions => $_getN(0);
  set readOptions(ReadOptions v) {
    setField(1, v);
  }

  bool hasReadOptions() => $_has(0);
  void clearReadOptions() => clearField(1);

  $0.PartitionId get partitionId => $_getN(1);
  set partitionId($0.PartitionId v) {
    setField(2, v);
  }

  bool hasPartitionId() => $_has(1);
  void clearPartitionId() => clearField(2);

  $1.Query get query => $_getN(2);
  set query($1.Query v) {
    setField(3, v);
  }

  bool hasQuery() => $_has(2);
  void clearQuery() => clearField(3);

  $1.GqlQuery get gqlQuery => $_getN(3);
  set gqlQuery($1.GqlQuery v) {
    setField(7, v);
  }

  bool hasGqlQuery() => $_has(3);
  void clearGqlQuery() => clearField(7);

  String get projectId => $_getS(4, '');
  set projectId(String v) {
    $_setString(4, v);
  }

  bool hasProjectId() => $_has(4);
  void clearProjectId() => clearField(8);
}

class RunQueryResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('RunQueryResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<$1.QueryResultBatch>(1, 'batch', $pb.PbFieldType.OM,
        $1.QueryResultBatch.getDefault, $1.QueryResultBatch.create)
    ..a<$1.Query>(
        2, 'query', $pb.PbFieldType.OM, $1.Query.getDefault, $1.Query.create)
    ..hasRequiredFields = false;

  RunQueryResponse() : super();
  RunQueryResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  RunQueryResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  RunQueryResponse clone() => new RunQueryResponse()..mergeFromMessage(this);
  RunQueryResponse copyWith(void Function(RunQueryResponse) updates) =>
      super.copyWith((message) => updates(message as RunQueryResponse));
  $pb.BuilderInfo get info_ => _i;
  static RunQueryResponse create() => new RunQueryResponse();
  static $pb.PbList<RunQueryResponse> createRepeated() =>
      new $pb.PbList<RunQueryResponse>();
  static RunQueryResponse getDefault() =>
      _defaultInstance ??= create()..freeze();
  static RunQueryResponse _defaultInstance;
  static void $checkItem(RunQueryResponse v) {
    if (v is! RunQueryResponse) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  $1.QueryResultBatch get batch => $_getN(0);
  set batch($1.QueryResultBatch v) {
    setField(1, v);
  }

  bool hasBatch() => $_has(0);
  void clearBatch() => clearField(1);

  $1.Query get query => $_getN(1);
  set query($1.Query v) {
    setField(2, v);
  }

  bool hasQuery() => $_has(1);
  void clearQuery() => clearField(2);
}

class BeginTransactionRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'BeginTransactionRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(8, 'projectId')
    ..a<TransactionOptions>(10, 'transactionOptions', $pb.PbFieldType.OM,
        TransactionOptions.getDefault, TransactionOptions.create)
    ..hasRequiredFields = false;

  BeginTransactionRequest() : super();
  BeginTransactionRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  BeginTransactionRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  BeginTransactionRequest clone() =>
      new BeginTransactionRequest()..mergeFromMessage(this);
  BeginTransactionRequest copyWith(
          void Function(BeginTransactionRequest) updates) =>
      super.copyWith((message) => updates(message as BeginTransactionRequest));
  $pb.BuilderInfo get info_ => _i;
  static BeginTransactionRequest create() => new BeginTransactionRequest();
  static $pb.PbList<BeginTransactionRequest> createRepeated() =>
      new $pb.PbList<BeginTransactionRequest>();
  static BeginTransactionRequest getDefault() =>
      _defaultInstance ??= create()..freeze();
  static BeginTransactionRequest _defaultInstance;
  static void $checkItem(BeginTransactionRequest v) {
    if (v is! BeginTransactionRequest)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get projectId => $_getS(0, '');
  set projectId(String v) {
    $_setString(0, v);
  }

  bool hasProjectId() => $_has(0);
  void clearProjectId() => clearField(8);

  TransactionOptions get transactionOptions => $_getN(1);
  set transactionOptions(TransactionOptions v) {
    setField(10, v);
  }

  bool hasTransactionOptions() => $_has(1);
  void clearTransactionOptions() => clearField(10);
}

class BeginTransactionResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'BeginTransactionResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<List<int>>(1, 'transaction', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  BeginTransactionResponse() : super();
  BeginTransactionResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  BeginTransactionResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  BeginTransactionResponse clone() =>
      new BeginTransactionResponse()..mergeFromMessage(this);
  BeginTransactionResponse copyWith(
          void Function(BeginTransactionResponse) updates) =>
      super.copyWith((message) => updates(message as BeginTransactionResponse));
  $pb.BuilderInfo get info_ => _i;
  static BeginTransactionResponse create() => new BeginTransactionResponse();
  static $pb.PbList<BeginTransactionResponse> createRepeated() =>
      new $pb.PbList<BeginTransactionResponse>();
  static BeginTransactionResponse getDefault() =>
      _defaultInstance ??= create()..freeze();
  static BeginTransactionResponse _defaultInstance;
  static void $checkItem(BeginTransactionResponse v) {
    if (v is! BeginTransactionResponse)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<int> get transaction => $_getN(0);
  set transaction(List<int> v) {
    $_setBytes(0, v);
  }

  bool hasTransaction() => $_has(0);
  void clearTransaction() => clearField(1);
}

class RollbackRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('RollbackRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<List<int>>(1, 'transaction', $pb.PbFieldType.OY)
    ..aOS(8, 'projectId')
    ..hasRequiredFields = false;

  RollbackRequest() : super();
  RollbackRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  RollbackRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  RollbackRequest clone() => new RollbackRequest()..mergeFromMessage(this);
  RollbackRequest copyWith(void Function(RollbackRequest) updates) =>
      super.copyWith((message) => updates(message as RollbackRequest));
  $pb.BuilderInfo get info_ => _i;
  static RollbackRequest create() => new RollbackRequest();
  static $pb.PbList<RollbackRequest> createRepeated() =>
      new $pb.PbList<RollbackRequest>();
  static RollbackRequest getDefault() =>
      _defaultInstance ??= create()..freeze();
  static RollbackRequest _defaultInstance;
  static void $checkItem(RollbackRequest v) {
    if (v is! RollbackRequest) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<int> get transaction => $_getN(0);
  set transaction(List<int> v) {
    $_setBytes(0, v);
  }

  bool hasTransaction() => $_has(0);
  void clearTransaction() => clearField(1);

  String get projectId => $_getS(1, '');
  set projectId(String v) {
    $_setString(1, v);
  }

  bool hasProjectId() => $_has(1);
  void clearProjectId() => clearField(8);
}

class RollbackResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('RollbackResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..hasRequiredFields = false;

  RollbackResponse() : super();
  RollbackResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  RollbackResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  RollbackResponse clone() => new RollbackResponse()..mergeFromMessage(this);
  RollbackResponse copyWith(void Function(RollbackResponse) updates) =>
      super.copyWith((message) => updates(message as RollbackResponse));
  $pb.BuilderInfo get info_ => _i;
  static RollbackResponse create() => new RollbackResponse();
  static $pb.PbList<RollbackResponse> createRepeated() =>
      new $pb.PbList<RollbackResponse>();
  static RollbackResponse getDefault() =>
      _defaultInstance ??= create()..freeze();
  static RollbackResponse _defaultInstance;
  static void $checkItem(RollbackResponse v) {
    if (v is! RollbackResponse) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }
}

class CommitRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('CommitRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<List<int>>(1, 'transaction', $pb.PbFieldType.OY)
    ..e<CommitRequest_Mode>(
        5,
        'mode',
        $pb.PbFieldType.OE,
        CommitRequest_Mode.MODE_UNSPECIFIED,
        CommitRequest_Mode.valueOf,
        CommitRequest_Mode.values)
    ..pp<Mutation>(6, 'mutations', $pb.PbFieldType.PM, Mutation.$checkItem,
        Mutation.create)
    ..aOS(8, 'projectId')
    ..hasRequiredFields = false;

  CommitRequest() : super();
  CommitRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  CommitRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  CommitRequest clone() => new CommitRequest()..mergeFromMessage(this);
  CommitRequest copyWith(void Function(CommitRequest) updates) =>
      super.copyWith((message) => updates(message as CommitRequest));
  $pb.BuilderInfo get info_ => _i;
  static CommitRequest create() => new CommitRequest();
  static $pb.PbList<CommitRequest> createRepeated() =>
      new $pb.PbList<CommitRequest>();
  static CommitRequest getDefault() => _defaultInstance ??= create()..freeze();
  static CommitRequest _defaultInstance;
  static void $checkItem(CommitRequest v) {
    if (v is! CommitRequest) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<int> get transaction => $_getN(0);
  set transaction(List<int> v) {
    $_setBytes(0, v);
  }

  bool hasTransaction() => $_has(0);
  void clearTransaction() => clearField(1);

  CommitRequest_Mode get mode => $_getN(1);
  set mode(CommitRequest_Mode v) {
    setField(5, v);
  }

  bool hasMode() => $_has(1);
  void clearMode() => clearField(5);

  List<Mutation> get mutations => $_getList(2);

  String get projectId => $_getS(3, '');
  set projectId(String v) {
    $_setString(3, v);
  }

  bool hasProjectId() => $_has(3);
  void clearProjectId() => clearField(8);
}

class CommitResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('CommitResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<MutationResult>(3, 'mutationResults', $pb.PbFieldType.PM,
        MutationResult.$checkItem, MutationResult.create)
    ..a<int>(4, 'indexUpdates', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  CommitResponse() : super();
  CommitResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  CommitResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  CommitResponse clone() => new CommitResponse()..mergeFromMessage(this);
  CommitResponse copyWith(void Function(CommitResponse) updates) =>
      super.copyWith((message) => updates(message as CommitResponse));
  $pb.BuilderInfo get info_ => _i;
  static CommitResponse create() => new CommitResponse();
  static $pb.PbList<CommitResponse> createRepeated() =>
      new $pb.PbList<CommitResponse>();
  static CommitResponse getDefault() => _defaultInstance ??= create()..freeze();
  static CommitResponse _defaultInstance;
  static void $checkItem(CommitResponse v) {
    if (v is! CommitResponse) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<MutationResult> get mutationResults => $_getList(0);

  int get indexUpdates => $_get(1, 0);
  set indexUpdates(int v) {
    $_setSignedInt32(1, v);
  }

  bool hasIndexUpdates() => $_has(1);
  void clearIndexUpdates() => clearField(4);
}

class AllocateIdsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('AllocateIdsRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<$0.Key>(
        1, 'keys', $pb.PbFieldType.PM, $0.Key.$checkItem, $0.Key.create)
    ..aOS(8, 'projectId')
    ..hasRequiredFields = false;

  AllocateIdsRequest() : super();
  AllocateIdsRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  AllocateIdsRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  AllocateIdsRequest clone() =>
      new AllocateIdsRequest()..mergeFromMessage(this);
  AllocateIdsRequest copyWith(void Function(AllocateIdsRequest) updates) =>
      super.copyWith((message) => updates(message as AllocateIdsRequest));
  $pb.BuilderInfo get info_ => _i;
  static AllocateIdsRequest create() => new AllocateIdsRequest();
  static $pb.PbList<AllocateIdsRequest> createRepeated() =>
      new $pb.PbList<AllocateIdsRequest>();
  static AllocateIdsRequest getDefault() =>
      _defaultInstance ??= create()..freeze();
  static AllocateIdsRequest _defaultInstance;
  static void $checkItem(AllocateIdsRequest v) {
    if (v is! AllocateIdsRequest)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<$0.Key> get keys => $_getList(0);

  String get projectId => $_getS(1, '');
  set projectId(String v) {
    $_setString(1, v);
  }

  bool hasProjectId() => $_has(1);
  void clearProjectId() => clearField(8);
}

class AllocateIdsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('AllocateIdsResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<$0.Key>(
        1, 'keys', $pb.PbFieldType.PM, $0.Key.$checkItem, $0.Key.create)
    ..hasRequiredFields = false;

  AllocateIdsResponse() : super();
  AllocateIdsResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  AllocateIdsResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  AllocateIdsResponse clone() =>
      new AllocateIdsResponse()..mergeFromMessage(this);
  AllocateIdsResponse copyWith(void Function(AllocateIdsResponse) updates) =>
      super.copyWith((message) => updates(message as AllocateIdsResponse));
  $pb.BuilderInfo get info_ => _i;
  static AllocateIdsResponse create() => new AllocateIdsResponse();
  static $pb.PbList<AllocateIdsResponse> createRepeated() =>
      new $pb.PbList<AllocateIdsResponse>();
  static AllocateIdsResponse getDefault() =>
      _defaultInstance ??= create()..freeze();
  static AllocateIdsResponse _defaultInstance;
  static void $checkItem(AllocateIdsResponse v) {
    if (v is! AllocateIdsResponse)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<$0.Key> get keys => $_getList(0);
}

class ReserveIdsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ReserveIdsRequest',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<$0.Key>(
        1, 'keys', $pb.PbFieldType.PM, $0.Key.$checkItem, $0.Key.create)
    ..aOS(8, 'projectId')
    ..aOS(9, 'databaseId')
    ..hasRequiredFields = false;

  ReserveIdsRequest() : super();
  ReserveIdsRequest.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ReserveIdsRequest.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ReserveIdsRequest clone() => new ReserveIdsRequest()..mergeFromMessage(this);
  ReserveIdsRequest copyWith(void Function(ReserveIdsRequest) updates) =>
      super.copyWith((message) => updates(message as ReserveIdsRequest));
  $pb.BuilderInfo get info_ => _i;
  static ReserveIdsRequest create() => new ReserveIdsRequest();
  static $pb.PbList<ReserveIdsRequest> createRepeated() =>
      new $pb.PbList<ReserveIdsRequest>();
  static ReserveIdsRequest getDefault() =>
      _defaultInstance ??= create()..freeze();
  static ReserveIdsRequest _defaultInstance;
  static void $checkItem(ReserveIdsRequest v) {
    if (v is! ReserveIdsRequest)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<$0.Key> get keys => $_getList(0);

  String get projectId => $_getS(1, '');
  set projectId(String v) {
    $_setString(1, v);
  }

  bool hasProjectId() => $_has(1);
  void clearProjectId() => clearField(8);

  String get databaseId => $_getS(2, '');
  set databaseId(String v) {
    $_setString(2, v);
  }

  bool hasDatabaseId() => $_has(2);
  void clearDatabaseId() => clearField(9);
}

class ReserveIdsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ReserveIdsResponse',
      package: const $pb.PackageName('google.datastore.v1'))
    ..hasRequiredFields = false;

  ReserveIdsResponse() : super();
  ReserveIdsResponse.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ReserveIdsResponse.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ReserveIdsResponse clone() =>
      new ReserveIdsResponse()..mergeFromMessage(this);
  ReserveIdsResponse copyWith(void Function(ReserveIdsResponse) updates) =>
      super.copyWith((message) => updates(message as ReserveIdsResponse));
  $pb.BuilderInfo get info_ => _i;
  static ReserveIdsResponse create() => new ReserveIdsResponse();
  static $pb.PbList<ReserveIdsResponse> createRepeated() =>
      new $pb.PbList<ReserveIdsResponse>();
  static ReserveIdsResponse getDefault() =>
      _defaultInstance ??= create()..freeze();
  static ReserveIdsResponse _defaultInstance;
  static void $checkItem(ReserveIdsResponse v) {
    if (v is! ReserveIdsResponse)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }
}

class Mutation extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Mutation',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<$0.Entity>(
        4, 'insert', $pb.PbFieldType.OM, $0.Entity.getDefault, $0.Entity.create)
    ..a<$0.Entity>(
        5, 'update', $pb.PbFieldType.OM, $0.Entity.getDefault, $0.Entity.create)
    ..a<$0.Entity>(
        6, 'upsert', $pb.PbFieldType.OM, $0.Entity.getDefault, $0.Entity.create)
    ..a<$0.Key>(
        7, 'delete', $pb.PbFieldType.OM, $0.Key.getDefault, $0.Key.create)
    ..aInt64(8, 'baseVersion')
    ..hasRequiredFields = false;

  Mutation() : super();
  Mutation.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Mutation.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Mutation clone() => new Mutation()..mergeFromMessage(this);
  Mutation copyWith(void Function(Mutation) updates) =>
      super.copyWith((message) => updates(message as Mutation));
  $pb.BuilderInfo get info_ => _i;
  static Mutation create() => new Mutation();
  static $pb.PbList<Mutation> createRepeated() => new $pb.PbList<Mutation>();
  static Mutation getDefault() => _defaultInstance ??= create()..freeze();
  static Mutation _defaultInstance;
  static void $checkItem(Mutation v) {
    if (v is! Mutation) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  $0.Entity get insert => $_getN(0);
  set insert($0.Entity v) {
    setField(4, v);
  }

  bool hasInsert() => $_has(0);
  void clearInsert() => clearField(4);

  $0.Entity get update => $_getN(1);
  set update($0.Entity v) {
    setField(5, v);
  }

  bool hasUpdate() => $_has(1);
  void clearUpdate() => clearField(5);

  $0.Entity get upsert => $_getN(2);
  set upsert($0.Entity v) {
    setField(6, v);
  }

  bool hasUpsert() => $_has(2);
  void clearUpsert() => clearField(6);

  $0.Key get delete => $_getN(3);
  set delete($0.Key v) {
    setField(7, v);
  }

  bool hasDelete() => $_has(3);
  void clearDelete() => clearField(7);

  Int64 get baseVersion => $_getI64(4);
  set baseVersion(Int64 v) {
    $_setInt64(4, v);
  }

  bool hasBaseVersion() => $_has(4);
  void clearBaseVersion() => clearField(8);
}

class MutationResult extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('MutationResult',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<$0.Key>(3, 'key', $pb.PbFieldType.OM, $0.Key.getDefault, $0.Key.create)
    ..aInt64(4, 'version')
    ..aOB(5, 'conflictDetected')
    ..hasRequiredFields = false;

  MutationResult() : super();
  MutationResult.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MutationResult.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MutationResult clone() => new MutationResult()..mergeFromMessage(this);
  MutationResult copyWith(void Function(MutationResult) updates) =>
      super.copyWith((message) => updates(message as MutationResult));
  $pb.BuilderInfo get info_ => _i;
  static MutationResult create() => new MutationResult();
  static $pb.PbList<MutationResult> createRepeated() =>
      new $pb.PbList<MutationResult>();
  static MutationResult getDefault() => _defaultInstance ??= create()..freeze();
  static MutationResult _defaultInstance;
  static void $checkItem(MutationResult v) {
    if (v is! MutationResult) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  $0.Key get key => $_getN(0);
  set key($0.Key v) {
    setField(3, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(3);

  Int64 get version => $_getI64(1);
  set version(Int64 v) {
    $_setInt64(1, v);
  }

  bool hasVersion() => $_has(1);
  void clearVersion() => clearField(4);

  bool get conflictDetected => $_get(2, false);
  set conflictDetected(bool v) {
    $_setBool(2, v);
  }

  bool hasConflictDetected() => $_has(2);
  void clearConflictDetected() => clearField(5);
}

class ReadOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ReadOptions',
      package: const $pb.PackageName('google.datastore.v1'))
    ..e<ReadOptions_ReadConsistency>(
        1,
        'readConsistency',
        $pb.PbFieldType.OE,
        ReadOptions_ReadConsistency.READ_CONSISTENCY_UNSPECIFIED,
        ReadOptions_ReadConsistency.valueOf,
        ReadOptions_ReadConsistency.values)
    ..a<List<int>>(2, 'transaction', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  ReadOptions() : super();
  ReadOptions.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ReadOptions.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ReadOptions clone() => new ReadOptions()..mergeFromMessage(this);
  ReadOptions copyWith(void Function(ReadOptions) updates) =>
      super.copyWith((message) => updates(message as ReadOptions));
  $pb.BuilderInfo get info_ => _i;
  static ReadOptions create() => new ReadOptions();
  static $pb.PbList<ReadOptions> createRepeated() =>
      new $pb.PbList<ReadOptions>();
  static ReadOptions getDefault() => _defaultInstance ??= create()..freeze();
  static ReadOptions _defaultInstance;
  static void $checkItem(ReadOptions v) {
    if (v is! ReadOptions) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  ReadOptions_ReadConsistency get readConsistency => $_getN(0);
  set readConsistency(ReadOptions_ReadConsistency v) {
    setField(1, v);
  }

  bool hasReadConsistency() => $_has(0);
  void clearReadConsistency() => clearField(1);

  List<int> get transaction => $_getN(1);
  set transaction(List<int> v) {
    $_setBytes(1, v);
  }

  bool hasTransaction() => $_has(1);
  void clearTransaction() => clearField(2);
}

class TransactionOptions_ReadWrite extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'TransactionOptions.ReadWrite',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<List<int>>(1, 'previousTransaction', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  TransactionOptions_ReadWrite() : super();
  TransactionOptions_ReadWrite.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  TransactionOptions_ReadWrite.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  TransactionOptions_ReadWrite clone() =>
      new TransactionOptions_ReadWrite()..mergeFromMessage(this);
  TransactionOptions_ReadWrite copyWith(
          void Function(TransactionOptions_ReadWrite) updates) =>
      super.copyWith(
          (message) => updates(message as TransactionOptions_ReadWrite));
  $pb.BuilderInfo get info_ => _i;
  static TransactionOptions_ReadWrite create() =>
      new TransactionOptions_ReadWrite();
  static $pb.PbList<TransactionOptions_ReadWrite> createRepeated() =>
      new $pb.PbList<TransactionOptions_ReadWrite>();
  static TransactionOptions_ReadWrite getDefault() =>
      _defaultInstance ??= create()..freeze();
  static TransactionOptions_ReadWrite _defaultInstance;
  static void $checkItem(TransactionOptions_ReadWrite v) {
    if (v is! TransactionOptions_ReadWrite)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<int> get previousTransaction => $_getN(0);
  set previousTransaction(List<int> v) {
    $_setBytes(0, v);
  }

  bool hasPreviousTransaction() => $_has(0);
  void clearPreviousTransaction() => clearField(1);
}

class TransactionOptions_ReadOnly extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'TransactionOptions.ReadOnly',
      package: const $pb.PackageName('google.datastore.v1'))
    ..hasRequiredFields = false;

  TransactionOptions_ReadOnly() : super();
  TransactionOptions_ReadOnly.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  TransactionOptions_ReadOnly.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  TransactionOptions_ReadOnly clone() =>
      new TransactionOptions_ReadOnly()..mergeFromMessage(this);
  TransactionOptions_ReadOnly copyWith(
          void Function(TransactionOptions_ReadOnly) updates) =>
      super.copyWith(
          (message) => updates(message as TransactionOptions_ReadOnly));
  $pb.BuilderInfo get info_ => _i;
  static TransactionOptions_ReadOnly create() =>
      new TransactionOptions_ReadOnly();
  static $pb.PbList<TransactionOptions_ReadOnly> createRepeated() =>
      new $pb.PbList<TransactionOptions_ReadOnly>();
  static TransactionOptions_ReadOnly getDefault() =>
      _defaultInstance ??= create()..freeze();
  static TransactionOptions_ReadOnly _defaultInstance;
  static void $checkItem(TransactionOptions_ReadOnly v) {
    if (v is! TransactionOptions_ReadOnly)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }
}

class TransactionOptions extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('TransactionOptions',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<TransactionOptions_ReadWrite>(
        1,
        'readWrite',
        $pb.PbFieldType.OM,
        TransactionOptions_ReadWrite.getDefault,
        TransactionOptions_ReadWrite.create)
    ..a<TransactionOptions_ReadOnly>(
        2,
        'readOnly',
        $pb.PbFieldType.OM,
        TransactionOptions_ReadOnly.getDefault,
        TransactionOptions_ReadOnly.create)
    ..hasRequiredFields = false;

  TransactionOptions() : super();
  TransactionOptions.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  TransactionOptions.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  TransactionOptions clone() =>
      new TransactionOptions()..mergeFromMessage(this);
  TransactionOptions copyWith(void Function(TransactionOptions) updates) =>
      super.copyWith((message) => updates(message as TransactionOptions));
  $pb.BuilderInfo get info_ => _i;
  static TransactionOptions create() => new TransactionOptions();
  static $pb.PbList<TransactionOptions> createRepeated() =>
      new $pb.PbList<TransactionOptions>();
  static TransactionOptions getDefault() =>
      _defaultInstance ??= create()..freeze();
  static TransactionOptions _defaultInstance;
  static void $checkItem(TransactionOptions v) {
    if (v is! TransactionOptions)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  TransactionOptions_ReadWrite get readWrite => $_getN(0);
  set readWrite(TransactionOptions_ReadWrite v) {
    setField(1, v);
  }

  bool hasReadWrite() => $_has(0);
  void clearReadWrite() => clearField(1);

  TransactionOptions_ReadOnly get readOnly => $_getN(1);
  set readOnly(TransactionOptions_ReadOnly v) {
    setField(2, v);
  }

  bool hasReadOnly() => $_has(1);
  void clearReadOnly() => clearField(2);
}
