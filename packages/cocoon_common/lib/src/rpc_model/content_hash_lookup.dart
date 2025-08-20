// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';

part 'content_hash_lookup.g.dart';

@JsonSerializable(checked: true)
@immutable
final class ContentHashLookup extends Model {
  ContentHashLookup({required this.contentHash, required this.gitShas});

  factory ContentHashLookup.fromJson(Map<String, Object?> json) {
    return _$ContentHashLookupFromJson(json);
  }

  @JsonKey(name: 'contentHash')
  final String contentHash;

  @JsonKey(name: 'gitShas')
  final List<String> gitShas;

  @override
  Map<String, Object?> toJson() {
    return _$ContentHashLookupToJson(this);
  }
}
