///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/github_webhook.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class GithubWebhookMessage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GithubWebhookMessage',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'cocoon'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'event')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'payload')
    ..hasRequiredFields = false;

  GithubWebhookMessage._() : super();
  factory GithubWebhookMessage({
    $core.String? event,
    $core.String? payload,
  }) {
    final _result = create();
    if (event != null) {
      _result.event = event;
    }
    if (payload != null) {
      _result.payload = payload;
    }
    return _result;
  }
  factory GithubWebhookMessage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GithubWebhookMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GithubWebhookMessage clone() => GithubWebhookMessage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GithubWebhookMessage copyWith(void Function(GithubWebhookMessage) updates) =>
      super.copyWith((message) => updates(message as GithubWebhookMessage))
          as GithubWebhookMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GithubWebhookMessage create() => GithubWebhookMessage._();
  GithubWebhookMessage createEmptyInstance() => create();
  static $pb.PbList<GithubWebhookMessage> createRepeated() => $pb.PbList<GithubWebhookMessage>();
  @$core.pragma('dart2js:noInline')
  static GithubWebhookMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GithubWebhookMessage>(create);
  static GithubWebhookMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get event => $_getSZ(0);
  @$pb.TagNumber(1)
  set event($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get payload => $_getSZ(1);
  @$pb.TagNumber(2)
  set payload($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => clearField(2);
}
