//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/location_tag.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../proto/v1/common.pb.dart' as $0;
import '../../../proto/v1/test_metadata.pb.dart' as $1;

/// Map from directory paths in a repo to extra tags to attach to TestResults.
class LocationTags_Repo extends $pb.GeneratedMessage {
  factory LocationTags_Repo({
    $core.Map<$core.String, LocationTags_Dir>? dirs,
    $core.Map<$core.String, LocationTags_File>? files,
  }) {
    final $result = create();
    if (dirs != null) {
      $result.dirs.addAll(dirs);
    }
    if (files != null) {
      $result.files.addAll(files);
    }
    return $result;
  }
  LocationTags_Repo._() : super();
  factory LocationTags_Repo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocationTags_Repo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocationTags.Repo', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..m<$core.String, LocationTags_Dir>(1, _omitFieldNames ? '' : 'dirs', entryClassName: 'LocationTags.Repo.DirsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: LocationTags_Dir.create, valueDefaultOrMaker: LocationTags_Dir.getDefault, packageName: const $pb.PackageName('luci.resultsink.v1'))
    ..m<$core.String, LocationTags_File>(2, _omitFieldNames ? '' : 'files', entryClassName: 'LocationTags.Repo.FilesEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: LocationTags_File.create, valueDefaultOrMaker: LocationTags_File.getDefault, packageName: const $pb.PackageName('luci.resultsink.v1'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocationTags_Repo clone() => LocationTags_Repo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocationTags_Repo copyWith(void Function(LocationTags_Repo) updates) => super.copyWith((message) => updates(message as LocationTags_Repo)) as LocationTags_Repo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationTags_Repo create() => LocationTags_Repo._();
  LocationTags_Repo createEmptyInstance() => create();
  static $pb.PbList<LocationTags_Repo> createRepeated() => $pb.PbList<LocationTags_Repo>();
  @$core.pragma('dart2js:noInline')
  static LocationTags_Repo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocationTags_Repo>(create);
  static LocationTags_Repo? _defaultInstance;

  /// The key is a relative dir path.
  /// "" means repo root and represents default for all subdirs.
  /// Must use forward slash as a dir separator.
  @$pb.TagNumber(1)
  $core.Map<$core.String, LocationTags_Dir> get dirs => $_getMap(0);

  /// The key is a relative path to a file.
  /// Same rules apply as dir.
  @$pb.TagNumber(2)
  $core.Map<$core.String, LocationTags_File> get files => $_getMap(1);
}

