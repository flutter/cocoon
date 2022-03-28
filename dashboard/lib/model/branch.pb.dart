///
//  Generated code. Do not modify.
//  source: lib/model/branch.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Branch extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Branch',
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'branch')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'repository')
    ..hasRequiredFields = false;

  Branch._() : super();
  factory Branch({
    $core.String? branch,
    $core.String? repository,
  }) {
    final _result = create();
    if (branch != null) {
      _result.branch = branch;
    }
    if (repository != null) {
      _result.repository = repository;
    }
    return _result;
  }
  factory Branch.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Branch.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Branch clone() => Branch()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Branch copyWith(void Function(Branch) updates) =>
      super.copyWith((message) => updates(message as Branch)) as Branch; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Branch create() => Branch._();
  Branch createEmptyInstance() => create();
  static $pb.PbList<Branch> createRepeated() => $pb.PbList<Branch>();
  @$core.pragma('dart2js:noInline')
  static Branch getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Branch>(create);
  static Branch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get branch => $_getSZ(0);
  @$pb.TagNumber(1)
  set branch($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBranch() => $_has(0);
  @$pb.TagNumber(1)
  void clearBranch() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get repository => $_getSZ(1);
  @$pb.TagNumber(2)
  set repository($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRepository() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepository() => clearField(2);
}
