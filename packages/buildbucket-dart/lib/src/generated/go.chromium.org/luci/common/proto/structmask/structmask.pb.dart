//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/common/proto/structmask/structmask.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class StructMask extends $pb.GeneratedMessage {
  factory StructMask() => create();
  StructMask._() : super();
  factory StructMask.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StructMask.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StructMask', package: const $pb.PackageName(_omitMessageNames ? '' : 'structmask'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StructMask clone() => StructMask()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StructMask copyWith(void Function(StructMask) updates) => super.copyWith((message) => updates(message as StructMask)) as StructMask;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StructMask create() => StructMask._();
  StructMask createEmptyInstance() => create();
  static $pb.PbList<StructMask> createRepeated() => $pb.PbList<StructMask>();
  @$core.pragma('dart2js:noInline')
  static StructMask getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StructMask>(create);
  static StructMask? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get path => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
