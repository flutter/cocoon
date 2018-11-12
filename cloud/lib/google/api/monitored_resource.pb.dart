///
//  Generated code. Do not modify.
//  source: google/api/monitored_resource.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

import 'label.pb.dart' as $0;
import '../protobuf/struct.pb.dart' as $1;

class MonitoredResourceDescriptor extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'MonitoredResourceDescriptor',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'type')
    ..aOS(2, 'displayName')
    ..aOS(3, 'description')
    ..pp<$0.LabelDescriptor>(4, 'labels', $pb.PbFieldType.PM,
        $0.LabelDescriptor.$checkItem, $0.LabelDescriptor.create)
    ..aOS(5, 'name')
    ..hasRequiredFields = false;

  MonitoredResourceDescriptor() : super();
  MonitoredResourceDescriptor.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MonitoredResourceDescriptor.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MonitoredResourceDescriptor clone() =>
      new MonitoredResourceDescriptor()..mergeFromMessage(this);
  MonitoredResourceDescriptor copyWith(
          void Function(MonitoredResourceDescriptor) updates) =>
      super.copyWith(
          (message) => updates(message as MonitoredResourceDescriptor));
  $pb.BuilderInfo get info_ => _i;
  static MonitoredResourceDescriptor create() =>
      new MonitoredResourceDescriptor();
  static $pb.PbList<MonitoredResourceDescriptor> createRepeated() =>
      new $pb.PbList<MonitoredResourceDescriptor>();
  static MonitoredResourceDescriptor getDefault() =>
      _defaultInstance ??= create()..freeze();
  static MonitoredResourceDescriptor _defaultInstance;
  static void $checkItem(MonitoredResourceDescriptor v) {
    if (v is! MonitoredResourceDescriptor)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get type => $_getS(0, '');
  set type(String v) {
    $_setString(0, v);
  }

  bool hasType() => $_has(0);
  void clearType() => clearField(1);

  String get displayName => $_getS(1, '');
  set displayName(String v) {
    $_setString(1, v);
  }

  bool hasDisplayName() => $_has(1);
  void clearDisplayName() => clearField(2);

  String get description => $_getS(2, '');
  set description(String v) {
    $_setString(2, v);
  }

  bool hasDescription() => $_has(2);
  void clearDescription() => clearField(3);

  List<$0.LabelDescriptor> get labels => $_getList(3);

  String get name => $_getS(4, '');
  set name(String v) {
    $_setString(4, v);
  }

  bool hasName() => $_has(4);
  void clearName() => clearField(5);
}

