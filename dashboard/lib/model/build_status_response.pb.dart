///
//  Generated code. Do not modify.
//  source: lib/model/build_status_response.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'build_status_response.pbenum.dart';

export 'build_status_response.pbenum.dart';

class BuildStatusResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'BuildStatusResponse',
      createEmptyInstance: create)
    ..e<EnumBuildStatus>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'buildStatus',
        $pb.PbFieldType.OE,
        defaultOrMaker: EnumBuildStatus.success,
        valueOf: EnumBuildStatus.valueOf,
        enumValues: EnumBuildStatus.values)
    ..pPS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'failingTasks')
    ..hasRequiredFields = false;

  BuildStatusResponse._() : super();
  factory BuildStatusResponse({
    EnumBuildStatus? buildStatus,
    $core.Iterable<$core.String>? failingTasks,
  }) {
    final _result = create();
    if (buildStatus != null) {
      _result.buildStatus = buildStatus;
    }
    if (failingTasks != null) {
      _result.failingTasks.addAll(failingTasks);
    }
    return _result;
  }
  factory BuildStatusResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildStatusResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildStatusResponse clone() => BuildStatusResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildStatusResponse copyWith(void Function(BuildStatusResponse) updates) =>
      super.copyWith((message) => updates(message as BuildStatusResponse))
          as BuildStatusResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildStatusResponse create() => BuildStatusResponse._();
  BuildStatusResponse createEmptyInstance() => create();
  static $pb.PbList<BuildStatusResponse> createRepeated() =>
      $pb.PbList<BuildStatusResponse>();
  @$core.pragma('dart2js:noInline')
  static BuildStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildStatusResponse>(create);
  static BuildStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  EnumBuildStatus get buildStatus => $_getN(0);
  @$pb.TagNumber(1)
  set buildStatus(EnumBuildStatus v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuildStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildStatus() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get failingTasks => $_getList(1);
}
