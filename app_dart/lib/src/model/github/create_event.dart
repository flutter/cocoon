// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Data models for json messages coming from GitHub Checks API.
///
/// See more:
///  * https://developer.com/v3/checks/.
import 'package:github/github.dart' show Repository;
import 'package:github/hooks.dart' show HookEvent;
import 'package:json_annotation/json_annotation.dart';

part 'create_event.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateEvent extends HookEvent {
  CreateEvent({
    this.ref,
    this.refType,
    this.masterBranch,
    this.repository,
  });

  factory CreateEvent.fromJson(Map<String, dynamic> input) => _$CreateEventFromJson(input);
  String? ref;
  String? refType;
  String? masterBranch;
  Repository? repository;

  Map<String, dynamic> toJson() => _$CreateEventToJson(this);
}
