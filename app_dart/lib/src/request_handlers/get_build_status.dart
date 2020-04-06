// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/service/datastore.dart';
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
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting BuildStatusServiceProvider buildStatusProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusProvider =
            buildStatusProvider ?? BuildStatusService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String branchParam = 'branch';

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(
        db: config.db, maxEntityGroups: config.maxEntityGroups);
    final BuildStatusService buildStatusService =
        buildStatusProvider(datastore);
    final String branch = request.uri.queryParameters[branchParam] ?? 'master';
    final BuildStatus status =
        await buildStatusService.calculateCumulativeStatus(branch: branch);

    return Body.forJson(<String, dynamic>{
      'AnticipatedBuildStatus': _buildStatusLookup[status],
    });
  }
}
