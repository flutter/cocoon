// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:neat_cache/neat_cache.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/request_handler.dart';
import 'body.dart';

/// A [RequestHandler] for serving cached responses.
/// 
/// High trafficked endpoints that have responses that do not change
/// based on request are good for caching. Additionally, saves
/// reading from Datastore which is expensive both timewise and monetarily.
/// 
/// Implementing requires a writer that will keep [responseKey] in the cache updated.
/// This should be [fallbackDelegate], but does not need to be.
@immutable
class CachedRequestHandler extends RequestHandler<Body> {
  /// Creates a new [CachedRequestHandler].
  const CachedRequestHandler(this.responseKey, this.fallbackDelegate,
      {@required Config config, @required this.cache})
      : super(config: config);

  /// The key in the subcache for responses that stores this response.
  final String responseKey;

  /// [RequestHandler] that queries Datastore for 
  final RequestHandler<Body> fallbackDelegate;

  final Cache<List<int>> cache;

  /// Services a cached request.
  @override
  Future<Body> get() async {
    final Cache<String> responseCache =
        cache.withPrefix(await config.redisResponseSubcache).withCodec(utf8);

    final String cachedResponse = await responseCache[responseKey].get();

    if (cachedResponse != null) {
      final Map<String, dynamic> jsonResponse = jsonDecode(cachedResponse);
      return Body.forJson(jsonResponse);
    } else {
      return fallbackDelegate.get();
    }
  }
}
