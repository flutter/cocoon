// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

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
    required RequestHandler<T> delegate,
    required super.config,
    required CacheService cache,
    Duration ttl = const Duration(minutes: 1),
  }) : _ttl = ttl,
       _cache = cache,
       _delegate = delegate;

  final RequestHandler<T> _delegate;
  final CacheService _cache;
  final Duration _ttl;

  @visibleForTesting
  static const String responseSubcacheName = 'response';

  @visibleForTesting
  static const String flushCacheQueryParam = 'flushCache';

  /// Services a cached request.
  ///
  /// Given the query param [flushCacheQueryParam]=true, it will purge the
  /// response from the cache before getting it to set the cached response
  /// to the latest information.
  @override
  Future<T> get() async {
    final responseKey = '${request!.uri.path}:${request!.uri.query}';

    if (request!.uri.queryParameters[flushCacheQueryParam] == 'true') {
      await _cache.purge(responseSubcacheName, responseKey);
    }

    final cachedBytes = await _cache.getOrCreateWithLocking(
      responseSubcacheName,
      responseKey,
      createFn: () async {
        // TODO(matanlurey): Evaluate if 5XX errors should not be cached.
        final response = await _createCachedResponse(_delegate);
        return response.toBytes();
      },
      ttl: _ttl,
    );

    final cachedResponse = _CachedHttpResponse.fromBytes(
      cachedBytes!,
      debugName: responseKey,
    );

    response!
      ..statusCode = cachedResponse.statusCode
      ..reasonPhrase = cachedResponse.reason;

    return Body.forStream(Stream<Uint8List?>.value(cachedResponse.body)) as T;
  }

  /// Invokes [delegate.get], and returns the result as a [_CachedHttpResponse].
  Future<_CachedHttpResponse> _createCachedResponse(
    RequestHandler<T> delegate,
  ) async {
    final body = await delegate.get();
    final response = this.response!;
    final builder = BytesBuilder();
    await body.serialize().forEach((d) {
      if (d != null) builder.add(d);
    });
    return _CachedHttpResponse._(
      response.statusCode,
      response.reasonPhrase,
      builder.toBytes(),
    );
  }
}

@immutable
final class _CachedHttpResponse {
  static const _magic4Bytes = 0xFA_CE_FE_ED;
  static final _magic4Uint8List =
      Uint8List(4)
        ..[0] = 0xFA
        ..[1] = 0xCE
        ..[2] = 0xFE
        ..[3] = 0xED;

  factory _CachedHttpResponse.fromBytes(
    Uint8List bytes, {
    required String debugName,
  }) {
    if (bytes.length < _magic4Uint8List.length ||
        bytes.buffer.asByteData().getUint32(0, Endian.big) != _magic4Bytes) {
      log.warn(
        '[CachedHttpResponse] Legacy cache for $debugName, falling back to '
        'status=200 reason=""',
      );
      return _CachedHttpResponse._(200, '', bytes.buffer.asUint8List());
    }

    // The default implementation of .decodeMessage rejects trailing padding
    // bytes, which are returned by the Redis cache implementation. If we ever
    // fix the Redis implementation, we can change what happens here.
    final buffer = utf8.decode(
      Uint8List.sublistView(bytes, _magic4Uint8List.length),
    );
    final decoded = json.decode(buffer) as Map<String, Object?>;
    return _CachedHttpResponse._(
      decoded['statusCode'] as int,
      decoded['reason'] as String,
      base64.decode(decoded['body'] as String),
    );
  }

  _CachedHttpResponse._(this.statusCode, this.reason, this.body);

  final int statusCode;
  final String reason;
  final Uint8List body;

  /// Returns a binary encoding of the HTTP response.
  Uint8List toBytes() {
    final encoded = utf8.encode(
      json.encode({
        'statusCode': statusCode,
        'reason': reason,
        'body': base64.encode(body),
      }),
    );

    final output = BytesBuilder(copy: true);
    output.add(_magic4Uint8List);
    output.add(encoded.buffer.asUint8List());
    return output.takeBytes();
  }
}
