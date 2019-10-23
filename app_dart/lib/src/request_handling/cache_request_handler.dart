// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:neat_cache/neat_cache.dart';

import 'package:cocoon_service/cocoon_service.dart';

import 'body.dart';

/// A class based on [RequestHandler] for serving cached responses.
@immutable
class CachedRequestHandler extends RequestHandler<Body> {
  /// Creates a new [CachedRequestHandler].
  const CachedRequestHandler(this.responseKey, this.fallbackHandler,
      {@required Config config, @required this.cache})
      : super(config: config);

  /// The key in the subcache for responses that stores this cached response.
  final String responseKey;

  /// [RequestHandler] that updates the cache.
  final RequestHandler<Body> fallbackHandler;

  final Cache<List<int>> cache;

  /// Services a cached request.
  @override
  Future<Body> get() async {
    final Cache<String> statusCache =
        cache.withPrefix(await config.redisResponseSubcache).withCodec(utf8);

    final String cachedResponse = await statusCache[responseKey].get();

    if (cachedResponse != null) {
      final Map<String, dynamic> jsonResponse = jsonDecode(cachedResponse);
      return Body.forJson(jsonResponse);
    } else {
      return fallbackHandler.get();
    }
  }
}
