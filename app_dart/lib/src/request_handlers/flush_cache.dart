// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/cache_service.dart';
import '../service/config.dart';

/// Trigger a cache flush on a config key and return empty response if successful.
///
/// If [cacheKeyParam] is not passed, throws [BadRequestException].
///
/// If the cache does not have the given key, throws [NotFoundException].
final class FlushCache extends ApiRequestHandler {
  const FlushCache({
    required super.config,
    required super.authenticationProvider,
    required CacheService cache,
  }) : _cache = cache;

  final CacheService _cache;

  /// Name of the query parameter passed to the endpoint.
  ///
  /// The value is expected to be an existing value from [CocoonConfig].
  @visibleForTesting
  static const String cacheKeyParam = 'key';

  @override
  Future<Response> get(Request request) async {
    checkRequiredQueryParameters(request, <String>[cacheKeyParam]);
    final cacheKey = request.uri.queryParameters[cacheKeyParam]!;

    // To validate cache flushes, validate that the key exists.
    await _cache.getOrCreate(
      Config.configCacheName,
      cacheKey,
      createFn:
          () => throw NotFoundException('Failed to find cache key: $cacheKey'),
    );

    await _cache.purge(Config.configCacheName, cacheKey);

    return Response.emptyOk;
  }
}
