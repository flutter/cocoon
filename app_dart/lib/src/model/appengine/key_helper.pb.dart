///
//  Generated code. Do not modify.
//  source: lib/src/model/appengine/key_helper.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Path_Element extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Path.Element', createEmptyInstance: create)
    ..aQS(2, 'type')
    ..aInt64(3, 'id')
    ..aOS(4, 'name');

  Path_Element._() : super();
  factory Path_Element() => create();
  factory Path_Element.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Path_Element.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @override
  @override
  @override
  Path_Element clone() => Path_Element()..mergeFromMessage(this);
  @override
  @override
  @override
  Path_Element copyWith(void Function(Path_Element) updates) =>
      super.copyWith((message) => updates(message as Path_Element));
  @override
  @override
  @override
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Path_Element create() => Path_Element._();
  @override
  @override
  @override
  Path_Element createEmptyInstance() => create();
  static $pb.PbList<Path_Element> createRepeated() => $pb.PbList<Path_Element>();
  @$core.pragma('dart2js:noInline')
  static Path_Element getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Path_Element>(create);
  static Path_Element _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(2)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get id => $_getI64(1);
  @$pb.TagNumber(3)
  set id($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(4)
  set name($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);
}

class Path extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Path', createEmptyInstance: create)
    ..pc<Path_Element>(1, 'element', $pb.PbFieldType.PG, subBuilder: Path_Element.create)
    ..hasRequiredFields = false;

  Path._() : super();
  factory Path() => create();
  factory Path.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Path.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @override
  @override
  @override
  Path clone() => Path()..mergeFromMessage(this);
  @override
  @override
  @override
  Path copyWith(void Function(Path) updates) => super.copyWith((message) => updates(message as Path));
  @override
  @override
  @override
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Path create() => Path._();
  @override
  @override
  @override
  Path createEmptyInstance() => create();
  static $pb.PbList<Path> createRepeated() => $pb.PbList<Path>();
  @$core.pragma('dart2js:noInline')
  static Path getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Path>(create);
  static Path _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Path_Element> get element => $_getList(0);
}

class Reference extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Reference', createEmptyInstance: create)
    ..aQS(13, 'app')
    ..aQM<Path>(14, 'path', subBuilder: Path.create)
    ..aOS(20, 'nameSpace');

  Reference._() : super();
  factory Reference() => create();
  factory Reference.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Reference.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @override
  @override
  @override
  Reference clone() => Reference()..mergeFromMessage(this);
  @override
  @override
  @override
  Reference copyWith(void Function(Reference) updates) => super.copyWith((message) => updates(message as Reference));
  @override
  @override
  @override
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Reference create() => Reference._();
  @override
  @override
  @override
  Reference createEmptyInstance() => create();
  static $pb.PbList<Reference> createRepeated() => $pb.PbList<Reference>();
  @$core.pragma('dart2js:noInline')
  static Reference getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Reference>(create);
  static Reference _defaultInstance;

  @$pb.TagNumber(13)
  $core.String get app => $_getSZ(0);
  @$pb.TagNumber(13)
  set app($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasApp() => $_has(0);
  @$pb.TagNumber(13)
  void clearApp() => clearField(13);

  @$pb.TagNumber(14)
  Path get path => $_getN(1);
  @$pb.TagNumber(14)
  set path(Path v) {
    setField(14, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(14)
  void clearPath() => clearField(14);
  @$pb.TagNumber(14)
  Path ensurePath() => $_ensure(1);

  @$pb.TagNumber(20)
  $core.String get nameSpace => $_getSZ(2);
  @$pb.TagNumber(20)
  set nameSpace($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasNameSpace() => $_has(2);
  @$pb.TagNumber(20)
  void clearNameSpace() => clearField(20);
}
