// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/cache_service.dart';

/// Trigger a cache flush on a config key.
@immutable
class FlushCache extends ApiRequestHandler<Body> {
  const FlushCache(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @required this.cache,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final CacheService cache;

  static const String cacheKeyParam = 'key';

  @override
  Future<Body> get() async {
    final String cacheKey = request.uri.queryParameters[cacheKeyParam];
    if (cacheKey == null) {
      throw const BadRequestException('Missing required query parameter: $cacheKeyParam');
    }

    await cache.purge(Config.configCacheName, cacheKey);

    return Body.empty;
  }
}
