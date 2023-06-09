// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Utilities to create PushMessages for testing.

import 'dart:convert';

import 'package:cocoon_service/src/model/luci/push_message.dart';

const String ref = 'deadbeef';

PushMessage createBuildbucketPushMessage(
  String status, {
  String? result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String? failureReason,
  String? userData = '',
}) {
  return PushMessage(
    data: buildPushMessageJson(
      status,
      result: result,
      builderName: builderName,
      urlParam: urlParam,
      retries: retries,
      failureReason: failureReason,
      userData: userData,
    ),
    messageId: '123',
  );
}

PushMessage pushMessageJsonNoBuildset(
  String status, {
  String? result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String? failureReason,
}) {
  return PushMessage(
    data: buildPushMessageJsonNoBuildset(
      status,
      result: result,
      builderName: builderName,
      urlParam: urlParam,
      retries: retries,
      failureReason: failureReason,
    ),
    messageId: '123',
  );
}

String buildPushMessageJson(
  String status, {
  String? result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String? failureReason,
  String? userData,
}) =>
    base64.encode(
      utf8.encode(
        buildPushMessageString(
          status,
          result: result,
          builderName: builderName,
          urlParam: urlParam,
          retries: retries,
          failureReason: failureReason,
          userData: userData,
        ),
      ),
    );

String buildPushMessageJsonNoBuildset(
  String status, {
  String? result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String? failureReason,
}) =>
    base64.encode(
      utf8.encode(
        buildPushMessageNoBuildsetString(
          status,
          result: result,
          builderName: builderName,
          urlParam: urlParam,
          retries: retries,
          failureReason: failureReason,
        ),
      ),
    );

String buildPushMessageString(
  String status, {
  String? result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String? failureReason,
  String? userData,
}) {
  return '''{
  "build": {
    "bucket": "luci.flutter.prod",
    "canary": false,
    "canary_preference": "PROD",
    "created_by": "user:dnfield@google.com",
    "created_ts": "1565049186247524",
    "completed_ts": "1565049193786090",
    "experimental": false,
    ${failureReason != null ? '"failure_reason": "$failureReason",' : ''}
    "id": "8905920700440101120",
    "parameters_json": "{\\"builder_name\\": \\"$builderName\\", \\"properties\\": {\\"git_ref\\": \\"refs/pull/37647/head\\", \\"git_url\\": \\"https://github.com/flutter/flutter\\"}}",
    "project": "flutter",
    ${result != null ? '"result": "$result",' : ''}
    "result_details_json": "{\\"properties\\": {}, \\"swarming\\": {\\"bot_dimensions\\": {\\"caches\\": [\\"flutter_openjdk_install\\", \\"git\\", \\"goma_v2\\", \\"vpython\\"], \\"cores\\": [\\"8\\"], \\"cpu\\": [\\"x86\\", \\"x86-64\\", \\"x86-64-Broadwell_GCE\\", \\"x86-64-avx2\\"], \\"gce\\": [\\"1\\"], \\"gpu\\": [\\"none\\"], \\"id\\": [\\"luci-flutter-prod-xenial-2-bnrz\\"], \\"image\\": [\\"chrome-xenial-19052201-9cb74617499\\"], \\"inside_docker\\": [\\"0\\"], \\"kvm\\": [\\"1\\"], \\"locale\\": [\\"en_US.UTF-8\\"], \\"machine_type\\": [\\"n1-standard-8\\"], \\"os\\": [\\"Linux\\", \\"Ubuntu\\", \\"Ubuntu-16.04\\"], \\"pool\\": [\\"luci.flutter.prod\\"], \\"python\\": [\\"2.7.12\\"], \\"server_version\\": [\\"4382-5929880\\"], \\"ssd\\": [\\"0\\"], \\"zone\\": [\\"us\\", \\"us-central\\", \\"us-central1\\", \\"us-central1-c\\"]}}}",
    "service_account": "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com",
    "started_ts": "1565049193786080",
    "status": "$status",
    "status_changed_ts": "1565049194386647",
    "tags": [
      "build_address:luci.flutter.prod/$builderName/1698",
      "builder:$builderName",
      "buildset:pr/git/37647",
      "buildset:sha/git/$ref",
      "github_link:https://github.com/flutter/flutter/pull/37647",
      "swarming_hostname:chromium-swarm.appspot.com",
      "swarming_tag:log_location:logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket.appspot.com/8905920700440101120/+/annotations",
      "swarming_tag:luci_project:flutter",
      "swarming_tag:os:Linux",
      "swarming_tag:recipe_name:flutter/flutter",
      "swarming_tag:recipe_package:infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
      "swarming_task_id:467d04f2f022d510",
      "user_agent:flutter-cocoon"
    ],
    "updated_ts": "1565049194391321",
    "url": "https://ci.chromium.org/b/8905920700440101120$urlParam",
    "utcnow_ts": "1565049194653640"
  },
  ${userData != null ? '"user_data": "$userData",' : ''}
  "hostname": "cr-buildbucket.appspot.com"
}''';
}

