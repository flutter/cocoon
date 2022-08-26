// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/luci/push_message.dart';

import 'package:test/test.dart';

void main() {
  test('BuildPushMessage.fromJson', () {
    final BuildPushMessage data = BuildPushMessage.fromJson(
      json.decode(buildPushMessageJson) as Map<String, dynamic>,
    );

    // TODO(chillers): This fails in EMEA timezones. Prefer using UTC instead of local.
    expect(data.build!.createdTimestamp!.year, 2019);
    expect(data.build!.createdTimestamp!.month, 8);
    expect(data.build!.createdTimestamp!.day, 5);

    expect(data.build!.tags!.length, 11);
    expect(data.build!.tagsByName('builder').single, 'Linux Coverage');
    expect(data.build!.tagsByName('buildset'), const <String>[
      'pr/git/37647',
      'sha/git/0d78fc94f890a64af140ce0a2671ac5fc636f59b',
    ]);
  });
}

const String buildPushMessageJson = '''{
  "build": {
    "bucket": "luci.flutter.prod",
    "canary": false,
    "canary_preference": "PROD",
    "created_by": "user:dnfield@google.com",
    "created_ts": "1565049186247524",
    "experimental": true,
    "id": "8905920700440101120",
    "parameters_json": "{\\"builder_name\\": \\"Linux Coverage\\", \\"properties\\": {\\"git_ref\\": \\"refs/pull/37647/head\\", \\"git_url\\": \\"https://github.com/flutter/flutter\\"}}",
    "project": "flutter",
    "result_details_json": "{\\"properties\\": {}, \\"swarming\\": {\\"bot_dimensions\\": {\\"caches\\": [\\"flutter_openjdk_install\\", \\"git\\", \\"goma_v2\\", \\"vpython\\"], \\"cores\\": [\\"8\\"], \\"cpu\\": [\\"x86\\", \\"x86-64\\", \\"x86-64-Broadwell_GCE\\", \\"x86-64-avx2\\"], \\"gce\\": [\\"1\\"], \\"gpu\\": [\\"none\\"], \\"id\\": [\\"luci-flutter-prod-xenial-2-bnrz\\"], \\"image\\": [\\"chrome-xenial-19052201-9cb74617499\\"], \\"inside_docker\\": [\\"0\\"], \\"kvm\\": [\\"1\\"], \\"locale\\": [\\"en_US.UTF-8\\"], \\"machine_type\\": [\\"n1-standard-8\\"], \\"os\\": [\\"Linux\\", \\"Ubuntu\\", \\"Ubuntu-16.04\\"], \\"pool\\": [\\"luci.flutter.prod\\"], \\"python\\": [\\"2.7.12\\"], \\"server_version\\": [\\"4382-5929880\\"], \\"ssd\\": [\\"0\\"], \\"zone\\": [\\"us\\", \\"us-central\\", \\"us-central1\\", \\"us-central1-c\\"]}}}",
    "service_account": "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com",
    "started_ts": "1565049193786080",
    "status": "STARTED",
    "status_changed_ts": "1565049194386647",
    "tags": [
      "build_address:luci.flutter.prod/Linux Coverage/1698",
      "builder:Linux Coverage",
      "buildset:pr/git/37647",
      "buildset:sha/git/0d78fc94f890a64af140ce0a2671ac5fc636f59b",
      "swarming_hostname:chromium-swarm.appspot.com",
      "swarming_tag:log_location:logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket.appspot.com/8905920700440101120/+/annotations",
      "swarming_tag:luci_project:flutter",
      "swarming_tag:os:Linux",
      "swarming_tag:recipe_name:flutter/flutter",
      "swarming_tag:recipe_package:infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
      "swarming_task_id:467d04f2f022d510"
    ],
    "updated_ts": "1565049194391321",
    "url": "https://ci.chromium.org/b/8905920700440101120",
    "utcnow_ts": "1565049194653640"
  },
  "hostname": "cr-buildbucket.appspot.com",
  "user_data": ""
}''';
