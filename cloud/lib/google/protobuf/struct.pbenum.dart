///
//  Generated code. Do not modify.
//  source: google/protobuf/struct.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' show int, dynamic, String, List, Map;
import 'package:protobuf/protobuf.dart' as $pb;

class NullValue extends $pb.ProtobufEnum {
  static const NullValue NULL_VALUE = const NullValue._(0, 'NULL_VALUE');

  static const List<NullValue> values = const <NullValue>[
    NULL_VALUE,
  ];

  static final Map<int, NullValue> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static NullValue valueOf(int value) => _byValue[value];
  static void $checkItem(NullValue v) {
    if (v is! NullValue) $pb.checkItemFailed(v, 'NullValue');
  }

  const NullValue._(int v, String n) : super(v, n);
}
