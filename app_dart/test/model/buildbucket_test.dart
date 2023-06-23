// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:test/test.dart';

void main() {
  const String exeJson = '''
    {
      "cipdPackage": "infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
      "cipdVersion": "refs/heads/main",
      "cmd": [
              "luciexe"
      ]
    }''';

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
    final List<dynamic>? decodedTags = json.decode(tagsJson) as List<dynamic>?;
    expect(const TagsConverter().fromJson(decodedTags), tags);
  });

  test('Serializes tags', () {
    final List<Map<String, String>> encodedTags =
        const TagsConverter().toJson(tags)!.cast<Map<String, String>>().toList();
    expect(encodedTags.length, 3);
    expect(json.encode(encodedTags), tagsJson);
  });

  test('Handles Build id correctly', () {
    final String id = 0xFFFFFFFFFFFFFFFF.toString(); // would overflow a 32 bit int
    final Build build = Build(id: id, builderId: const BuilderId());
    final Map<String, dynamic> buildJson = build.toJson();
    expect(buildJson['id'], id.toString());
    expect(buildJson['id'].runtimeType, String);

    final Build deserializedBuild = Build.fromJson(json.decode(json.encode(buildJson)) as Map<String, dynamic>);
    expect(deserializedBuild.id, id);

    final GetBuildRequest request = GetBuildRequest(id: id);
    final Map<String, dynamic> requestBuildJson = request.toJson();
    expect(requestBuildJson['id'], id.toString());
    expect(requestBuildJson['id'].runtimeType, String);

    final GetBuildRequest deserializedRequest = GetBuildRequest.fromJson(requestBuildJson);
    expect(deserializedRequest.id, id);
  });

  test('Handles fields correctly', () {
    GetBuildRequest request = const GetBuildRequest(id: '9083774268329986752');
    Map<String, dynamic> requestBuildJson = request.toJson();
    expect(requestBuildJson['id'], request.id.toString());
    request = const GetBuildRequest(id: '9083774268329986752', fields: 'summaryMarkDown');
    requestBuildJson = request.toJson();
    expect(requestBuildJson['id'], request.id.toString());
    expect(requestBuildJson['fields'], 'summaryMarkDown');
  });

  test('Creates a ScheduleBuildRequest', () {
    const ScheduleBuildRequest req = ScheduleBuildRequest(
      builderId: BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: 'fake_builder',
      ),
      properties: <String, String>{
        'git_url': 'https://github.com/flutter/flutter',
        'git_ref': 'refs/pull/63834/head',
      },
      dimensions: <RequestedDimension>[RequestedDimension(key: 'a', value: 'b', expiration: '120s')],
      priority: 100,
    );
    expect(
        json.encode(req.toJson()),
        '{"builder":{"project":"flutter","bucket":"try","builder":"fake_builder"},'
        '"properties":{"git_url":"https://github.com/flutter/flutter","git_ref":"refs/pull/63834/head"},'
        '"dimensions":[{"key":"a","value":"b","expiration":"120s"}],"priority":100}');
  });

  test('Executable is handled correctly', () {
    final Executable exe = Executable.fromJson(jsonDecode(exeJson));
    expect(exe.cipdVersion, 'refs/heads/main');
    expect(exe.cipdPackage, 'infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build');
    expect(exe.cmd, ['luciexe']);
  });
}
