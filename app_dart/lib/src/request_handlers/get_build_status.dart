// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';

const Map<BuildStatus, String> _buildStatusLookup = <BuildStatus, String>{
  BuildStatus.succeeded: Task.statusSucceeded,
  BuildStatus.failed: Task.statusFailed,
};

@immutable
class GetBuildStatus extends RequestHandler<Body> {
  const GetBuildStatus(
    Config config, {
    @visibleForTesting BuildStatusProvider buildStatusProvider,
  })  : buildStatusProvider =
            buildStatusProvider ?? const BuildStatusProvider(),
        super(config: config);

  final BuildStatusProvider buildStatusProvider;

  static const String branchParam = 'branch';

  @override
  Future<Body> get() async {
    final String branch = request.uri.queryParameters[branchParam] ?? 'master';
    final BuildStatus status =
        await buildStatusProvider.calculateCumulativeStatus(branch: branch);

    return Body.forJson(<String, dynamic>{
      'AnticipatedBuildStatus': _buildStatusLookup[status],
    });
  }
}
