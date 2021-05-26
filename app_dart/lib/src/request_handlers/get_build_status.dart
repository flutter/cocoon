// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/protos.dart' show BuildStatusResponse, EnumBuildStatus;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../protos.dart' show BuildStatusResponse, EnumBuildStatus;
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';
import '../service/datastore.dart';

@immutable
class GetBuildStatus extends RequestHandler<Body> {
  const GetBuildStatus(
    Config config, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting BuildStatusServiceProvider buildStatusProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusProvider = buildStatusProvider ?? BuildStatusService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String branchParam = 'branch';
  static const String repoParam = 'repo';

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusProvider(datastore);
    final String branch = request.uri.queryParameters[branchParam] ?? config.defaultBranch;
    final RepositorySlug repoSlug =
        RepositorySlug.full(request.uri.queryParameters[repoParam] ?? config.flutterSlug.fullName);
    final BuildStatus status = await buildStatusService.calculateCumulativeStatus(branch: branch, repoSlug: repoSlug);
    final BuildStatusResponse response = BuildStatusResponse()
      ..buildStatus = status.succeeded ? EnumBuildStatus.success : EnumBuildStatus.failure
      ..failingTasks.addAll(status.failedTasks);

    return Body.forJson(response.writeToJsonMap());
  }
}
