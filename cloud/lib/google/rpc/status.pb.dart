///
//  Generated code. Do not modify.
//  source: google/rpc/status.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

import '../protobuf/any.pb.dart' as $0;

class Status extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Status',
      package: const $pb.PackageName('google.rpc'))
    ..a<int>(1, 'code', $pb.PbFieldType.O3)
    ..aOS(2, 'message')
    ..pp<$0.Any>(
        3, 'details', $pb.PbFieldType.PM, $0.Any.$checkItem, $0.Any.create)
    ..hasRequiredFields = false;

  Status() : super();
  Status.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Status.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Status clone() => new Status()..mergeFromMessage(this);
  Status copyWith(void Function(Status) updates) =>
      super.copyWith((message) => updates(message as Status));
  $pb.BuilderInfo get info_ => _i;
  static Status create() => new Status();
  static $pb.PbList<Status> createRepeated() => new $pb.PbList<Status>();
  static Status getDefault() => _defaultInstance ??= create()..freeze();
  static Status _defaultInstance;
  static void $checkItem(Status v) {
    if (v is! Status) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  int get code => $_get(0, 0);
  set code(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasCode() => $_has(0);
  void clearCode() => clearField(1);

  String get message => $_getS(1, '');
  set message(String v) {
    $_setString(1, v);
  }

  bool hasMessage() => $_has(1);
  void clearMessage() => clearField(2);

  List<$0.Any> get details => $_getList(2);
}
