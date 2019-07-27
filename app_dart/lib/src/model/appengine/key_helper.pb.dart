///
//  Generated code. Do not modify.
//  source: lib/src/model/key_helper.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

class Path_Element extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Path.Element')
    ..aQS(2, 'type')
    ..aInt64(3, 'id')
    ..aOS(4, 'name');

  Path_Element._() : super();
  factory Path_Element() => create();
  factory Path_Element.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Path_Element.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  Path_Element clone() => Path_Element()..mergeFromMessage(this);
  Path_Element copyWith(void Function(Path_Element) updates) =>
      super.copyWith((message) => updates(message as Path_Element));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Path_Element create() => Path_Element._();
  Path_Element createEmptyInstance() => create();
  static $pb.PbList<Path_Element> createRepeated() => $pb.PbList<Path_Element>();
  static Path_Element getDefault() => _defaultInstance ??= create()..freeze();
  static Path_Element _defaultInstance;

  $core.String get type => $_getS(0, '');
  set type($core.String v) {
    $_setString(0, v);
  }

  $core.bool hasType() => $_has(0);
  void clearType() => clearField(2);

  Int64 get id => $_getI64(1);
  set id(Int64 v) {
    $_setInt64(1, v);
  }

  $core.bool hasId() => $_has(1);
  void clearId() => clearField(3);

  $core.String get name => $_getS(2, '');
  set name($core.String v) {
    $_setString(2, v);
  }

  $core.bool hasName() => $_has(2);
  void clearName() => clearField(4);
}

class Path extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Path')
    ..pc<Path_Element>(1, 'element', $pb.PbFieldType.PG, Path_Element.create)
    ..hasRequiredFields = false;

  Path._() : super();
  factory Path() => create();
  factory Path.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Path.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  Path clone() => Path()..mergeFromMessage(this);
  Path copyWith(void Function(Path) updates) =>
      super.copyWith((message) => updates(message as Path));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Path create() => Path._();
  Path createEmptyInstance() => create();
  static $pb.PbList<Path> createRepeated() => $pb.PbList<Path>();
  static Path getDefault() => _defaultInstance ??= create()..freeze();
  static Path _defaultInstance;

  $core.List<Path_Element> get element => $_getList(0);
}

class Reference extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Reference')
    ..aQS(13, 'app')
    ..a<Path>(14, 'path', $pb.PbFieldType.QM, Path.getDefault, Path.create)
    ..aOS(20, 'nameSpace');

  Reference._() : super();
  factory Reference() => create();
  factory Reference.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Reference.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  Reference clone() => Reference()..mergeFromMessage(this);
  Reference copyWith(void Function(Reference) updates) =>
      super.copyWith((message) => updates(message as Reference));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Reference create() => Reference._();
  Reference createEmptyInstance() => create();
  static $pb.PbList<Reference> createRepeated() => $pb.PbList<Reference>();
  static Reference getDefault() => _defaultInstance ??= create()..freeze();
  static Reference _defaultInstance;

  $core.String get app => $_getS(0, '');
  set app($core.String v) {
    $_setString(0, v);
  }

  $core.bool hasApp() => $_has(0);
  void clearApp() => clearField(13);

  Path get path => $_getN(1);
  set path(Path v) {
    setField(14, v);
  }

  $core.bool hasPath() => $_has(1);
  void clearPath() => clearField(14);

  $core.String get nameSpace => $_getS(2, '');
  set nameSpace($core.String v) {
    $_setString(2, v);
  }

  $core.bool hasNameSpace() => $_has(2);
  void clearNameSpace() => clearField(20);
}
