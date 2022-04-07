// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/secrets.dart';
import 'package:github/github.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import 'config_test_data.dart';

/// Number of entries allowed in [Cache].
const int kCacheSize = 1024;

void main() {
  group('Config', () {
    late CacheProvider cacheProvider;
    late Config config;
    late MockClient mockClient;
    final SecretManager secretManager = LocalSecretManager();
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    const int kCacheSize = 1024;

    setUp(() {
      cacheProvider = Cache.inMemoryCacheProvider(kCacheSize);
      mockClient = MockClient((_) async => http.Response(installations, HttpStatus.ok));
      config = Config(
        cacheProvider: cacheProvider,
        httpProvider: () => mockClient,
        secretManager: secretManager,
      );
    });

    test('verify github App InstallationId ', () async {
      final Uri githubInstallationUri = Uri.https('api.github.com', 'app/installations');
      final http.Response response = await mockClient.get(githubInstallationUri);
      final list = json.decode(response.body).map((data) => (data) as Map<String, dynamic>).toList();
      expect(list[0]['id'].toString(), '24369313');
      expect(list[1]['id'].toString(), '23587612');
    });

    test('generateGithubToken pulls from cache', () async {
      const String configValue = 'githubToken';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);
      Cache cache = Cache(cacheProvider).withPrefix('config');
      await cache['githubToken'].set(
        cachedValue,
        const Duration(minutes: 1),
      );

      final String githubToken = await config.generateGithubToken(slug);
      expect(githubToken, 'githubToken');
    });
  });
}
