//
//  Generated code. Do not modify.
//  source: internal/github_webhook.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// For full spec, see:
///   * https://docs.github.com/webhooks-and-events/webhooks/webhook-events-and-payloads
class GithubWebhookMessage extends $pb.GeneratedMessage {
  factory GithubWebhookMessage({
    $core.String? event,
    $core.String? payload,
  }) {
    final $result = create();
    if (event != null) {
      $result.event = event;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    return $result;
  }
  GithubWebhookMessage._() : super();
  factory GithubWebhookMessage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GithubWebhookMessage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GithubWebhookMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cocoon'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'event')
    ..aOS(2, _omitFieldNames ? '' : 'payload')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GithubWebhookMessage clone() =>
      GithubWebhookMessage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GithubWebhookMessage copyWith(void Function(GithubWebhookMessage) updates) =>
      super.copyWith((message) => updates(message as GithubWebhookMessage))
          as GithubWebhookMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GithubWebhookMessage create() => GithubWebhookMessage._();
  GithubWebhookMessage createEmptyInstance() => create();
  static $pb.PbList<GithubWebhookMessage> createRepeated() =>
      $pb.PbList<GithubWebhookMessage>();
  @$core.pragma('dart2js:noInline')
  static GithubWebhookMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GithubWebhookMessage>(create);
  static GithubWebhookMessage? _defaultInstance;

  /// X-GitHub-Event HTTP Header indicating the webhook action.
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

  /// JSON encoded webhook payload from GitHub.
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

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
