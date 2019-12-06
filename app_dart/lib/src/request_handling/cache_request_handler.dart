// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:pedantic/pedantic.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/request_handler.dart';
import 'body.dart';

/// A [RequestHandler] for serving cached responses.
///
/// High traffic endpoints that have responses that do not change
/// based on request are good for caching. Additionally, saves
/// reading from Datastore which is expensive both timewise and monetarily.
@immutable
class CacheRequestHandler<T extends Body> extends RequestHandler<T> {
  /// Creates a new [CacheRequestHandler].
  const CacheRequestHandler({
    @required this.delegate,
    @required Config config,
    @required this.cache,
    this.ttl = const Duration(minutes: 1),
  }) : super(config: config);

  /// [RequestHandler] to fallback on for cache misses.
  final RequestHandler<T> delegate;

  final Cache<Uint8List> cache;

  /// The time to live for the response stored in the cache.
  final Duration ttl;

  /// Services a cached request.
  @override
  Future<T> get() async {
    final Cache<Uint8List> responseCache =
        cache.withPrefix(await config.redisResponseSubcache);

    final String responseKey = '${request.uri.path}:${request.uri.query}';
    final Uint8List cachedResponse = await responseCache[responseKey].get();

    if (cachedResponse != null) {
      return Body.forStream(Stream<Uint8List>.value(cachedResponse));
    } else {
      final Body body = await delegate.get();
      final List<int> rawBytes = await body
          .serialize()
          .expand<int>((Uint8List chunk) => chunk)
          .toList();
      final Uint8List bytes = Uint8List.fromList(rawBytes);
      await responseCache[responseKey].set(bytes, ttl);

      return body;
    }
  }
}
