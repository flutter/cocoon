// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/luci/buildbucket.dart';

void main() {
  const String tagsJson = '['
      '{"key":"tag_a","value":"chrome/win32-builder-perf"},'
      '{"key":"tag_b","value":"true"},'
      '{"key":"tag_b","value":"9083774268329986752"}'
      ']';

  const Map<String, List<String>> tags = <String, List<String>>{
    'tag_a': <String>['chrome/win32-builder-perf'],
    'tag_b': <String>['true', '9083774268329986752'],
  };

  test('Deserializes tags', () {
    final List<dynamic> decodedTags = json.decode(tagsJson) as List<dynamic>;
    expect(const TagsConverter().fromJson(decodedTags), tags);
  });

  test('Serializes tags', () {
    final List<Map<String, String>> encodedTags =
        const TagsConverter().toJson(tags).cast<Map<String, String>>().toList();
    expect(encodedTags.length, 3);
    expect(json.encode(encodedTags), tagsJson);
  });

  test('Handles Build id correctly', () {
    const int id = 0xFFFFFFFFFFFFFFFF; // would overflow a 32 bit int
    const Build build = Build(id: id, builderId: BuilderId());
    final Map<String, dynamic> buildJson = build.toJson();
    expect(buildJson['id'], id.toString());
    expect(buildJson['id'].runtimeType, String);

    final Build deserializedBuild =
        Build.fromJson(json.decode(json.encode(buildJson)) as Map<String, dynamic>);
    expect(deserializedBuild.id, id);

    const GetBuildRequest request = GetBuildRequest(id: id);
    final Map<String, dynamic> requestBuildJson = request.toJson();
    expect(requestBuildJson['id'], id.toString());
    expect(requestBuildJson['id'].runtimeType, String);

    final GetBuildRequest deserializedRequest =
        GetBuildRequest.fromJson(requestBuildJson);
    expect(deserializedRequest.id, id);
  });
}
