// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../../request_handling/body.dart';
import '../../service/logging.dart';
import '../common/json_converters.dart';

part 'push_message.g.dart';

/// A Cloud PubSub push message.
///
/// For example:
/// ```json
/// {
///   "message": {
///     "attributes": {
///       "key": "value"
///     },
///     "data": "SGVsbG8gQ2xvdWQgUHViL1N1YiEgSGVyZSBpcyBteSBtZXNzYWdlIQ==",
///     "messageId": "136969346945"
///   },
///   "subscription": "projects/myproject/subscriptions/mysubscription"
/// }
/// ```
///
/// Where `data` is base64 encoded.
///
/// See https://cloud.google.com/pubsub/docs/push#receiving_push_messages
@JsonSerializable(includeIfNull: false)
class PushMessageEnvelope extends JsonBody {
  const PushMessageEnvelope({
    this.message,
    this.subscription,
  });

  static PushMessageEnvelope fromJson(Map<String, dynamic> json) => _$PushMessageEnvelopeFromJson(json);

  /// The message contents.
  final PushMessage? message;

  /// The name of the subscription associated with the delivery.
  final String? subscription;

  @override
  Map<String, dynamic> toJson() => _$PushMessageEnvelopeToJson(this);
}

/// A PubSub push message payload.
@JsonSerializable(includeIfNull: false)
class PushMessage extends JsonBody {
  const PushMessage({
    this.attributes,
    this.data,
    this.messageId,
    this.publishTime,
  });

  static PushMessage fromJson(Map<String, dynamic> json) => _$PushMessageFromJson(json);

  /// PubSub attributes on the message.
  final Map<String, String>? attributes;

  /// The raw string data of the message.
  @Base64Converter()
  final String? data;

  /// A identifier for the message from PubSub.
  final String? messageId;

  /// The time at which the message was published, populated by the server when
  /// it receives the topics.publish call.
  ///
  /// A timestamp in RFC3339 UTC "Zulu" format, with nanosecond resolution and
  /// up to nine fractional digits. Examples: "2014-10-02T15:01:23Z" and
  /// "2014-10-02T15:01:23.045123456Z".
  final String? publishTime;

  @override
  Map<String, dynamic> toJson() => _$PushMessageToJson(this);
}

/// The LUCI build data from a PubSub push message payload.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class BuildPushMessage extends JsonBody {
  const BuildPushMessage({
    this.build,
    this.hostname,
    String? userData,
  }) : rawUserData = userData;

  /// Create [BuildPushMessage] from [PushMessage].
  factory BuildPushMessage.fromPushMessage(PushMessage message) {
    final data = message.data;
    if (data == null) {
      throw const FormatException('Cannot create BuildPushMessage from null data');
    }

    try {
      final String decodedData = String.fromCharCodes(base64.decode(data));
      log.info('Result message from base64: $decodedData');
      return BuildPushMessage.fromJson(json.decode(decodedData) as Map<String, dynamic>);
    } on FormatException {
      log.info('Result message: $data');
      return BuildPushMessage.fromJson(json.decode(data) as Map<String, dynamic>);
    }
  }

  static BuildPushMessage fromJson(Map<String, dynamic> json) => _$BuildPushMessageFromJson(json);

  /// The Build this message is for.
  final Build? build;

  /// The hostname for the build, e.g. `cr-buildbucket.appspot.com`.
  final String? hostname;

  /// Do not use this value for anything.
  ///
  /// This value cannot be marked private due to json_serializable not
  /// generating on private fields.
  ///
  /// This value is used to generate [userData].
  @JsonKey(name: 'user_data')
  final String? rawUserData;

  /// User data that was included in the LUCI build request.
  Map<String, dynamic> get userData {
    if (rawUserData == null) {
      return <String, dynamic>{};
    }

    try {
      return json.decode(rawUserData!) as Map<String, dynamic>;
    } on FormatException {
      final Uint8List bytes = base64.decode(rawUserData!);
      final String rawJson = String.fromCharCodes(bytes);
      if (rawJson.isEmpty) {
        return <String, dynamic>{};
      }
      return json.decode(rawJson) as Map<String, dynamic>;
    }
  }

  @override
  Map<String, dynamic> toJson() => _$BuildPushMessageToJson(this);
}

/// See https://github.com/luci/luci-go/blob/master/common/api/buildbucket/buildbucket/v1/buildbucket-gen.go#L332ƒ
@JsonSerializable(includeIfNull: false)
class Build extends JsonBody {
  const Build({
    this.bucket,
    this.canary,
    this.canaryPreference,
    this.cancelationReason,
    this.completedTimestamp,
    this.createdBy,
    this.createdTimestamp,
    this.failureReason,
    this.experimental,
    this.id,
    this.buildParameters,
    this.project,
    this.result,
    this.resultDetails,
    this.serviceAccount,
    this.startedTimestamp,
    this.status,
    this.tags,
    this.updatedTimestamp,
    this.utcNowTimestamp,
    this.url,
  });

