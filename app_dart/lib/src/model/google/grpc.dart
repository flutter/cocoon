// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import '../../request_handling/body.dart';

part 'grpc.g.dart';

/// [Status] defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs. It is
/// used by [gRPC](https://github.com/grpc). Each [Status] message contains
/// three pieces of data: error code, error message, and error details.
///
/// Resources:
/// * https://cloud.google.com/apis/design/errors
@JsonSerializable(includeIfNull: false)
class GrpcStatus extends JsonBody {
  const GrpcStatus({required this.code, this.message, this.details});

  /// Creates a [Status] from JSON.
  static GrpcStatus fromJson(Map<String, dynamic> json) =>
      _$GrpcStatusFromJson(json);

  /// The status code, which should be an enum value of [google.rpc.Code][].
  final int code;

  /// A developer-facing error message, which should be in English. Any
  /// user-facing error message should be localized and sent in the
  /// [google.rpc.Status.details][] field, or localized by the client.
  final String? message;

  /// A list of messages that carry the error details.  There is a common set of
  /// message types for APIs to use.
  final dynamic details;

  @override
  String toString() => 'Response #$code: $message, $details';

  @override
  Map<String, dynamic> toJson() => _$GrpcStatusToJson(this);
}
