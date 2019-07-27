// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import 'package:cocoon_service/src/model/luci/buildbucket.dart';

void main() {
  const String tagsJson = '['
      '{"key":"scheduler_job_id","value":"chrome/win32-builder-perf"},'
      '{"key":"scheduler_invocation_id","value":"9083774268329986752"}'
      ']';

  const Map<String, String> tags = <String, String>{
    'scheduler_job_id': 'chrome/win32-builder-perf',
    'scheduler_invocation_id': '9083774268329986752',
  };

  test('Deserializes tags', () {
    final List<dynamic> decodedTags = json.decode(tagsJson) as List<dynamic>;
    expect(tagsFromJson(decodedTags), tags);
  });

  test('Serializes tags', () {
    final List<Map<String, String>> encodedTags = tagsToJson(tags);
    expect(encodedTags.length, 2);
    expect(json.encode(encodedTags), tagsJson);
  });

  test('Handles Build id correctly', () {
    int id = 0xFFFFFFFFFFFFFFFF; // would overflow a 32 bit int
    final Build build = Build(id: id);
    final Map<String, dynamic> buildJson = build.toJson();
    expect(buildJson['id'], id.toString());
    expect(buildJson['id'].runtimeType, String);

    final Build deserializedBuild = Build.fromJson(buildJson);
    expect(deserializedBuild.id, id);

    final GetBuildRequest request = GetBuildRequest(id: id);
    final Map<String, dynamic> requestBuildJson = request.toJson();
    expect(requestBuildJson['id'], id.toString());
    expect(requestBuildJson['id'].runtimeType, String);

    final GetBuildRequest deserializedRequest = GetBuildRequest.fromJson(requestBuildJson);
    expect(deserializedRequest.id, id);
  });
}
