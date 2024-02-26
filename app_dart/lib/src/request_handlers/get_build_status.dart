// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../protos.dart' show BuildStatusResponse, EnumBuildStatus;
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';

@immutable
class GetBuildStatus extends RequestHandler<Body> {
  const GetBuildStatus({
    required super.config,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
    @visibleForTesting BuildStatusServiceProvider? buildStatusProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusProvider = buildStatusProvider ?? BuildStatusService.defaultProvider;
  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final BuildStatusResponse response = await createResponse();
    return Body.forJson(response.writeToJsonMap());
  }

  Future<BuildStatusResponse> createResponse() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusProvider(datastore);
    final String repoName = request!.uri.queryParameters[kRepoParam] ?? 'flutter';
    final RepositorySlug slug = RepositorySlug('flutter', repoName);
    final BuildStatus status = (await buildStatusService.calculateCumulativeStatus(slug))!;
    return BuildStatusResponse()
      ..buildStatus = status.succeeded ? EnumBuildStatus.success : EnumBuildStatus.failure
      ..failingTasks.addAll(status.failedTasks);
  }
}
