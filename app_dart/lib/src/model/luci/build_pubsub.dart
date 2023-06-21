import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart' as build_bucket;
import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:json_annotation/json_annotation.dart';

part 'build_pubsub.g.dart';


@JsonSerializable(includeIfNull: false)
class BuildV2PubSub extends JsonBody {
  const BuildV2PubSub({
    this.build,
    String? buildLargeFields,
    this.compression,
  }) : rawBuildLargeFields = buildLargeFields;

  final build_bucket.Build? build;

  @Base64Converter()
  final String? rawBuildLargeFields;

  final build_bucket.Compression? compression;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}

@JsonSerializable(includeIfNull: false)
class PubSubCallBack extends JsonBody {
  const PubSubCallBack({
    this.buildV2PubSub,
    String? userData,
  }) : rawUserData = userData;

  final BuildV2PubSub? buildV2PubSub;

  final String? rawUserData;

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

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
}
