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
class CachedRequestHandler<T extends Body> extends RequestHandler<T> {
  /// Creates a new [CachedRequestHandler].
  const CachedRequestHandler(
      {@required this.fallbackDelegate,
      @required Config config,
      @required this.cache})
      : super(config: config);

  /// [RequestHandler] that queries Datastore for the response.
  final RequestHandler<T> fallbackDelegate;

  final Cache<List<int>> cache;

  /// Services a cached request.
  @override
  Future<T> get() async {
    final Cache<String> responseCache =
        cache.withPrefix(await config.redisResponseSubcache).withCodec(utf8);

    final String cachedResponse = await responseCache[request.uri.path].get();

    if (cachedResponse != null) {
      final Map<String, dynamic> jsonResponse = jsonDecode(cachedResponse);
      return Body.forJson(jsonResponse);
    } else {
      return fallbackDelegate.get();
    }
  }
}
