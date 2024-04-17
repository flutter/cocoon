// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pubsub_message_v2.g.dart';

// TODO (ricardoamador) look to see how this can be removed in favor of the gcloud lib pub/sub.
// the initial finding is that it may be an issue with how gcloud packages the
// message.
@JsonSerializable(includeIfNull: false)
class PubSubPushMessageV2 extends JsonBody {
  const PubSubPushMessageV2({
    this.message,
    this.subscription,
  });

  static PubSubPushMessageV2 fromJson(Map<String, dynamic> json) => _$PubSubPushMessageV2FromJson(json);

  /// The message contents.
  final PushMessageV2? message;

  /// The name of the subscription associated with the delivery.
  final String? subscription;

  @override
  Map<String, dynamic> toJson() => _$PubSubPushMessageV2ToJson(this);
}

// Rename this to PushMessage as it is basically that class.
@JsonSerializable(includeIfNull: false)
class PushMessageV2 extends JsonBody {
  const PushMessageV2({
    this.attributes,
    this.data,
    this.messageId,
    this.publishTime,
  });

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

  static PushMessageV2 fromJson(Map<String, dynamic> json) => _$PushMessageV2FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PushMessageV2ToJson(this);
}
