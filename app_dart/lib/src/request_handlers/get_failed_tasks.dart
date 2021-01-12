// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/service/datastore.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';

@immutable
class GetFailedTasks extends RequestHandler<Body> {
  const GetFailedTasks(
      Config config, {
        @visibleForTesting DatastoreServiceProvider datastoreProvider,
        @visibleForTesting BuildStatusServiceProvider buildStatusProvider,
      })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusProvider = buildStatusProvider ?? BuildStatusService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String branchParam = 'branch';

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusProvider(datastore);
    final String branch = request.uri.queryParameters[branchParam] ?? 'master';

    return Body.forJson(<String, dynamic>{
      'FailingTasks': await buildStatusService.getFailingTasks(branch: branch),
    });
  }
}
