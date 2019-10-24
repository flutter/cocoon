// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';

import '../datastore/cocoon_config.dart';

@immutable
class CacheService {
  const CacheService(this.config);

  final Config config;

  Future<Cache<Uint8List>> redisCache() async {
    final CacheProvider<List<int>> provider =
        Cache.redisCacheProvider(await config.redisUrl);
    return Cache<List<int>>(provider).withCodec<Uint8List>(const _CacheCodec());
  }

  Future<Cache<Uint8List>> inMemoryCache(int size) async {
    final CacheProvider<List<int>> provider = Cache.inMemoryCacheProvider(size);
    return Cache<List<int>>(provider).withCodec<Uint8List>(const _CacheCodec());
  }
}

class _CacheCodec extends Codec<Uint8List, List<int>> {
  const _CacheCodec();

  @override
  Converter<Uint8List, List<int>> get encoder => const _ListIntConverter();

  @override
  Converter<List<int>, Uint8List> get decoder => const _Uint8ListConverter();
}

class _ListIntConverter extends Converter<Uint8List, List<int>> {
  const _ListIntConverter();

  @override
  List<int> convert(Uint8List input) => input;
}

class _Uint8ListConverter extends Converter<List<int>, Uint8List> {
  const _Uint8ListConverter();

  @override
  Uint8List convert(List<int> input) => Uint8List.fromList(input);
}
