///
//  Generated code. Do not modify.
//  source: google/api/label.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' show int, dynamic, String, List, Map;
import 'package:protobuf/protobuf.dart' as $pb;

class LabelDescriptor_ValueType extends $pb.ProtobufEnum {
  static const LabelDescriptor_ValueType STRING =
      const LabelDescriptor_ValueType._(0, 'STRING');
  static const LabelDescriptor_ValueType BOOL =
      const LabelDescriptor_ValueType._(1, 'BOOL');
  static const LabelDescriptor_ValueType INT64 =
      const LabelDescriptor_ValueType._(2, 'INT64');

  static const List<LabelDescriptor_ValueType> values =
      const <LabelDescriptor_ValueType>[
    STRING,
    BOOL,
    INT64,
  ];

  static final Map<int, LabelDescriptor_ValueType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static LabelDescriptor_ValueType valueOf(int value) => _byValue[value];
  static void $checkItem(LabelDescriptor_ValueType v) {
    if (v is! LabelDescriptor_ValueType)
      $pb.checkItemFailed(v, 'LabelDescriptor_ValueType');
  }

  const LabelDescriptor_ValueType._(int v, String n) : super(v, n);
}
