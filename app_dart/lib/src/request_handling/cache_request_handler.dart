// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

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
    final Cache<List<int>> responseCache =
        cache.withPrefix(await config.redisResponseSubcache);

    final List<int> cachedResponse =
        await responseCache[request.uri.path].get();

    if (cachedResponse != null) {
      final Stream<Uint8List> response =
          Stream<Uint8List>.fromIterable(cachedResponse.cast<Uint8List>());
      return Body.forStream(response);
    } else {
      final Body body = await fallbackDelegate.get();
      await updateCache(responseCache, body);

      return body;
    }
  }

  /// Update cache with the latest response.
  ///
  /// This response will be served for the next minute of requests.
  Future<void> updateCache(Cache<List<int>> responseCache, Body body) async {
    final List<int> serializedBody =
        await body.serialize().cast<int>().toList();

    await responseCache[request.uri.path]
        .set(serializedBody, const Duration(minutes: 1));
  }
}
