// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// CreateEvent model that is generated from GitHub Create event webhook.
///
/// See more:
///  * https://docs.github.com/en/developers/webhooks-and-events/events/github-event-types#createevent
import 'package:github/github.dart' show Repository, User;
import 'package:github/hooks.dart' show HookEvent;
import 'package:json_annotation/json_annotation.dart';

part 'create_event.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateEvent extends HookEvent {
  CreateEvent({
    this.ref,
    this.refType,
    this.pusherType,
    this.repository,
    this.sender,
  });

  factory CreateEvent.fromJson(Map<String, dynamic> input) => _$CreateEventFromJson(input);
  String? ref;
  String? refType;
  String? pusherType;
  Repository? repository;
  User? sender;

  Map<String, dynamic> toJson() => _$CreateEventToJson(this);
}
