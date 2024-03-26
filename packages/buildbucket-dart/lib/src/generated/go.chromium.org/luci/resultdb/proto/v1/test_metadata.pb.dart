//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/test_metadata.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../google/protobuf/struct.pb.dart' as $1;
import 'common.pb.dart' as $0;

/// Information about a test metadata.
class TestMetadataDetail extends $pb.GeneratedMessage {
  factory TestMetadataDetail({
    $core.String? name,
    $core.String? project,
    $core.String? testId,
    $0.SourceRef? sourceRef,
    TestMetadata? testMetadata,
    $core.String? refHash,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (project != null) {
      $result.project = project;
    }
    if (testId != null) {
      $result.testId = testId;
    }
    if (sourceRef != null) {
      $result.sourceRef = sourceRef;
    }
    if (testMetadata != null) {
      $result.testMetadata = testMetadata;
    }
    if (refHash != null) {
      $result.refHash = refHash;
    }
    return $result;
  }
  TestMetadataDetail._() : super();
  factory TestMetadataDetail.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TestMetadataDetail.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestMetadataDetail',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'testId')
    ..aOM<$0.SourceRef>(4, _omitFieldNames ? '' : 'sourceRef', subBuilder: $0.SourceRef.create)
    ..aOM<TestMetadata>(5, _omitFieldNames ? '' : 'testMetadata',
        protoName: 'testMetadata', subBuilder: TestMetadata.create)
    ..aOS(12, _omitFieldNames ? '' : 'refHash')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TestMetadataDetail clone() => TestMetadataDetail()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TestMetadataDetail copyWith(void Function(TestMetadataDetail) updates) =>
      super.copyWith((message) => updates(message as TestMetadataDetail)) as TestMetadataDetail;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestMetadataDetail create() => TestMetadataDetail._();
  TestMetadataDetail createEmptyInstance() => create();
  static $pb.PbList<TestMetadataDetail> createRepeated() => $pb.PbList<TestMetadataDetail>();
  @$core.pragma('dart2js:noInline')
  static TestMetadataDetail getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestMetadataDetail>(create);
  static TestMetadataDetail? _defaultInstance;

  ///  Can be used to refer to a test metadata, e.g. in ResultDB.QueryTestMetadata
  ///  RPC.
  ///  Format:
  ///  "projects/{PROJECT}/refs/{REF_HASH}/tests/{URL_ESCAPED_TEST_ID}".
  ///  where URL_ESCAPED_TEST_ID is test_id escaped with
  ///  https://golang.org/pkg/net/url/#PathEscape. See also https://aip.dev/122.
  ///
  ///  Output only.
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

  /// The LUCI project.
  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  /// A unique identifier of a test in a LUCI project.
  /// Refer to TestResult.test_id for details.
  @$pb.TagNumber(3)
  $core.String get testId => $_getSZ(2);
  @$pb.TagNumber(3)
  set testId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTestId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTestId() => clearField(3);

  /// A reference in the source control system where the test metadata comes from.
  @$pb.TagNumber(4)
  $0.SourceRef get sourceRef => $_getN(3);
  @$pb.TagNumber(4)
  set sourceRef($0.SourceRef v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasSourceRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceRef() => clearField(4);
  @$pb.TagNumber(4)
  $0.SourceRef ensureSourceRef() => $_ensure(3);

  /// Test metadata content.
  @$pb.TagNumber(5)
  TestMetadata get testMetadata => $_getN(4);
  @$pb.TagNumber(5)
  set testMetadata(TestMetadata v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTestMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearTestMetadata() => clearField(5);
  @$pb.TagNumber(5)
  TestMetadata ensureTestMetadata() => $_ensure(4);

  /// Hexadecimal encoded hash string of the source_ref.
  /// A given source_ref always hashes to the same ref_hash value.
  @$pb.TagNumber(12)
  $core.String get refHash => $_getSZ(5);
  @$pb.TagNumber(12)
  set refHash($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasRefHash() => $_has(5);
  @$pb.TagNumber(12)
  void clearRefHash() => clearField(12);
}

/// Information about a test.
class TestMetadata extends $pb.GeneratedMessage {
  factory TestMetadata({
    $core.String? name,
    TestLocation? location,
    BugComponent? bugComponent,
    $core.String? propertiesSchema,
    $1.Struct? properties,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (location != null) {
      $result.location = location;
    }
    if (bugComponent != null) {
      $result.bugComponent = bugComponent;
    }
    if (propertiesSchema != null) {
      $result.propertiesSchema = propertiesSchema;
    }
    if (properties != null) {
      $result.properties = properties;
    }
    return $result;
  }
  TestMetadata._() : super();
  factory TestMetadata.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TestMetadata.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestMetadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<TestLocation>(2, _omitFieldNames ? '' : 'location', subBuilder: TestLocation.create)
    ..aOM<BugComponent>(3, _omitFieldNames ? '' : 'bugComponent', subBuilder: BugComponent.create)
    ..aOS(4, _omitFieldNames ? '' : 'propertiesSchema')
    ..aOM<$1.Struct>(5, _omitFieldNames ? '' : 'properties', subBuilder: $1.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TestMetadata clone() => TestMetadata()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TestMetadata copyWith(void Function(TestMetadata) updates) =>
      super.copyWith((message) => updates(message as TestMetadata)) as TestMetadata;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestMetadata create() => TestMetadata._();
  TestMetadata createEmptyInstance() => create();
  static $pb.PbList<TestMetadata> createRepeated() => $pb.PbList<TestMetadata>();
  @$core.pragma('dart2js:noInline')
  static TestMetadata getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestMetadata>(create);
  static TestMetadata? _defaultInstance;

  /// The original test name.
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

  /// Where the test is defined, e.g. the file name.
  /// location.repo MUST be specified.
  @$pb.TagNumber(2)
  TestLocation get location => $_getN(1);
  @$pb.TagNumber(2)
  set location(TestLocation v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLocation() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocation() => clearField(2);
  @$pb.TagNumber(2)
  TestLocation ensureLocation() => $_ensure(1);

  /// The issue tracker component associated with the test, if any.
  /// Bugs related to the test may be filed here.
  @$pb.TagNumber(3)
  BugComponent get bugComponent => $_getN(2);
  @$pb.TagNumber(3)
  set bugComponent(BugComponent v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBugComponent() => $_has(2);
  @$pb.TagNumber(3)
  void clearBugComponent() => clearField(3);
  @$pb.TagNumber(3)
  BugComponent ensureBugComponent() => $_ensure(2);

  /// Identifies the schema of the JSON object in the properties field.
  /// Use the fully-qualified name of the source protocol buffer.
  /// eg. chromiumos.test.api.TestCaseInfo
  /// ResultDB will *not* validate the properties field with respect to this
  /// schema. Downstream systems may however use this field to inform how the
  /// properties field is interpreted.
  @$pb.TagNumber(4)
  $core.String get propertiesSchema => $_getSZ(3);
  @$pb.TagNumber(4)
  set propertiesSchema($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPropertiesSchema() => $_has(3);
  @$pb.TagNumber(4)
  void clearPropertiesSchema() => clearField(4);

  ///  Arbitrary JSON object that contains structured, domain-specific properties
  ///  of the test.
  ///
  ///  The serialized size must be <= 4096 bytes.
  ///
  ///  If this field is specified, properties_schema must also be specified.
  @$pb.TagNumber(5)
  $1.Struct get properties => $_getN(4);
  @$pb.TagNumber(5)
  set properties($1.Struct v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasProperties() => $_has(4);
  @$pb.TagNumber(5)
  void clearProperties() => clearField(5);
  @$pb.TagNumber(5)
  $1.Struct ensureProperties() => $_ensure(4);
}

/// Location of the test definition.
class TestLocation extends $pb.GeneratedMessage {
  factory TestLocation({
    $core.String? repo,
    $core.String? fileName,
    $core.int? line,
  }) {
    final $result = create();
    if (repo != null) {
      $result.repo = repo;
    }
    if (fileName != null) {
      $result.fileName = fileName;
    }
    if (line != null) {
      $result.line = line;
    }
    return $result;
  }
  TestLocation._() : super();
  factory TestLocation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TestLocation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestLocation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'repo')
    ..aOS(2, _omitFieldNames ? '' : 'fileName')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'line', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TestLocation clone() => TestLocation()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TestLocation copyWith(void Function(TestLocation) updates) =>
      super.copyWith((message) => updates(message as TestLocation)) as TestLocation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestLocation create() => TestLocation._();
  TestLocation createEmptyInstance() => create();
  static $pb.PbList<TestLocation> createRepeated() => $pb.PbList<TestLocation>();
  @$core.pragma('dart2js:noInline')
  static TestLocation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestLocation>(create);
  static TestLocation? _defaultInstance;

  /// Gitiles URL as the identifier for a repo.
  /// Format for Gitiles URL: https://<host>/<project>
  /// For example "https://chromium.googlesource.com/chromium/src"
  /// Must not end with ".git".
  /// SHOULD be specified.
  @$pb.TagNumber(1)
  $core.String get repo => $_getSZ(0);
  @$pb.TagNumber(1)
  set repo($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRepo() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepo() => clearField(1);

  /// Name of the file where the test is defined.
  /// For files in a repository, must start with "//"
  /// Example: "//components/payments/core/payment_request_data_util_unittest.cc"
  /// Max length: 512.
  /// MUST not use backslashes.
  /// Required.
  @$pb.TagNumber(2)
  $core.String get fileName => $_getSZ(1);
  @$pb.TagNumber(2)
  set fileName($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFileName() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileName() => clearField(2);

  /// One-based line number where the test is defined.
  @$pb.TagNumber(3)
  $core.int get line => $_getIZ(2);
  @$pb.TagNumber(3)
  set line($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLine() => $_has(2);
  @$pb.TagNumber(3)
  void clearLine() => clearField(3);
}

enum BugComponent_System { issueTracker, monorail, notSet }

/// Represents a component in an issue tracker. A component is
/// a container for issues.
class BugComponent extends $pb.GeneratedMessage {
  factory BugComponent({
    IssueTrackerComponent? issueTracker,
    MonorailComponent? monorail,
  }) {
    final $result = create();
    if (issueTracker != null) {
      $result.issueTracker = issueTracker;
    }
    if (monorail != null) {
      $result.monorail = monorail;
    }
    return $result;
  }
  BugComponent._() : super();
  factory BugComponent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BugComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BugComponent_System> _BugComponent_SystemByTag = {
    1: BugComponent_System.issueTracker,
    2: BugComponent_System.monorail,
    0: BugComponent_System.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BugComponent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<IssueTrackerComponent>(1, _omitFieldNames ? '' : 'issueTracker', subBuilder: IssueTrackerComponent.create)
    ..aOM<MonorailComponent>(2, _omitFieldNames ? '' : 'monorail', subBuilder: MonorailComponent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BugComponent clone() => BugComponent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BugComponent copyWith(void Function(BugComponent) updates) =>
      super.copyWith((message) => updates(message as BugComponent)) as BugComponent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BugComponent create() => BugComponent._();
  BugComponent createEmptyInstance() => create();
  static $pb.PbList<BugComponent> createRepeated() => $pb.PbList<BugComponent>();
  @$core.pragma('dart2js:noInline')
  static BugComponent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BugComponent>(create);
  static BugComponent? _defaultInstance;

  BugComponent_System whichSystem() => _BugComponent_SystemByTag[$_whichOneof(0)]!;
  void clearSystem() => clearField($_whichOneof(0));

  /// The Google Issue Tracker component.
  @$pb.TagNumber(1)
  IssueTrackerComponent get issueTracker => $_getN(0);
  @$pb.TagNumber(1)
  set issueTracker(IssueTrackerComponent v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIssueTracker() => $_has(0);
  @$pb.TagNumber(1)
  void clearIssueTracker() => clearField(1);
  @$pb.TagNumber(1)
  IssueTrackerComponent ensureIssueTracker() => $_ensure(0);

  /// The monorail component.
  @$pb.TagNumber(2)
  MonorailComponent get monorail => $_getN(1);
  @$pb.TagNumber(2)
  set monorail(MonorailComponent v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMonorail() => $_has(1);
  @$pb.TagNumber(2)
  void clearMonorail() => clearField(2);
  @$pb.TagNumber(2)
  MonorailComponent ensureMonorail() => $_ensure(1);
}

/// A component in Google Issue Tracker, sometimes known as Buganizer,
/// available at https://issuetracker.google.com.
class IssueTrackerComponent extends $pb.GeneratedMessage {
  factory IssueTrackerComponent({
    $fixnum.Int64? componentId,
  }) {
    final $result = create();
    if (componentId != null) {
      $result.componentId = componentId;
    }
    return $result;
  }
  IssueTrackerComponent._() : super();
  factory IssueTrackerComponent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory IssueTrackerComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'IssueTrackerComponent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'componentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  IssueTrackerComponent clone() => IssueTrackerComponent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  IssueTrackerComponent copyWith(void Function(IssueTrackerComponent) updates) =>
      super.copyWith((message) => updates(message as IssueTrackerComponent)) as IssueTrackerComponent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IssueTrackerComponent create() => IssueTrackerComponent._();
  IssueTrackerComponent createEmptyInstance() => create();
  static $pb.PbList<IssueTrackerComponent> createRepeated() => $pb.PbList<IssueTrackerComponent>();
  @$core.pragma('dart2js:noInline')
  static IssueTrackerComponent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IssueTrackerComponent>(create);
  static IssueTrackerComponent? _defaultInstance;

  /// The Google Issue Tracker component ID.
  @$pb.TagNumber(1)
  $fixnum.Int64 get componentId => $_getI64(0);
  @$pb.TagNumber(1)
  set componentId($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasComponentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearComponentId() => clearField(1);
}

/// A component in monorail issue tracker, available at
/// https://bugs.chromium.org.
class MonorailComponent extends $pb.GeneratedMessage {
  factory MonorailComponent({
    $core.String? project,
    $core.String? value,
  }) {
    final $result = create();
    if (project != null) {
      $result.project = project;
    }
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  MonorailComponent._() : super();
  factory MonorailComponent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MonorailComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MonorailComponent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MonorailComponent clone() => MonorailComponent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MonorailComponent copyWith(void Function(MonorailComponent) updates) =>
      super.copyWith((message) => updates(message as MonorailComponent)) as MonorailComponent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MonorailComponent create() => MonorailComponent._();
  MonorailComponent createEmptyInstance() => create();
  static $pb.PbList<MonorailComponent> createRepeated() => $pb.PbList<MonorailComponent>();
  @$core.pragma('dart2js:noInline')
  static MonorailComponent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MonorailComponent>(create);
  static MonorailComponent? _defaultInstance;

  /// The monorail project name.
  @$pb.TagNumber(1)
  $core.String get project => $_getSZ(0);
  @$pb.TagNumber(1)
  set project($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => clearField(1);

  /// The monorail component value. E.g. "Blink>Accessibility".
  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
