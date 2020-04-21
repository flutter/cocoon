// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/foundation/providers.dart';
import 'package:cocoon_service/src/foundation/typedefs.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:meta/meta.dart';
import 'package:metrics_center/flutter.dart';

/// Synchronizes the performance benchmark data points in metrics center.
@immutable
class SyncMetricsCenter extends ApiRequestHandler<Body> {
  const SyncMetricsCenter(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting LoggingProvider loggingProvider,
  })  : loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        super(config: config, authenticationProvider: authenticationProvider);

  final LoggingProvider loggingProvider;

  @override
  Future<Body> get() async {
    final Logging logger = loggingProvider();
    logger.debug('Started syncing metrics center.');
    final Map<String, dynamic> serviceAccountJson =
        await config.metricsCenterServiceAccountJson;
    final FlutterCenter center =
        await FlutterCenter.makeDefault(serviceAccountJson);
    final int number = await center.synchronize();
    logger.debug('Number of points have been pulled or pushed: $number.');
    return Body.empty;
  }
}
