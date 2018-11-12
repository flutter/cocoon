///
//  Generated code. Do not modify.
//  source: google/api/http.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

class Http extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Http',
      package: const $pb.PackageName('google.api'))
    ..pp<HttpRule>(
        1, 'rules', $pb.PbFieldType.PM, HttpRule.$checkItem, HttpRule.create)
    ..aOB(2, 'fullyDecodeReservedExpansion')
    ..hasRequiredFields = false;

  Http() : super();
  Http.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Http.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Http clone() => new Http()..mergeFromMessage(this);
  Http copyWith(void Function(Http) updates) =>
      super.copyWith((message) => updates(message as Http));
  $pb.BuilderInfo get info_ => _i;
  static Http create() => new Http();
  static $pb.PbList<Http> createRepeated() => new $pb.PbList<Http>();
  static Http getDefault() => _defaultInstance ??= create()..freeze();
  static Http _defaultInstance;
  static void $checkItem(Http v) {
    if (v is! Http) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<HttpRule> get rules => $_getList(0);

  bool get fullyDecodeReservedExpansion => $_get(1, false);
  set fullyDecodeReservedExpansion(bool v) {
    $_setBool(1, v);
  }

  bool hasFullyDecodeReservedExpansion() => $_has(1);
  void clearFullyDecodeReservedExpansion() => clearField(2);
}

class HttpRule extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('HttpRule',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'selector')
    ..aOS(2, 'get')
    ..aOS(3, 'put')
    ..aOS(4, 'post')
    ..aOS(5, 'delete')
    ..aOS(6, 'patch')
    ..aOS(7, 'body')
    ..a<CustomHttpPattern>(8, 'custom', $pb.PbFieldType.OM,
        CustomHttpPattern.getDefault, CustomHttpPattern.create)
    ..pp<HttpRule>(11, 'additionalBindings', $pb.PbFieldType.PM,
        HttpRule.$checkItem, HttpRule.create)
    ..aOS(12, 'responseBody')
    ..hasRequiredFields = false;

  HttpRule() : super();
  HttpRule.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  HttpRule.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  HttpRule clone() => new HttpRule()..mergeFromMessage(this);
  HttpRule copyWith(void Function(HttpRule) updates) =>
      super.copyWith((message) => updates(message as HttpRule));
  $pb.BuilderInfo get info_ => _i;
  static HttpRule create() => new HttpRule();
  static $pb.PbList<HttpRule> createRepeated() => new $pb.PbList<HttpRule>();
  static HttpRule getDefault() => _defaultInstance ??= create()..freeze();
  static HttpRule _defaultInstance;
  static void $checkItem(HttpRule v) {
    if (v is! HttpRule) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get selector => $_getS(0, '');
  set selector(String v) {
    $_setString(0, v);
  }

  bool hasSelector() => $_has(0);
  void clearSelector() => clearField(1);

  String get get => $_getS(1, '');
  set get(String v) {
    $_setString(1, v);
  }

  bool hasGet() => $_has(1);
  void clearGet() => clearField(2);

  String get put => $_getS(2, '');
  set put(String v) {
    $_setString(2, v);
  }

  bool hasPut() => $_has(2);
  void clearPut() => clearField(3);

  String get post => $_getS(3, '');
  set post(String v) {
    $_setString(3, v);
  }

  bool hasPost() => $_has(3);
  void clearPost() => clearField(4);

  String get delete => $_getS(4, '');
  set delete(String v) {
    $_setString(4, v);
  }

  bool hasDelete() => $_has(4);
  void clearDelete() => clearField(5);

  String get patch => $_getS(5, '');
  set patch(String v) {
    $_setString(5, v);
  }

  bool hasPatch() => $_has(5);
  void clearPatch() => clearField(6);

  String get body => $_getS(6, '');
  set body(String v) {
    $_setString(6, v);
  }

  bool hasBody() => $_has(6);
  void clearBody() => clearField(7);

  CustomHttpPattern get custom => $_getN(7);
  set custom(CustomHttpPattern v) {
    setField(8, v);
  }

  bool hasCustom() => $_has(7);
  void clearCustom() => clearField(8);

  List<HttpRule> get additionalBindings => $_getList(8);

  String get responseBody => $_getS(9, '');
  set responseBody(String v) {
    $_setString(9, v);
  }

  bool hasResponseBody() => $_has(9);
  void clearResponseBody() => clearField(12);
}

class CustomHttpPattern extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('CustomHttpPattern',
      package: const $pb.PackageName('google.api'))
    ..aOS(1, 'kind')
    ..aOS(2, 'path')
    ..hasRequiredFields = false;

  CustomHttpPattern() : super();
  CustomHttpPattern.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  CustomHttpPattern.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  CustomHttpPattern clone() => new CustomHttpPattern()..mergeFromMessage(this);
  CustomHttpPattern copyWith(void Function(CustomHttpPattern) updates) =>
      super.copyWith((message) => updates(message as CustomHttpPattern));
  $pb.BuilderInfo get info_ => _i;
  static CustomHttpPattern create() => new CustomHttpPattern();
  static $pb.PbList<CustomHttpPattern> createRepeated() =>
      new $pb.PbList<CustomHttpPattern>();
  static CustomHttpPattern getDefault() =>
      _defaultInstance ??= create()..freeze();
  static CustomHttpPattern _defaultInstance;
  static void $checkItem(CustomHttpPattern v) {
    if (v is! CustomHttpPattern)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get kind => $_getS(0, '');
  set kind(String v) {
    $_setString(0, v);
  }

  bool hasKind() => $_has(0);
  void clearKind() => clearField(1);

  String get path => $_getS(1, '');
  set path(String v) {
    $_setString(1, v);
  }

  bool hasPath() => $_has(1);
  void clearPath() => clearField(2);
}
