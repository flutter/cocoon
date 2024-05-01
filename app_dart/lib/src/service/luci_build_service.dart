// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';

import '../model/luci/push_message.dart' as push_message;
import '../model/luci/buildbucket.dart';
import 'build_bucket_v2_client.dart';

/// Class to interact with LUCI buildbucket to get, trigger
/// and cancel builds for github repos. It uses [config.luciTryBuilders] to
/// get the list of available builders.
class LuciBuildService {
  LuciBuildService({
    required this.buildBucketClient,
    required this.buildBucketV2Client,
  });

  BuildBucketClient buildBucketClient;
  BuildBucketV2Client buildBucketV2Client;

  /// Sends [ScheduleBuildRequest] using information from a given build's
  /// [BuildPushMessage].
  ///
  /// The buildset, user_agent, and github_link tags are applied to match the
  /// original build. The build properties and user data from the original build
  /// are also preserved.
  ///
  /// The [currentAttempt] is used to track the number of current build attempt.
  Future<Build> rescheduleBuild({
    required String builderName,
    required push_message.BuildPushMessage buildPushMessage,
    required int rescheduleAttempt,
  }) async {
    // Ensure we are using V2 bucket name istead of V1.
    // V1 bucket name  is "luci.flutter.prod" while the api
    // is expecting just the last part after "."(prod).
    final String bucketName = buildPushMessage.build!.bucket!.split('.').last;
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': buildPushMessage.build!.tagsByName('buildset'),
      'user_agent': buildPushMessage.build!.tagsByName('user_agent'),
      'github_link': buildPushMessage.build!.tagsByName('github_link'),
      'cipd_version': buildPushMessage.build!.tagsByName('cipd_version'),
      'github_checkrun': buildPushMessage.build!.tagsByName('github_checkrun'),
      'current_attempt': <String>[rescheduleAttempt.toString()],
    };
    return buildBucketClient.scheduleBuild(
      ScheduleBuildRequest(
        builderId: BuilderId(
          project: buildPushMessage.build!.project,
          bucket: bucketName,
          builder: builderName,
        ),
        tags: tags,
        // We need to cast to <String, Object> to bypass json.encode error when scheduling builds.
        properties:
            (buildPushMessage.build!.buildParameters!['properties'] as Map<String, Object?>).cast<String, Object>(),
        notify: NotificationConfig(
          pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
          userData: base64Encode(json.encode(buildPushMessage.userData).codeUnits),
        ),
      ),
    );
  }
}
