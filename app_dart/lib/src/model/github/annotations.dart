// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'annotations.g.dart';

/// Data models for json messages coming from GitHub Annotations.
@JsonSerializable(fieldRename: FieldRename.snake)
class Annotation {
  /// Support parsing directly from the API's `[{},]` response.
  static List<Annotation> fromJsonList(List<dynamic> input) =>
      input.whereType<Map<String, dynamic>>().map(Annotation.fromJson).toList();

  Annotation({this.annotationLevel, this.message});
  factory Annotation.fromJson(Map<String, dynamic> input) =>
      _$AnnotationFromJson(input);

  String? annotationLevel;
  String? message;

  Map<String, dynamic> toJson() => _$AnnotationToJson(this);

  @override
  String toString() {
    return '$Annotation ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}
