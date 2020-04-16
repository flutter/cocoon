// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/foundation/providers.dart';
import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:meta/meta.dart';

/// Synchronizes the performance benchmark data points in metrics center.
@immutable
class SyncMetricsCenter extends ApiRequestHandler<Body> {
  const SyncMetricsCenter(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;

  @override
  Future<Body> get() async {
    final Logging logger = loggingProvider();
    logger.debug('started syncing metrics center');

    return Body.empty;
  }
}
