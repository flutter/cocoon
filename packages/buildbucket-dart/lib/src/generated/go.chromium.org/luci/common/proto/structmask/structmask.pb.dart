//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/common/proto/structmask/structmask.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

///  StructMask selects a subset of a google.protobuf.Struct.
///
///  Usually used as a repeated field, to allow specifying a union of different
///  subsets.
class StructMask extends $pb.GeneratedMessage {
  factory StructMask({
    $core.Iterable<$core.String>? path,
  }) {
    final $result = create();
    if (path != null) {
      $result.path.addAll(path);
    }
    return $result;
  }
  StructMask._() : super();
  factory StructMask.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StructMask.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StructMask',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'structmask'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StructMask clone() => StructMask()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StructMask copyWith(void Function(StructMask) updates) =>
      super.copyWith((message) => updates(message as StructMask)) as StructMask;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StructMask create() => StructMask._();
  StructMask createEmptyInstance() => create();
  static $pb.PbList<StructMask> createRepeated() => $pb.PbList<StructMask>();
  @$core.pragma('dart2js:noInline')
  static StructMask getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StructMask>(create);
  static StructMask? _defaultInstance;

  ///  A field path inside the struct to select.
  ///
  ///  Each item can be:
  ///    * `some_value` - a concrete dict key to follow (unless it is a number or
  ///      includes `*`, use quotes in this case).
  ///    * `"some_value"` - same, but quoted. Useful for selecting `*` or numbers
  ///      literally. See https://pkg.go.dev/strconv#Unquote for syntax.
  ///    * `<number>` (e.g. `0`) - a zero-based list index to follow.
  ///      **Not implemented**.
  ///    *  `*` - follow all dict keys and all list elements. Applies **only** to
  ///      dicts and lists. Trying to recurse into a number or a string results
  ///      in an empty match.
  ///
  ///  When examining a value the following exceptional conditions result in
  ///  an empty match, which is represented by `null` for list elements or
  ///  omissions of the field for dicts:
  ///    * Trying to follow a dict key while examining a list.
  ///    * Trying to follow a key which is not present in the dict.
  ///    * Trying to use `*` mask with values that aren't dicts or lists.
  ///
  ///  When using `*`, the result is always a subset of the input. In particular
  ///  this is important when filtering lists: if a list of size N is selected by
  ///  the mask, then the filtered result will also always be a list of size N,
  ///  with elements filtered further according to the rest of the mask (perhaps
  ///  resulting in `null` elements on type mismatches, as explained above).
  @$pb.TagNumber(1)
  $core.List<$core.String> get path => $_getList(0);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
