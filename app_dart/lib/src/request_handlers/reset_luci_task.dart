// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/luci/buildbucket.dart' as bb;
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class ResetDevicelabTask extends ApiRequestHandler<Body> {
  const ResetDevicelabTask(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @required this.buildBucketClient,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final BuildBucketClient buildBucketClient;

  static const String luciBuilderNameParam = 'LuciBuilderName';
  static const String commitShaParam = 'CommitSha';

  @override
  Future<Body> post() async {
    checkRequiredParameters(<String>[luciBuilderNameParam, commitShaParam]);
    final String luciBuilderName = requestData[luciBuilderNameParam] as String;
    final String commitSha = requestData[commitShaParam] as String;
    await buildBucketClient.scheduleBuild(bb.ScheduleBuildRequest(
      builderId: bb.BuilderId(
        project: 'flutter',
        bucket: 'try',
        builder: luciBuilderName,
      ),
      gitilesCommit: GitilesCommit(
        host: 'chromium.googlesource.com',
        project: 'external/github.com/flutter/flutter',
        ref: 'refs/heads/master',
        hash: commitSha,
      ),
      tags: const <String, List<String>>{},
      properties: const <String, String>{},
      notify: bb.NotificationConfig(
        pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
        userData: json.encode(<String, dynamic>{
          'retries': 1,
        }),
      ),
    ));
    return Body.empty;
  }
}
