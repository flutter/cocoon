// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/request_handler.dart';
import '../service/cache_service.dart';
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

  final CacheService cache;

  /// The time to live for the response stored in the cache.
  final Duration ttl;

  @visibleForTesting
  static const String responseSubcacheName = 'response';

  /// Services a cached request.
  @override
  Future<T> get() async {
    final String responseKey = '${request.uri.path}:${request.uri.query}';
    final Uint8List cachedResponse = await cache.getOrCreate(
        responseSubcacheName, responseKey,
        createFn: () => getBodyBytesFromDelegate(delegate), ttl: ttl);

    return Body.forStream(Stream<Uint8List>.value(cachedResponse));
  }

  /// Get a Uint8List that contains the bytes of the response from [delegate]
  /// so it can be stored in [cache].
  Future<Uint8List> getBodyBytesFromDelegate(RequestHandler<T> delegate) async {
    final Body body = await delegate.get();
    
    // Body only offers getting a Stream<Uint8List> since it just sends
    // the data out usually to a client. In this case, we want to store
    // the bytes in the cache which requires several conversions to get a
    // Uint8List that contains the bytes of the response.
    final List<int> rawBytes =
        await body.serialize().expand<int>((Uint8List chunk) => chunk).toList();
    return Uint8List.fromList(rawBytes);
  }
}
