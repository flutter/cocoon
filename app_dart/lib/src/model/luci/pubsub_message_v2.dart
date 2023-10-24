import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pubsub_message_v2.g.dart';

// Rename this to PushMessage as it is basically that class.
@JsonSerializable(includeIfNull: false)
class PubSubMessageV2 extends JsonBody{
  const PubSubMessageV2({this.attributes, this.data, this.messageId, this.publishTime});

  /// PubSub attributes on the message.
  final Map<String, String>? attributes;

  @Base64Converter()
  final String? data;

  final String? messageId;

  final String? publishTime;

  static PubSubMessageV2 fromJson(Map<String, dynamic> json) => _$PubSubMessageV2FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PubSubMessageV2ToJson(this);
}