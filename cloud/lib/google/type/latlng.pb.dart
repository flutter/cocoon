///
//  Generated code. Do not modify.
//  source: google/type/latlng.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

class LatLng extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('LatLng',
      package: const $pb.PackageName('google.type'))
    ..a<double>(1, 'latitude', $pb.PbFieldType.OD)
    ..a<double>(2, 'longitude', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  LatLng() : super();
  LatLng.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  LatLng.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  LatLng clone() => new LatLng()..mergeFromMessage(this);
  LatLng copyWith(void Function(LatLng) updates) =>
      super.copyWith((message) => updates(message as LatLng));
  $pb.BuilderInfo get info_ => _i;
  static LatLng create() => new LatLng();
  static $pb.PbList<LatLng> createRepeated() => new $pb.PbList<LatLng>();
  static LatLng getDefault() => _defaultInstance ??= create()..freeze();
  static LatLng _defaultInstance;
  static void $checkItem(LatLng v) {
    if (v is! LatLng) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  double get latitude => $_getN(0);
  set latitude(double v) {
    $_setDouble(0, v);
  }

  bool hasLatitude() => $_has(0);
  void clearLatitude() => clearField(1);

  double get longitude => $_getN(1);
  set longitude(double v) {
    $_setDouble(1, v);
  }

  bool hasLongitude() => $_has(1);
  void clearLongitude() => clearField(2);
}