String buildPushMessageNoBuildsetString(
  String status, {
  String? result,
  String builderName = 'Linux Coverage',
  String urlParam = '',
  int retries = 0,
  String? failureReason,
}) {
  return '''{
  "build": {
    "bucket": "luci.flutter.prod",
    "canary": false,
    "canary_preference": "PROD",
    "created_by": "user:dnfield@google.com",
    "created_ts": "1565049186247524",
    "experimental": false,
    ${failureReason != null ? '"failure_reason": "$failureReason",' : ''}
    "id": "8905920700440101120",
    "parameters_json": "{\\"builder_name\\": \\"$builderName\\", \\"properties\\": {\\"git_ref\\": \\"refs/pull/37647/head\\", \\"git_url\\": \\"https://github.com/flutter/flutter\\"}}",
    "project": "flutter",
    ${result != null ? '"result": "$result",' : ''}
    "result_details_json": "{\\"properties\\": {}, \\"swarming\\": {\\"bot_dimensions\\": {\\"caches\\": [\\"flutter_openjdk_install\\", \\"git\\", \\"goma_v2\\", \\"vpython\\"], \\"cores\\": [\\"8\\"], \\"cpu\\": [\\"x86\\", \\"x86-64\\", \\"x86-64-Broadwell_GCE\\", \\"x86-64-avx2\\"], \\"gce\\": [\\"1\\"], \\"gpu\\": [\\"none\\"], \\"id\\": [\\"luci-flutter-prod-xenial-2-bnrz\\"], \\"image\\": [\\"chrome-xenial-19052201-9cb74617499\\"], \\"inside_docker\\": [\\"0\\"], \\"kvm\\": [\\"1\\"], \\"locale\\": [\\"en_US.UTF-8\\"], \\"machine_type\\": [\\"n1-standard-8\\"], \\"os\\": [\\"Linux\\", \\"Ubuntu\\", \\"Ubuntu-16.04\\"], \\"pool\\": [\\"luci.flutter.prod\\"], \\"python\\": [\\"2.7.12\\"], \\"server_version\\": [\\"4382-5929880\\"], \\"ssd\\": [\\"0\\"], \\"zone\\": [\\"us\\", \\"us-central\\", \\"us-central1\\", \\"us-central1-c\\"]}}}",
    "service_account": "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com",
    "started_ts": "1565049193786080",
    "status": "$status",
    "status_changed_ts": "1565049194386647",
    "tags": [
      "build_address:luci.flutter.prod/$builderName/1698",
      "builder:$builderName",
      "github_link:https://github.com/flutter/flutter/pull/37647",
      "swarming_hostname:chromium-swarm.appspot.com",
      "swarming_tag:log_location:logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket.appspot.com/8905920700440101120/+/annotations",
      "swarming_tag:luci_project:flutter",
      "swarming_tag:os:Linux",
      "swarming_tag:recipe_name:flutter/flutter",
      "swarming_tag:recipe_package:infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
      "swarming_task_id:467d04f2f022d510",
      "user_agent:flutter-cocoon"
    ],
    "updated_ts": "1565049194391321",
    "url": "https://ci.chromium.org/b/8905920700440101120$urlParam",
    "utcnow_ts": "1565049194653640"
  },
  "hostname": "cr-buildbucket.appspot.com",
  "user_data": "{\\"retries\\": $retries}"
}''';
}
