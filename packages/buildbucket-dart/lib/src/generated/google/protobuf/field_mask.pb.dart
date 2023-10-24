//
//  Generated code. Do not modify.
//  source: google/protobuf/field_mask.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/src/protobuf/mixins/well_known.dart' as $mixin;

class FieldMask extends $pb.GeneratedMessage with $mixin.FieldMaskMixin {
  factory FieldMask() => create();
  FieldMask._() : super();
  factory FieldMask.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FieldMask.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FieldMask', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.protobuf'), createEmptyInstance: create, toProto3Json: $mixin.FieldMaskMixin.toProto3JsonHelper, fromProto3Json: $mixin.FieldMaskMixin.fromProto3JsonHelper)
    ..pPS(1, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FieldMask clone() => FieldMask()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FieldMask copyWith(void Function(FieldMask) updates) => super.copyWith((message) => updates(message as FieldMask)) as FieldMask;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FieldMask create() => FieldMask._();
  FieldMask createEmptyInstance() => create();
  static $pb.PbList<FieldMask> createRepeated() => $pb.PbList<FieldMask>();
  @$core.pragma('dart2js:noInline')
  static FieldMask getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FieldMask>(create);
  static FieldMask? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get paths => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
