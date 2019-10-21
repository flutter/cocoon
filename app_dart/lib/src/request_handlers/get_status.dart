// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:pedantic/pedantic.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

@immutable
class GetStatus extends RequestHandler<Body> {
  const GetStatus(Config config, this.fallbackHandler) : super(config: config);

  final RequestHandler<Body> fallbackHandler;

  @override
  Future<Body> get() async {
   final CacheProvider<List<int>> cacheProvider =
        Cache.redisCacheProvider(await config.redisUrl);
    final Cache<List<int>> cache = Cache<List<int>>(cacheProvider);

    final Cache<String> statusCache = cache.withPrefix('responses').withCodec(utf8);

    final String response = await statusCache['get-status'].get();
    if (response == null) {
      return fallbackHandler.get();
    }

    // Since this is just a read operation, waiting is an extra precaution
    // that does not need to be taken.
    unawaited(cacheProvider.close());

    return Body.forJson(jsonDecode(response));
  }
}