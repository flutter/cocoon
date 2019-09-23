///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/stage.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $0;
import 'task.pb.dart' as $1;

class Stage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Stage')
    ..aOS(1, 'name')
    ..a<$0.Commit>(2, 'commit', $pb.PbFieldType.OM, $0.Commit.getDefault, $0.Commit.create)
    ..pc<$1.Task>(3, 'tasks', $pb.PbFieldType.PM,$1.Task.create)
    ..aOS(4, 'taskStatus')
    ..hasRequiredFields = false
  ;

  Stage._() : super();
  factory Stage() => create();
  factory Stage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Stage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Stage clone() => Stage()..mergeFromMessage(this);
  Stage copyWith(void Function(Stage) updates) => super.copyWith((message) => updates(message as Stage));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Stage create() => Stage._();
  Stage createEmptyInstance() => create();
  static $pb.PbList<Stage> createRepeated() => $pb.PbList<Stage>();
  static Stage getDefault() => _defaultInstance ??= create()..freeze();
  static Stage _defaultInstance;

  $core.String get name => $_getS(0, '');
  set name($core.String v) { $_setString(0, v); }
  $core.bool hasName() => $_has(0);
  void clearName() => clearField(1);

  $0.Commit get commit => $_getN(1);
  set commit($0.Commit v) { setField(2, v); }
  $core.bool hasCommit() => $_has(1);
  void clearCommit() => clearField(2);

  $core.List<$1.Task> get tasks => $_getList(2);

  $core.String get taskStatus => $_getS(3, '');
  set taskStatus($core.String v) { $_setString(3, v); }
  $core.bool hasTaskStatus() => $_has(3);
  void clearTaskStatus() => clearField(4);
}