  static Build fromJson(Map<String, dynamic> json) => _$BuildFromJson(json);

  /// The BuildBucket name.
  final String? bucket;

  /// Whether carnary hardware was used.
  final bool? canary;

  /// The canary preference for `canary`.
  @JsonKey(name: 'canary_preference')
  final CanaryPreference? canaryPreference;

  /// The reason for canceling the build.
  @JsonKey(name: 'cancelation_reason')
  final CancelationReason? cancelationReason;

  /// The completion time of the build.
  @JsonKey(name: 'completed_ts')
  @MicrosecondsSinceEpochConverter()
  final DateTime? completedTimestamp;

  /// The user who created the build.
  @JsonKey(name: 'created_by')
  final String? createdBy;

  /// The creation time of the build.
  @JsonKey(name: 'created_ts')
  @MicrosecondsSinceEpochConverter()
  final DateTime? createdTimestamp;

  /// Whether the build was experimental or not.
  final bool? experimental;

  /// The reason the build failed, if it failed.
  @JsonKey(name: 'failure_reason')
  final FailureReason? failureReason;

  /// The unique BuildBucket ID for the build.
  final String? id;

  /// Parameters passed to the build.
  @JsonKey(name: 'parameters_json')
  @NestedJsonConverter()
  final Map<String, dynamic>? buildParameters;

  /// The BuildBucket project for the build, e.g. `flutter`.
  final String? project;

  /// The result of the build.
  ///
  /// If [Result.canceled], [cancelationReason] will be populated.
  ///
  /// If [Result.failure], [failureReason] will be populated.
  final Result? result;

  /// A JSON object that contains additional build information based on the
  /// result.
  @JsonKey(name: 'result_details_json')
  @NestedJsonConverter()
  final Map<String, dynamic>? resultDetails;

  /// The service account used for the build.
  @JsonKey(name: 'service_account')
  final String? serviceAccount;

  /// The time of the build start.
  @JsonKey(name: 'started_ts')
  @MicrosecondsSinceEpochConverter()
  final DateTime? startedTimestamp;

  /// The [Status] of the build.
  ///
  /// If [Status.completed], [result] will be populated.
  final Status? status;

  /// The swarming tags for the build.
  final List<String>? tags;

  /// Returns all tags matching the prefix.
  ///
  /// For example, to get the `buildset` tag(s), call `tagsByName('buildset')`;
  /// to get the `swarming_tag:os`, call `tagsByName('swarming_tag:os')`.
  List<String> tagsByName(String prefix) {
    return tags!
        .where((String tag) => tag.startsWith('$prefix:'))
        .map<String>((String tag) => tag.substring(prefix.length + 1))
        .toList();
  }

  /// The time of the last update to this information.
  @JsonKey(name: 'updated_ts')
  @MicrosecondsSinceEpochConverter()
  final DateTime? updatedTimestamp;

  /// The URL of the build.
  final String? url;

  /// The time used as UTC now for reference to other times in this message.
  @JsonKey(name: 'utcnow_ts')
  @MicrosecondsSinceEpochConverter()
  final DateTime? utcNowTimestamp;

  @override
  Map<String, dynamic> toJson() => _$BuildToJson(this);
}

/// The method to select whether canary hardware was chosen for a build.
enum CanaryPreference {
  @JsonValue('AUTO')
  auto,
  @JsonValue('CANARY')
  canary,
  @JsonValue('PROD')
  prod,
}

/// The reason for canceling a build.
enum CancelationReason {
  @JsonValue('CANCELED_EXPLICITLY')
  canceledExplicitly,
  @JsonValue('TIMEOUT')
  timeout,
}

/// The reason a build failed.
enum FailureReason {
  @JsonValue('BUILDBUCKET_FAILURE')
  buildbucketFailure,
  @JsonValue('BUILD_FAILURE')
  buildFailure,
  @JsonValue('INFRA_FAILURE')
  infraFailure,
  @JsonValue('INVALID_BUILD_DEFINITION')
  invalidBuildDefinition,
}

/// The final result of a build, if its [Status] is [Status.completed].
enum Result {
  @JsonValue('CANCELED')
  canceled,
  @JsonValue('FAILURE')
  failure,
  @JsonValue('INFRA_FAILURE')
  infraFailure,
  @JsonValue('SUCCESS')
  success,
}

/// The current status of a build.
///
/// If [Status.completed], then a [Result] will be present as well.
enum Status {
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('STARTED')
  started,
}
