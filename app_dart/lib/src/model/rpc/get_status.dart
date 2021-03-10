// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import '../appengine/agent.dart';
import '../appengine/commit_status.dart';

part 'get_status.g.dart';


@JsonSerializable()
class GetStatusResponse {
  GetStatusResponse({this.agents, this.statuses = const <CommitStatus>[]});

  factory GetStatusResponse.fromJson(Map<String, dynamic> json) => _$GetStatusResponseFromJson(json);

  final List<Agent> agents;
  final List<CommitStatus> statuses;

  Map<String, dynamic> toJson() => _$GetStatusResponseToJson(this);
}