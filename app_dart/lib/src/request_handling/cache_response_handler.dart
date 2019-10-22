// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:pedantic/pedantic.dart';

import 'package:cocoon_service/cocoon_service.dart';

import 'body.dart';

/// A class based on [RequestHandler] for serving cached responses from redis.
@immutable
class CacheResponseHandler extends RequestHandler<Body> {
  /// Creates a new [CacheResponseHandler].
  const CacheResponseHandler(this.responseKey, this.fallbackHandler,
      {@required Config config})
      : super(config: config);

  /// The key in the subcache for responses that stores this cached response.
  final String responseKey;

  /// [RequestHandler] that updates the cache.
  final RequestHandler<Body> fallbackHandler;

  /// Services a request that is cached in redis.
  @override
  Future<Body> get() async {
    final CacheProvider<List<int>> cacheProvider =
        Cache.redisCacheProvider(await config.redisUrl);
    final Cache<List<int>> cache = Cache<List<int>>(cacheProvider);

    final Cache<String> statusCache =
        cache.withPrefix(await config.redisResponseSubcache).withCodec(utf8);

    final String response = await statusCache[responseKey].get();

    // Since this is just a read operation, waiting is an extra precaution
    // that does not need to be taken.
    unawaited(cacheProvider.close());

    if (response != null) {
      return Body.forJson(jsonDecode(response));
    } else {
      return fallbackHandler.get();
    }
  }
}
