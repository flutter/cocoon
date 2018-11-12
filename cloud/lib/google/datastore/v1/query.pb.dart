///
//  Generated code. Do not modify.
//  source: google/datastore/v1/query.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'entity.pb.dart' as $0;
import '../../protobuf/wrappers.pb.dart' as $1;

import 'query.pbenum.dart';

export 'query.pbenum.dart';

class EntityResult extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('EntityResult',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<$0.Entity>(
        1, 'entity', $pb.PbFieldType.OM, $0.Entity.getDefault, $0.Entity.create)
    ..a<List<int>>(3, 'cursor', $pb.PbFieldType.OY)
    ..aInt64(4, 'version')
    ..hasRequiredFields = false;

  EntityResult() : super();
  EntityResult.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  EntityResult.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  EntityResult clone() => new EntityResult()..mergeFromMessage(this);
  EntityResult copyWith(void Function(EntityResult) updates) =>
      super.copyWith((message) => updates(message as EntityResult));
  $pb.BuilderInfo get info_ => _i;
  static EntityResult create() => new EntityResult();
  static $pb.PbList<EntityResult> createRepeated() =>
      new $pb.PbList<EntityResult>();
  static EntityResult getDefault() => _defaultInstance ??= create()..freeze();
  static EntityResult _defaultInstance;
  static void $checkItem(EntityResult v) {
    if (v is! EntityResult) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  $0.Entity get entity => $_getN(0);
  set entity($0.Entity v) {
    setField(1, v);
  }

  bool hasEntity() => $_has(0);
  void clearEntity() => clearField(1);

  List<int> get cursor => $_getN(1);
  set cursor(List<int> v) {
    $_setBytes(1, v);
  }

  bool hasCursor() => $_has(1);
  void clearCursor() => clearField(3);

  Int64 get version => $_getI64(2);
  set version(Int64 v) {
    $_setInt64(2, v);
  }

  bool hasVersion() => $_has(2);
  void clearVersion() => clearField(4);
}

class Query extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Query',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<Projection>(2, 'projection', $pb.PbFieldType.PM, Projection.$checkItem,
        Projection.create)
    ..pp<KindExpression>(3, 'kind', $pb.PbFieldType.PM,
        KindExpression.$checkItem, KindExpression.create)
    ..a<Filter>(
        4, 'filter', $pb.PbFieldType.OM, Filter.getDefault, Filter.create)
    ..pp<PropertyOrder>(5, 'order', $pb.PbFieldType.PM,
        PropertyOrder.$checkItem, PropertyOrder.create)
    ..pp<PropertyReference>(6, 'distinctOn', $pb.PbFieldType.PM,
        PropertyReference.$checkItem, PropertyReference.create)
    ..a<List<int>>(7, 'startCursor', $pb.PbFieldType.OY)
    ..a<List<int>>(8, 'endCursor', $pb.PbFieldType.OY)
    ..a<int>(10, 'offset', $pb.PbFieldType.O3)
    ..a<$1.Int32Value>(12, 'limit', $pb.PbFieldType.OM,
        $1.Int32Value.getDefault, $1.Int32Value.create)
    ..hasRequiredFields = false;

  Query() : super();
  Query.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Query.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Query clone() => new Query()..mergeFromMessage(this);
  Query copyWith(void Function(Query) updates) =>
      super.copyWith((message) => updates(message as Query));
  $pb.BuilderInfo get info_ => _i;
  static Query create() => new Query();
  static $pb.PbList<Query> createRepeated() => new $pb.PbList<Query>();
  static Query getDefault() => _defaultInstance ??= create()..freeze();
  static Query _defaultInstance;
  static void $checkItem(Query v) {
    if (v is! Query) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<Projection> get projection => $_getList(0);

  List<KindExpression> get kind => $_getList(1);

  Filter get filter => $_getN(2);
  set filter(Filter v) {
    setField(4, v);
  }

  bool hasFilter() => $_has(2);
  void clearFilter() => clearField(4);

  List<PropertyOrder> get order => $_getList(3);

  List<PropertyReference> get distinctOn => $_getList(4);

  List<int> get startCursor => $_getN(5);
  set startCursor(List<int> v) {
    $_setBytes(5, v);
  }

  bool hasStartCursor() => $_has(5);
  void clearStartCursor() => clearField(7);

  List<int> get endCursor => $_getN(6);
  set endCursor(List<int> v) {
    $_setBytes(6, v);
  }

  bool hasEndCursor() => $_has(6);
  void clearEndCursor() => clearField(8);

  int get offset => $_get(7, 0);
  set offset(int v) {
    $_setSignedInt32(7, v);
  }

  bool hasOffset() => $_has(7);
  void clearOffset() => clearField(10);

  $1.Int32Value get limit => $_getN(8);
  set limit($1.Int32Value v) {
    setField(12, v);
  }

  bool hasLimit() => $_has(8);
  void clearLimit() => clearField(12);
}

