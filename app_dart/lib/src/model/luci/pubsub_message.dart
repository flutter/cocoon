// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pubsub_message.g.dart';

// TODO (ricardoamador) look to see how this can be removed in favor of the gcloud lib pub/sub.
// the initial finding is that it may be an issue with how gcloud packages the
// message.
@JsonSerializable(includeIfNull: false)
class PubSubPushMessage extends JsonBody {
  const PubSubPushMessage({
    this.message,
    this.subscription,
  });

  static PubSubPushMessage fromJson(Map<String, dynamic> json) => _$PubSubPushMessageFromJson(json);

  /// The message contents.
  final PushMessage? message;

  /// The name of the subscription associated with the delivery.
  final String? subscription;

  @override
  Map<String, dynamic> toJson() => _$PubSubPushMessageToJson(this);
}

// Rename this to PushMessage as it is basically that class.
@JsonSerializable(includeIfNull: false)
class PushMessage extends JsonBody {
  const PushMessage({
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

  static PushMessage fromJson(Map<String, dynamic> json) => _$PushMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PushMessageToJson(this);
}
