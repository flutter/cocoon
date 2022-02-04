// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../request_handling/body.dart';
import '../common/json_converters.dart';

part 'result_update_pushmessage.g.dart';

/// The task update data from a PubSub push message payload.
@JsonSerializable(includeIfNull: false)
class ResultUpdatePushMessage extends JsonBody {
  const ResultUpdatePushMessage({
    required this.sha,
    required this.branch,
    required this.slug,
    required this.name,
    required this.result,
    this.started,
    this.finished,
  });

  static ResultUpdatePushMessage fromJson(Map<String, dynamic> json) =>
      _$ResultUpdatePushMessageFromJson(json);

  final String sha;
  final String branch;
  final RepositorySlug slug;
  final String name;
  final String result;
  final DateTime? started;
  final DateTime? finished;

  @override
  Map<String, dynamic> toJson() => _$ResultUpdatePushMessageToJson(this);
}