class KindExpression extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('KindExpression',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(1, 'name')
    ..hasRequiredFields = false;

  KindExpression() : super();
  KindExpression.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  KindExpression.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  KindExpression clone() => new KindExpression()..mergeFromMessage(this);
  KindExpression copyWith(void Function(KindExpression) updates) =>
      super.copyWith((message) => updates(message as KindExpression));
  $pb.BuilderInfo get info_ => _i;
  static KindExpression create() => new KindExpression();
  static $pb.PbList<KindExpression> createRepeated() =>
      new $pb.PbList<KindExpression>();
  static KindExpression getDefault() => _defaultInstance ??= create()..freeze();
  static KindExpression _defaultInstance;
  static void $checkItem(KindExpression v) {
    if (v is! KindExpression) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get name => $_getS(0, '');
  set name(String v) {
    $_setString(0, v);
  }

  bool hasName() => $_has(0);
  void clearName() => clearField(1);
}

class PropertyReference extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('PropertyReference',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(2, 'name')
    ..hasRequiredFields = false;

  PropertyReference() : super();
  PropertyReference.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  PropertyReference.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  PropertyReference clone() => new PropertyReference()..mergeFromMessage(this);
  PropertyReference copyWith(void Function(PropertyReference) updates) =>
      super.copyWith((message) => updates(message as PropertyReference));
  $pb.BuilderInfo get info_ => _i;
  static PropertyReference create() => new PropertyReference();
  static $pb.PbList<PropertyReference> createRepeated() =>
      new $pb.PbList<PropertyReference>();
  static PropertyReference getDefault() =>
      _defaultInstance ??= create()..freeze();
  static PropertyReference _defaultInstance;
  static void $checkItem(PropertyReference v) {
    if (v is! PropertyReference)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get name => $_getS(0, '');
  set name(String v) {
    $_setString(0, v);
  }

  bool hasName() => $_has(0);
  void clearName() => clearField(2);
}

class Projection extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Projection',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<PropertyReference>(1, 'property', $pb.PbFieldType.OM,
        PropertyReference.getDefault, PropertyReference.create)
    ..hasRequiredFields = false;

  Projection() : super();
  Projection.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Projection.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Projection clone() => new Projection()..mergeFromMessage(this);
  Projection copyWith(void Function(Projection) updates) =>
      super.copyWith((message) => updates(message as Projection));
  $pb.BuilderInfo get info_ => _i;
  static Projection create() => new Projection();
  static $pb.PbList<Projection> createRepeated() =>
      new $pb.PbList<Projection>();
  static Projection getDefault() => _defaultInstance ??= create()..freeze();
  static Projection _defaultInstance;
  static void $checkItem(Projection v) {
    if (v is! Projection) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  PropertyReference get property => $_getN(0);
  set property(PropertyReference v) {
    setField(1, v);
  }

  bool hasProperty() => $_has(0);
  void clearProperty() => clearField(1);
}

class PropertyOrder extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('PropertyOrder',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<PropertyReference>(1, 'property', $pb.PbFieldType.OM,
        PropertyReference.getDefault, PropertyReference.create)
    ..e<PropertyOrder_Direction>(
        2,
        'direction',
        $pb.PbFieldType.OE,
        PropertyOrder_Direction.DIRECTION_UNSPECIFIED,
        PropertyOrder_Direction.valueOf,
        PropertyOrder_Direction.values)
    ..hasRequiredFields = false;

  PropertyOrder() : super();
  PropertyOrder.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  PropertyOrder.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  PropertyOrder clone() => new PropertyOrder()..mergeFromMessage(this);
  PropertyOrder copyWith(void Function(PropertyOrder) updates) =>
      super.copyWith((message) => updates(message as PropertyOrder));
  $pb.BuilderInfo get info_ => _i;
  static PropertyOrder create() => new PropertyOrder();
  static $pb.PbList<PropertyOrder> createRepeated() =>
      new $pb.PbList<PropertyOrder>();
  static PropertyOrder getDefault() => _defaultInstance ??= create()..freeze();
  static PropertyOrder _defaultInstance;
  static void $checkItem(PropertyOrder v) {
    if (v is! PropertyOrder) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  PropertyReference get property => $_getN(0);
  set property(PropertyReference v) {
    setField(1, v);
  }

  bool hasProperty() => $_has(0);
  void clearProperty() => clearField(1);

  PropertyOrder_Direction get direction => $_getN(1);
  set direction(PropertyOrder_Direction v) {
    setField(2, v);
  }

  bool hasDirection() => $_has(1);
  void clearDirection() => clearField(2);
}

class Filter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Filter',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<CompositeFilter>(1, 'compositeFilter', $pb.PbFieldType.OM,
        CompositeFilter.getDefault, CompositeFilter.create)
    ..a<PropertyFilter>(2, 'propertyFilter', $pb.PbFieldType.OM,
        PropertyFilter.getDefault, PropertyFilter.create)
    ..hasRequiredFields = false;

  Filter() : super();
  Filter.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Filter.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Filter clone() => new Filter()..mergeFromMessage(this);
  Filter copyWith(void Function(Filter) updates) =>
      super.copyWith((message) => updates(message as Filter));
  $pb.BuilderInfo get info_ => _i;
  static Filter create() => new Filter();
  static $pb.PbList<Filter> createRepeated() => new $pb.PbList<Filter>();
  static Filter getDefault() => _defaultInstance ??= create()..freeze();
  static Filter _defaultInstance;
  static void $checkItem(Filter v) {
    if (v is! Filter) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  CompositeFilter get compositeFilter => $_getN(0);
  set compositeFilter(CompositeFilter v) {
    setField(1, v);
  }

  bool hasCompositeFilter() => $_has(0);
  void clearCompositeFilter() => clearField(1);

  PropertyFilter get propertyFilter => $_getN(1);
  set propertyFilter(PropertyFilter v) {
    setField(2, v);
  }

  bool hasPropertyFilter() => $_has(1);
  void clearPropertyFilter() => clearField(2);
}

class CompositeFilter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('CompositeFilter',
      package: const $pb.PackageName('google.datastore.v1'))
    ..e<CompositeFilter_Operator>(
        1,
        'op',
        $pb.PbFieldType.OE,
        CompositeFilter_Operator.OPERATOR_UNSPECIFIED,
        CompositeFilter_Operator.valueOf,
        CompositeFilter_Operator.values)
    ..pp<Filter>(
        2, 'filters', $pb.PbFieldType.PM, Filter.$checkItem, Filter.create)
    ..hasRequiredFields = false;

  CompositeFilter() : super();
  CompositeFilter.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  CompositeFilter.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  CompositeFilter clone() => new CompositeFilter()..mergeFromMessage(this);
  CompositeFilter copyWith(void Function(CompositeFilter) updates) =>
      super.copyWith((message) => updates(message as CompositeFilter));
  $pb.BuilderInfo get info_ => _i;
  static CompositeFilter create() => new CompositeFilter();
  static $pb.PbList<CompositeFilter> createRepeated() =>
      new $pb.PbList<CompositeFilter>();
  static CompositeFilter getDefault() =>
      _defaultInstance ??= create()..freeze();
  static CompositeFilter _defaultInstance;
  static void $checkItem(CompositeFilter v) {
    if (v is! CompositeFilter) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  CompositeFilter_Operator get op => $_getN(0);
  set op(CompositeFilter_Operator v) {
    setField(1, v);
  }

  bool hasOp() => $_has(0);
  void clearOp() => clearField(1);

  List<Filter> get filters => $_getList(1);
}

class PropertyFilter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('PropertyFilter',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<PropertyReference>(1, 'property', $pb.PbFieldType.OM,
        PropertyReference.getDefault, PropertyReference.create)
    ..e<PropertyFilter_Operator>(
        2,
        'op',
        $pb.PbFieldType.OE,
        PropertyFilter_Operator.OPERATOR_UNSPECIFIED,
        PropertyFilter_Operator.valueOf,
        PropertyFilter_Operator.values)
    ..a<$0.Value>(
        3, 'value', $pb.PbFieldType.OM, $0.Value.getDefault, $0.Value.create)
    ..hasRequiredFields = false;

  PropertyFilter() : super();
  PropertyFilter.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  PropertyFilter.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  PropertyFilter clone() => new PropertyFilter()..mergeFromMessage(this);
  PropertyFilter copyWith(void Function(PropertyFilter) updates) =>
      super.copyWith((message) => updates(message as PropertyFilter));
  $pb.BuilderInfo get info_ => _i;
  static PropertyFilter create() => new PropertyFilter();
  static $pb.PbList<PropertyFilter> createRepeated() =>
      new $pb.PbList<PropertyFilter>();
  static PropertyFilter getDefault() => _defaultInstance ??= create()..freeze();
  static PropertyFilter _defaultInstance;
  static void $checkItem(PropertyFilter v) {
    if (v is! PropertyFilter) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  PropertyReference get property => $_getN(0);
  set property(PropertyReference v) {
    setField(1, v);
  }

  bool hasProperty() => $_has(0);
  void clearProperty() => clearField(1);

  PropertyFilter_Operator get op => $_getN(1);
  set op(PropertyFilter_Operator v) {
    setField(2, v);
  }

  bool hasOp() => $_has(1);
  void clearOp() => clearField(2);

  $0.Value get value => $_getN(2);
  set value($0.Value v) {
    setField(3, v);
  }

  bool hasValue() => $_has(2);
  void clearValue() => clearField(3);
}

class GqlQuery_NamedBindingsEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'GqlQuery.NamedBindingsEntry',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(1, 'key')
    ..a<GqlQueryParameter>(2, 'value', $pb.PbFieldType.OM,
        GqlQueryParameter.getDefault, GqlQueryParameter.create)
    ..hasRequiredFields = false;

  GqlQuery_NamedBindingsEntry() : super();
  GqlQuery_NamedBindingsEntry.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  GqlQuery_NamedBindingsEntry.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  GqlQuery_NamedBindingsEntry clone() =>
      new GqlQuery_NamedBindingsEntry()..mergeFromMessage(this);
  GqlQuery_NamedBindingsEntry copyWith(
          void Function(GqlQuery_NamedBindingsEntry) updates) =>
      super.copyWith(
          (message) => updates(message as GqlQuery_NamedBindingsEntry));
  $pb.BuilderInfo get info_ => _i;
  static GqlQuery_NamedBindingsEntry create() =>
      new GqlQuery_NamedBindingsEntry();
  static $pb.PbList<GqlQuery_NamedBindingsEntry> createRepeated() =>
      new $pb.PbList<GqlQuery_NamedBindingsEntry>();
  static GqlQuery_NamedBindingsEntry getDefault() =>
      _defaultInstance ??= create()..freeze();
  static GqlQuery_NamedBindingsEntry _defaultInstance;
  static void $checkItem(GqlQuery_NamedBindingsEntry v) {
    if (v is! GqlQuery_NamedBindingsEntry)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get key => $_getS(0, '');
  set key(String v) {
    $_setString(0, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  GqlQueryParameter get value => $_getN(1);
  set value(GqlQueryParameter v) {
    setField(2, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class GqlQuery extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('GqlQuery',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(1, 'queryString')
    ..aOB(2, 'allowLiterals')
    ..pp<GqlQueryParameter>(4, 'positionalBindings', $pb.PbFieldType.PM,
        GqlQueryParameter.$checkItem, GqlQueryParameter.create)
    ..pp<GqlQuery_NamedBindingsEntry>(
        5,
        'namedBindings',
        $pb.PbFieldType.PM,
        GqlQuery_NamedBindingsEntry.$checkItem,
        GqlQuery_NamedBindingsEntry.create)
    ..hasRequiredFields = false;

  GqlQuery() : super();
  GqlQuery.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  GqlQuery.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  GqlQuery clone() => new GqlQuery()..mergeFromMessage(this);
  GqlQuery copyWith(void Function(GqlQuery) updates) =>
      super.copyWith((message) => updates(message as GqlQuery));
  $pb.BuilderInfo get info_ => _i;
  static GqlQuery create() => new GqlQuery();
  static $pb.PbList<GqlQuery> createRepeated() => new $pb.PbList<GqlQuery>();
  static GqlQuery getDefault() => _defaultInstance ??= create()..freeze();
  static GqlQuery _defaultInstance;
  static void $checkItem(GqlQuery v) {
    if (v is! GqlQuery) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get queryString => $_getS(0, '');
  set queryString(String v) {
    $_setString(0, v);
  }

  bool hasQueryString() => $_has(0);
  void clearQueryString() => clearField(1);

  bool get allowLiterals => $_get(1, false);
  set allowLiterals(bool v) {
    $_setBool(1, v);
  }

  bool hasAllowLiterals() => $_has(1);
  void clearAllowLiterals() => clearField(2);

  List<GqlQueryParameter> get positionalBindings => $_getList(2);

  List<GqlQuery_NamedBindingsEntry> get namedBindings => $_getList(3);
}

class GqlQueryParameter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('GqlQueryParameter',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<$0.Value>(
        2, 'value', $pb.PbFieldType.OM, $0.Value.getDefault, $0.Value.create)
    ..a<List<int>>(3, 'cursor', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  GqlQueryParameter() : super();
  GqlQueryParameter.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  GqlQueryParameter.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  GqlQueryParameter clone() => new GqlQueryParameter()..mergeFromMessage(this);
  GqlQueryParameter copyWith(void Function(GqlQueryParameter) updates) =>
      super.copyWith((message) => updates(message as GqlQueryParameter));
  $pb.BuilderInfo get info_ => _i;
  static GqlQueryParameter create() => new GqlQueryParameter();
  static $pb.PbList<GqlQueryParameter> createRepeated() =>
      new $pb.PbList<GqlQueryParameter>();
  static GqlQueryParameter getDefault() =>
      _defaultInstance ??= create()..freeze();
  static GqlQueryParameter _defaultInstance;
  static void $checkItem(GqlQueryParameter v) {
    if (v is! GqlQueryParameter)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  $0.Value get value => $_getN(0);
  set value($0.Value v) {
    setField(2, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(2);

  List<int> get cursor => $_getN(1);
  set cursor(List<int> v) {
    $_setBytes(1, v);
  }

  bool hasCursor() => $_has(1);
  void clearCursor() => clearField(3);
}

class QueryResultBatch extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('QueryResultBatch',
      package: const $pb.PackageName('google.datastore.v1'))
    ..e<EntityResult_ResultType>(
        1,
        'entityResultType',
        $pb.PbFieldType.OE,
        EntityResult_ResultType.RESULT_TYPE_UNSPECIFIED,
        EntityResult_ResultType.valueOf,
        EntityResult_ResultType.values)
    ..pp<EntityResult>(2, 'entityResults', $pb.PbFieldType.PM,
        EntityResult.$checkItem, EntityResult.create)
    ..a<List<int>>(3, 'skippedCursor', $pb.PbFieldType.OY)
    ..a<List<int>>(4, 'endCursor', $pb.PbFieldType.OY)
    ..e<QueryResultBatch_MoreResultsType>(
        5,
        'moreResults',
        $pb.PbFieldType.OE,
        QueryResultBatch_MoreResultsType.MORE_RESULTS_TYPE_UNSPECIFIED,
        QueryResultBatch_MoreResultsType.valueOf,
        QueryResultBatch_MoreResultsType.values)
    ..a<int>(6, 'skippedResults', $pb.PbFieldType.O3)
    ..aInt64(7, 'snapshotVersion')
    ..hasRequiredFields = false;

  QueryResultBatch() : super();
  QueryResultBatch.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  QueryResultBatch.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  QueryResultBatch clone() => new QueryResultBatch()..mergeFromMessage(this);
  QueryResultBatch copyWith(void Function(QueryResultBatch) updates) =>
      super.copyWith((message) => updates(message as QueryResultBatch));
  $pb.BuilderInfo get info_ => _i;
  static QueryResultBatch create() => new QueryResultBatch();
  static $pb.PbList<QueryResultBatch> createRepeated() =>
      new $pb.PbList<QueryResultBatch>();
  static QueryResultBatch getDefault() =>
      _defaultInstance ??= create()..freeze();
  static QueryResultBatch _defaultInstance;
  static void $checkItem(QueryResultBatch v) {
    if (v is! QueryResultBatch) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  EntityResult_ResultType get entityResultType => $_getN(0);
  set entityResultType(EntityResult_ResultType v) {
    setField(1, v);
  }

  bool hasEntityResultType() => $_has(0);
  void clearEntityResultType() => clearField(1);

  List<EntityResult> get entityResults => $_getList(1);

  List<int> get skippedCursor => $_getN(2);
  set skippedCursor(List<int> v) {
    $_setBytes(2, v);
  }

  bool hasSkippedCursor() => $_has(2);
  void clearSkippedCursor() => clearField(3);

  List<int> get endCursor => $_getN(3);
  set endCursor(List<int> v) {
    $_setBytes(3, v);
  }

  bool hasEndCursor() => $_has(3);
  void clearEndCursor() => clearField(4);

  QueryResultBatch_MoreResultsType get moreResults => $_getN(4);
  set moreResults(QueryResultBatch_MoreResultsType v) {
    setField(5, v);
  }

  bool hasMoreResults() => $_has(4);
  void clearMoreResults() => clearField(5);

  int get skippedResults => $_get(5, 0);
  set skippedResults(int v) {
    $_setSignedInt32(5, v);
  }

  bool hasSkippedResults() => $_has(5);
  void clearSkippedResults() => clearField(6);

  Int64 get snapshotVersion => $_getI64(6);
  set snapshotVersion(Int64 v) {
    $_setInt64(6, v);
  }

  bool hasSnapshotVersion() => $_has(6);
  void clearSnapshotVersion() => clearField(7);
}
