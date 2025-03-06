//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class BuilderMask_BuilderMaskType extends $pb.ProtobufEnum {
  static const BuilderMask_BuilderMaskType BUILDER_MASK_TYPE_UNSPECIFIED =
      BuilderMask_BuilderMaskType._(
          0, _omitEnumNames ? '' : 'BUILDER_MASK_TYPE_UNSPECIFIED');
  static const BuilderMask_BuilderMaskType CONFIG_ONLY =
      BuilderMask_BuilderMaskType._(1, _omitEnumNames ? '' : 'CONFIG_ONLY');
  static const BuilderMask_BuilderMaskType ALL =
      BuilderMask_BuilderMaskType._(2, _omitEnumNames ? '' : 'ALL');
  static const BuilderMask_BuilderMaskType METADATA_ONLY =
      BuilderMask_BuilderMaskType._(3, _omitEnumNames ? '' : 'METADATA_ONLY');

  static const $core.List<BuilderMask_BuilderMaskType> values =
      <BuilderMask_BuilderMaskType>[
    BUILDER_MASK_TYPE_UNSPECIFIED,
    CONFIG_ONLY,
    ALL,
    METADATA_ONLY,
  ];

  static final $core.Map<$core.int, BuilderMask_BuilderMaskType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static BuilderMask_BuilderMaskType? valueOf($core.int value) =>
      _byValue[value];

  const BuilderMask_BuilderMaskType._($core.int v, $core.String n)
      : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
