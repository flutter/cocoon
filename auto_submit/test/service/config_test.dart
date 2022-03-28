// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/secrets.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

/// Number of entries allowed in [Cache].
const int kCacheSize = 1024;
void main() {
  group('Config', () {
    late CacheProvider cacheProvider;
    late Config config;
    const int kCacheSize = 1024;

    setUp(() {
      cacheProvider = Cache.inMemoryCacheProvider(kCacheSize);
      config = Config(
        cacheProvider: cacheProvider,
        secretManager: CloudSecretManager(),
      );
    });

    test('githubAppInstallationId ', () async {
      await withAppEngineServices(() async {
        useLoggingPackageAdaptor();
        final String installationId = await config.getInstallationId();
        expect(installationId, '24369313');
      });
    });

    test('generateGithubToken pulls from cache', () async {
      const String configValue = 'githubToken';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);
      Cache cache = Cache(cacheProvider).withPrefix('config');
      await cache['githubToken'].set(
        cachedValue,
        const Duration(minutes: 1),
      );

      final String githubToken = await config.generateGithubToken();
      expect(githubToken, 'githubToken');
    });
  });
}