/// Extra tags to attach to TestResults for a directory.
class LocationTags_Dir extends $pb.GeneratedMessage {
  factory LocationTags_Dir({
    $core.Iterable<$0.StringPair>? tags,
    $1.BugComponent? bugComponent,
  }) {
    final $result = create();
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (bugComponent != null) {
      $result.bugComponent = bugComponent;
    }
    return $result;
  }
  LocationTags_Dir._() : super();
  factory LocationTags_Dir.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocationTags_Dir.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocationTags.Dir', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..pc<$0.StringPair>(1, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $0.StringPair.create)
    ..aOM<$1.BugComponent>(2, _omitFieldNames ? '' : 'bugComponent', subBuilder: $1.BugComponent.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocationTags_Dir clone() => LocationTags_Dir()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocationTags_Dir copyWith(void Function(LocationTags_Dir) updates) => super.copyWith((message) => updates(message as LocationTags_Dir)) as LocationTags_Dir;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationTags_Dir create() => LocationTags_Dir._();
  LocationTags_Dir createEmptyInstance() => create();
  static $pb.PbList<LocationTags_Dir> createRepeated() => $pb.PbList<LocationTags_Dir>();
  @$core.pragma('dart2js:noInline')
  static LocationTags_Dir getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocationTags_Dir>(create);
  static LocationTags_Dir? _defaultInstance;

  ///  If a key is not defined for subdir, but defined for an ancestor dir, then
  ///  the value(s) in the ancestor is implied.
  ///
  ///  A key can be repeated.
  @$pb.TagNumber(1)
  $core.List<$0.StringPair> get tags => $_getList(0);

  /// The issue tracker component associated with the test, if any.
  /// Bugs related to the test may be filed here.
  /// Populated to test_metadata.bug_component.
  @$pb.TagNumber(2)
  $1.BugComponent get bugComponent => $_getN(1);
  @$pb.TagNumber(2)
  set bugComponent($1.BugComponent v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBugComponent() => $_has(1);
  @$pb.TagNumber(2)
  void clearBugComponent() => clearField(2);
  @$pb.TagNumber(2)
  $1.BugComponent ensureBugComponent() => $_ensure(1);
}

/// Extra tags to attach to TestResults for a file.
class LocationTags_File extends $pb.GeneratedMessage {
  factory LocationTags_File({
    $core.Iterable<$0.StringPair>? tags,
    $1.BugComponent? bugComponent,
  }) {
    final $result = create();
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (bugComponent != null) {
      $result.bugComponent = bugComponent;
    }
    return $result;
  }
  LocationTags_File._() : super();
  factory LocationTags_File.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocationTags_File.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocationTags.File', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..pc<$0.StringPair>(1, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $0.StringPair.create)
    ..aOM<$1.BugComponent>(2, _omitFieldNames ? '' : 'bugComponent', subBuilder: $1.BugComponent.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocationTags_File clone() => LocationTags_File()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocationTags_File copyWith(void Function(LocationTags_File) updates) => super.copyWith((message) => updates(message as LocationTags_File)) as LocationTags_File;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationTags_File create() => LocationTags_File._();
  LocationTags_File createEmptyInstance() => create();
  static $pb.PbList<LocationTags_File> createRepeated() => $pb.PbList<LocationTags_File>();
  @$core.pragma('dart2js:noInline')
  static LocationTags_File getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocationTags_File>(create);
  static LocationTags_File? _defaultInstance;

  /// A key can be repeated.
  @$pb.TagNumber(1)
  $core.List<$0.StringPair> get tags => $_getList(0);

  /// The issue tracker component associated with the test, if any.
  /// Bugs related to the test may be filed here.
  /// Populated to test_metadata.bug_component.
  @$pb.TagNumber(2)
  $1.BugComponent get bugComponent => $_getN(1);
  @$pb.TagNumber(2)
  set bugComponent($1.BugComponent v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBugComponent() => $_has(1);
  @$pb.TagNumber(2)
  void clearBugComponent() => clearField(2);
  @$pb.TagNumber(2)
  $1.BugComponent ensureBugComponent() => $_ensure(1);
}

///  Maps from directory paths to extra fields to attach to TestResults.
///  When converted to JSON format, it will look like below:
/// {
///   "repos": {
///     "https://chromium.googlesource.com/chromium/src" : {
///       "dirs": {
///         ".": {
///           "tags": {
///             "teamEmail": "team_email@chromium.org"
///           }
///         },
///         "foo": {
///           "tags": {
///             "teamEmail": "team_email@chromium.org",
///             "os": "WINDOWS"
///           },
///           "bug_component": {
///             "issue_tracker": {
///               "component_id": "17171717"
///             }
///           }
///         }
///       }
///       "files": {
///         "./file.txt": {
///           "tags": {
///             "teamEmail": "other_email@chromium.org",
///             "os": "WINDOWS"
///           },
///           "bug_component": {
///             "issue_tracker": {
///               "component_id": "123456"
///             }
///           }
///         }
///       }
///     }
///   }
/// }
///
///  N.B. This message is called 'LocationTags' because it was previously
///  only used for tags, but this is no longer true.
class LocationTags extends $pb.GeneratedMessage {
  factory LocationTags({
    $core.Map<$core.String, LocationTags_Repo>? repos,
  }) {
    final $result = create();
    if (repos != null) {
      $result.repos.addAll(repos);
    }
    return $result;
  }
  LocationTags._() : super();
  factory LocationTags.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocationTags.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocationTags', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..m<$core.String, LocationTags_Repo>(1, _omitFieldNames ? '' : 'repos', entryClassName: 'LocationTags.ReposEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: LocationTags_Repo.create, valueDefaultOrMaker: LocationTags_Repo.getDefault, packageName: const $pb.PackageName('luci.resultsink.v1'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocationTags clone() => LocationTags()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocationTags copyWith(void Function(LocationTags) updates) => super.copyWith((message) => updates(message as LocationTags)) as LocationTags;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationTags create() => LocationTags._();
  LocationTags createEmptyInstance() => create();
  static $pb.PbList<LocationTags> createRepeated() => $pb.PbList<LocationTags>();
  @$core.pragma('dart2js:noInline')
  static LocationTags getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocationTags>(create);
  static LocationTags? _defaultInstance;

  /// The key is a Gitiles URL as the identifier for a repo.
  /// Format for Gitiles URL: https://<host>/<project>
  /// For example "https://chromium.googlesource.com/chromium/src"
  /// Must not end with ".git".
  @$pb.TagNumber(1)
  $core.Map<$core.String, LocationTags_Repo> get repos => $_getMap(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
