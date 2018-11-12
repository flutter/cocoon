///
//  Generated code. Do not modify.
//  source: google/api/label.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

import 'label.pbenum.dart';

export 'label.pbenum.dart';

class LabelDescriptor extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('LabelDescriptor',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'key')
    ..e<LabelDescriptor_ValueType>(
        2,
        'valueType',
        $pb.PbFieldType.OE,
        LabelDescriptor_ValueType.STRING,
        LabelDescriptor_ValueType.valueOf,
        LabelDescriptor_ValueType.values)
    ..aOS(3, 'description')
    ..hasRequiredFields = false;

  LabelDescriptor() : super();
  LabelDescriptor.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LabelDescriptor.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LabelDescriptor clone() => new LabelDescriptor()..mergeFromMessage(this);
  LabelDescriptor copyWith(void Function(LabelDescriptor) updates) =>
      super.copyWith((message) => updates(message as LabelDescriptor));
  $pb.BuilderInfo get info_ => _i;
  static LabelDescriptor create() => new LabelDescriptor();
  static $pb.PbList<LabelDescriptor> createRepeated() =>
      new $pb.PbList<LabelDescriptor>();
  static LabelDescriptor getDefault() =>
      _defaultInstance ??= create()..freeze();
  static LabelDescriptor _defaultInstance;
  static void $checkItem(LabelDescriptor v) {
    if (v is! LabelDescriptor) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get key => $_getS(0, '');
  set key(String v) {
    $_setString(0, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  LabelDescriptor_ValueType get valueType => $_getN(1);
  set valueType(LabelDescriptor_ValueType v) {
    setField(2, v);
  }

  bool hasValueType() => $_has(1);
  void clearValueType() => clearField(2);

  String get description => $_getS(2, '');
  set description(String v) {
    $_setString(2, v);
  }

  bool hasDescription() => $_has(2);
  void clearDescription() => clearField(3);
}
