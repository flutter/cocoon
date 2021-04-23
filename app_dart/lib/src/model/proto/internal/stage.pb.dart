///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/stage.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $1;
import 'task.pb.dart' as $2;

class Stage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Stage', createEmptyInstance: create)
    ..aOS(1, 'name')
    ..aOM<$1.Commit>(2, 'commit', subBuilder: $1.Commit.create)
    ..pc<$2.Task>(3, 'tasks', $pb.PbFieldType.PM, subBuilder: $2.Task.create)
    ..aOS(4, 'taskStatus')
    ..hasRequiredFields = false;

  Stage._() : super();
  factory Stage() => create();
  factory Stage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Stage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @override
  @override
  @override
  Stage clone() => Stage()..mergeFromMessage(this);
  @override
  @override
  @override
  Stage copyWith(void Function(Stage) updates) => super.copyWith((message) => updates(message as Stage));
  @override
  @override
  @override
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Stage create() => Stage._();
  @override
  @override
  @override
  Stage createEmptyInstance() => create();
  static $pb.PbList<Stage> createRepeated() => $pb.PbList<Stage>();
  @$core.pragma('dart2js:noInline')
  static Stage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Stage>(create);
  static Stage _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $1.Commit get commit => $_getN(1);
  @$pb.TagNumber(2)
  set commit($1.Commit v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommit() => clearField(2);
  @$pb.TagNumber(2)
  $1.Commit ensureCommit() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$2.Task> get tasks => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get taskStatus => $_getSZ(3);
  @$pb.TagNumber(4)
  set taskStatus($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTaskStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearTaskStatus() => clearField(4);
}
