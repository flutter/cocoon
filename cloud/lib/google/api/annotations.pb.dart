///
//  Generated code. Do not modify.
//  source: google/api/annotations.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

import 'http.pb.dart' as $0;

class Annotations {
  static final $pb.Extension http = new $pb.Extension<$0.HttpRule>(
      'google.protobuf.MethodOptions',
      'http',
      72295728,
      $pb.PbFieldType.OM,
      $0.HttpRule.getDefault,
      $0.HttpRule.create);
  static void registerAllExtensions($pb.ExtensionRegistry registry) {
    registry.add(http);
  }
}
