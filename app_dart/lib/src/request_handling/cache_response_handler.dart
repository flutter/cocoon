// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:meta/meta.dart';

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
    final HttpResponse response = request.response;

    if (file.existsSync()) {
      // return cached response
    } else {
      return fallbackHandler.get();
    }
  }
}
