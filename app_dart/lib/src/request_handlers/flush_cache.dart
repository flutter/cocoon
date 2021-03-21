// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/cache_service.dart';

/// Trigger a cache flush on a config key and return empty response if successful.
///
/// If [cacheKeyParam] is not passed, throws [BadRequestException].
/// If the cache does not have the given key, throws [NotFoundException].
@immutable
class FlushCache extends ApiRequestHandler<Body> {
  const FlushCache(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @required this.cache,
  }) : super(config: config, authenticationProvider: authenticationProvider);

  final CacheService cache;

  /// Name of the query parameter passed to the endpoint.
  ///
  /// The value is expected to be an existing value from [CocoonConfig].
  static const String cacheKeyParam = 'key';

  @override
  Future<Body> get() async {
    checkRequiredQueryParameters(<String>[cacheKeyParam]);
    final String cacheKey = request.uri.queryParameters[cacheKeyParam];

    // To validate cache flushes, validate that the key exists.
    await cache.getOrCreate(
      Config.configCacheName,
      cacheKey,
      createFn: () => throw NotFoundException('Failed to find cache key: $cacheKey'),
    );

    await cache.purge(Config.configCacheName, cacheKey);

    return Body.empty;
  }
}
