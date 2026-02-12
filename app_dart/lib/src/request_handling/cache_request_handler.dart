// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_common/core_extensions.dart';
import 'package:meta/meta.dart';

import '../request_handling/request_handler.dart';
import '../service/cache_service.dart';
import 'http_utils.dart';
import 'response.dart';

/// A [RequestHandler] for serving cached responses.
///
/// High traffic endpoints that have responses that do not change
/// based on request are good for caching. Additionally, saves
/// reading from Firestore which is expensive both timewise and monetarily.
final class CacheRequestHandler extends RequestHandler {
  /// Creates a new [CacheRequestHandler].
  const CacheRequestHandler({
    required RequestHandler delegate,
    required super.config,
    required CacheService cache,
    Duration ttl = const Duration(minutes: 1),
  }) : _ttl = ttl,
       _cache = cache,
       _delegate = delegate;

  final RequestHandler _delegate;
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
  Future<Response> get(Request request) async {
    final responseKey = '${request.uri.path}:${request.uri.query}';

    if (request.uri.queryParameters[flushCacheQueryParam] == 'true') {
      await _cache.purge(responseSubcacheName, responseKey);
    }

    final cachedBytes = await _cache.getOrCreateWithLocking(
      responseSubcacheName,
      responseKey,
      createFn: () async {
        // This also caches 5XX errors, which, while unexpected, makes sense in
        // the context of our server, where we have public APIs that can make
        // expensive operations. If one was to fail, we'd prefer not making that
        // expensive operation over and over in a short time window.
        final response = await _createCachedResponse(request, _delegate);
        return response.toBytes();
      },
      ttl: _ttl,
    );

    final cachedResponse = _CachedHttpResponse.fromBytes(
      cachedBytes!,
      debugName: responseKey,
    );

    return Response.stream(
      Stream.value(cachedResponse.body),
      statusCode: cachedResponse.statusCode,
      contentType: cachedResponse.contentType,
    );
  }

  /// Invokes [delegate.get], and returns the result as a [_CachedHttpResponse].
  Future<_CachedHttpResponse> _createCachedResponse(
    Request request,
    RequestHandler delegate,
  ) async {
    final response = await delegate.get(request);
    return _CachedHttpResponse._(
      response.statusCode,
      await response.body.collectBytes(),
      response.contentType,
    );
  }
}

@immutable
final class _CachedHttpResponse {
  static const _magic4Bytes = 0xFA_CE_FE_ED;
  static final _magic4Uint8List = Uint8List(4)
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
      throw StateError(
        'Unexpected cached HTTP response: "${base64.encode(bytes)}"',
      );
    }

    // The default implementation of .decodeMessage rejects trailing padding
    // bytes, which are returned by the Redis cache implementation. If we ever
    // fix the Redis implementation, we can change what happens here.
    final buffer = utf8.decode(
      Uint8List.sublistView(bytes, _magic4Uint8List.length),
    );
    final decoded = json.decode(buffer) as Map<String, Object?>;
    final contentType = decoded['contentType'] as String?;
    return _CachedHttpResponse._(
      decoded['statusCode'] as int,
      base64.decode(decoded['body'] as String),
      contentType != null ? MediaType.parse(contentType) : null,
    );
  }

  _CachedHttpResponse._(this.statusCode, this.body, this.contentType);

  final int statusCode;
  final Uint8List body;
  final MediaType? contentType;

  /// Returns a binary encoding of the HTTP response.
  Uint8List toBytes() {
    final encoded = utf8.encode(
      json.encode({
        'statusCode': statusCode,
        'body': base64.encode(body),
        if (contentType case final contentType?) 'contentType': '$contentType',
      }),
    );

    final output = BytesBuilder(copy: true);
    output.add(_magic4Uint8List);
    output.add(encoded.buffer.asUint8List());
    return output.takeBytes();
  }
}
