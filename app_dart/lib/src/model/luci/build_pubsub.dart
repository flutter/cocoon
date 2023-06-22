import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:cocoon_service/src/model/luci/build_infra.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart' as build_bucket;
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:json_annotation/json_annotation.dart';

part 'build_pubsub.g.dart';

@JsonSerializable(includeIfNull: false)
class Build extends JsonBody {
  const Build({
    this.id,
    this.builder,
    this.builderInfo,
    this.number,
    this.createdBy,
    this.canceledBy,
    this.createTime,
    this.startTime,
    this.endTime,
    this.updateTime,
    this.cancelTime,
    this.status,
    this.summaryMarkdown,
    this.cancellationMarkdown,
    this.critical,
    this.input,
    this.output,
    this.steps,
    this.buildInfra,
    this.tags,
    this.exe,
    this.canary,
    this.schedulingTimeout,
    this.executionTimeout,
    this.gracePeriod,
    this.waitForCapacity,
    this.canOutliveParent,
    this.ancestorIds,
    this.retriable,
  });

  final int? id;
  final build_bucket.BuilderId? builder;
  final build_bucket.BuilderInfo? builderInfo;
  final int? number;
  final String? createdBy;
  final String? canceledBy;
  final DateTime? createTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? updateTime;
  final DateTime? cancelTime;
  final build_bucket.Status? status;
  final String? summaryMarkdown;
  final String? cancellationMarkdown;
  final build_bucket.Trinary? critical;
  final build_bucket.Input? input;
  final build_bucket.Output? output;
  final List<build_bucket.Step>? steps;
  final BuildInfra? buildInfra;
  // /// Used to return builds containing all of the specified tags.
  // tags are actually String pairs, one key may have multiple values.
  @TagsConverter()
  final Map<String?, List<String?>>? tags;
  final build_bucket.Executable? exe;
  final bool? canary;
  final Duration? schedulingTimeout;
  final Duration? executionTimeout;
  final Duration? gracePeriod;
  final bool? waitForCapacity;
  final bool? canOutliveParent;
  final List<int>? ancestorIds;
  final build_bucket.Trinary? retriable;

  @override
  Map<String, dynamic> toJson() => _$BuildToJson(this);

  static Build fromJson(Map<String, dynamic> json) => _$BuildFromJson(json);
}

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
  Map<String, dynamic> toJson() => _$BuildV2PubSubToJson(this);

  static BuildV2PubSub fromJson(Map<String, dynamic> json) => _$BuildV2PubSubFromJson(json);
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