class MonitoredResource_LabelsEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'MonitoredResource.LabelsEntry',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'key')
    ..aOS(2, 'value')
    ..hasRequiredFields = false;

  MonitoredResource_LabelsEntry() : super();
  MonitoredResource_LabelsEntry.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MonitoredResource_LabelsEntry.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MonitoredResource_LabelsEntry clone() =>
      new MonitoredResource_LabelsEntry()..mergeFromMessage(this);
  MonitoredResource_LabelsEntry copyWith(
          void Function(MonitoredResource_LabelsEntry) updates) =>
      super.copyWith(
          (message) => updates(message as MonitoredResource_LabelsEntry));
  $pb.BuilderInfo get info_ => _i;
  static MonitoredResource_LabelsEntry create() =>
      new MonitoredResource_LabelsEntry();
  static $pb.PbList<MonitoredResource_LabelsEntry> createRepeated() =>
      new $pb.PbList<MonitoredResource_LabelsEntry>();
  static MonitoredResource_LabelsEntry getDefault() =>
      _defaultInstance ??= create()..freeze();
  static MonitoredResource_LabelsEntry _defaultInstance;
  static void $checkItem(MonitoredResource_LabelsEntry v) {
    if (v is! MonitoredResource_LabelsEntry)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get key => $_getS(0, '');
  set key(String v) {
    $_setString(0, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  String get value => $_getS(1, '');
  set value(String v) {
    $_setString(1, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class MonitoredResource extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('MonitoredResource',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'type')
    ..pp<MonitoredResource_LabelsEntry>(
        2,
        'labels',
        $pb.PbFieldType.PM,
        MonitoredResource_LabelsEntry.$checkItem,
        MonitoredResource_LabelsEntry.create)
    ..hasRequiredFields = false;

  MonitoredResource() : super();
  MonitoredResource.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MonitoredResource.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MonitoredResource clone() => new MonitoredResource()..mergeFromMessage(this);
  MonitoredResource copyWith(void Function(MonitoredResource) updates) =>
      super.copyWith((message) => updates(message as MonitoredResource));
  $pb.BuilderInfo get info_ => _i;
  static MonitoredResource create() => new MonitoredResource();
  static $pb.PbList<MonitoredResource> createRepeated() =>
      new $pb.PbList<MonitoredResource>();
  static MonitoredResource getDefault() =>
      _defaultInstance ??= create()..freeze();
  static MonitoredResource _defaultInstance;
  static void $checkItem(MonitoredResource v) {
    if (v is! MonitoredResource)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get type => $_getS(0, '');
  set type(String v) {
    $_setString(0, v);
  }

  bool hasType() => $_has(0);
  void clearType() => clearField(1);

  List<MonitoredResource_LabelsEntry> get labels => $_getList(1);
}

class MonitoredResourceMetadata_UserLabelsEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'MonitoredResourceMetadata.UserLabelsEntry',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'key')
    ..aOS(2, 'value')
    ..hasRequiredFields = false;

  MonitoredResourceMetadata_UserLabelsEntry() : super();
  MonitoredResourceMetadata_UserLabelsEntry.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MonitoredResourceMetadata_UserLabelsEntry.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MonitoredResourceMetadata_UserLabelsEntry clone() =>
      new MonitoredResourceMetadata_UserLabelsEntry()..mergeFromMessage(this);
  MonitoredResourceMetadata_UserLabelsEntry copyWith(
          void Function(MonitoredResourceMetadata_UserLabelsEntry) updates) =>
      super.copyWith((message) =>
          updates(message as MonitoredResourceMetadata_UserLabelsEntry));
  $pb.BuilderInfo get info_ => _i;
  static MonitoredResourceMetadata_UserLabelsEntry create() =>
      new MonitoredResourceMetadata_UserLabelsEntry();
  static $pb.PbList<MonitoredResourceMetadata_UserLabelsEntry>
      createRepeated() =>
          new $pb.PbList<MonitoredResourceMetadata_UserLabelsEntry>();
  static MonitoredResourceMetadata_UserLabelsEntry getDefault() =>
      _defaultInstance ??= create()..freeze();
  static MonitoredResourceMetadata_UserLabelsEntry _defaultInstance;
  static void $checkItem(MonitoredResourceMetadata_UserLabelsEntry v) {
    if (v is! MonitoredResourceMetadata_UserLabelsEntry)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get key => $_getS(0, '');
  set key(String v) {
    $_setString(0, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  String get value => $_getS(1, '');
  set value(String v) {
    $_setString(1, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class MonitoredResourceMetadata extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'MonitoredResourceMetadata',
      package: const $pb.PackageName('google.api'))
    ..a<$1.Struct>(1, 'systemLabels', $pb.PbFieldType.OM, $1.Struct.getDefault,
        $1.Struct.create)
    ..pp<MonitoredResourceMetadata_UserLabelsEntry>(
        2,
        'userLabels',
        $pb.PbFieldType.PM,
        MonitoredResourceMetadata_UserLabelsEntry.$checkItem,
        MonitoredResourceMetadata_UserLabelsEntry.create)
    ..hasRequiredFields = false;

  MonitoredResourceMetadata() : super();
  MonitoredResourceMetadata.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  MonitoredResourceMetadata.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  MonitoredResourceMetadata clone() =>
      new MonitoredResourceMetadata()..mergeFromMessage(this);
  MonitoredResourceMetadata copyWith(
          void Function(MonitoredResourceMetadata) updates) =>
      super
          .copyWith((message) => updates(message as MonitoredResourceMetadata));
  $pb.BuilderInfo get info_ => _i;
  static MonitoredResourceMetadata create() => new MonitoredResourceMetadata();
  static $pb.PbList<MonitoredResourceMetadata> createRepeated() =>
      new $pb.PbList<MonitoredResourceMetadata>();
  static MonitoredResourceMetadata getDefault() =>
      _defaultInstance ??= create()..freeze();
  static MonitoredResourceMetadata _defaultInstance;
  static void $checkItem(MonitoredResourceMetadata v) {
    if (v is! MonitoredResourceMetadata)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  $1.Struct get systemLabels => $_getN(0);
  set systemLabels($1.Struct v) {
    setField(1, v);
  }

  bool hasSystemLabels() => $_has(0);
  void clearSystemLabels() => clearField(1);

  List<MonitoredResourceMetadata_UserLabelsEntry> get userLabels =>
      $_getList(1);
}
