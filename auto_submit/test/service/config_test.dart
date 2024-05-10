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
    final LocalSecretManager secretManager = LocalSecretManager();
    final RepositorySlug flutterSlug = RepositorySlug('flutter', 'flutter');
    final RepositorySlug testSlug = RepositorySlug('test', 'test');
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

    test('verify throws if installations response is unexpected', () async {
      cacheProvider = Cache.inMemoryCacheProvider(kCacheSize);
      mockClient = MockClient((_) async => http.Response('[]', HttpStatus.internalServerError));
      secretManager.put(Config.kGithubKey, _fakeKey);
      secretManager.put(Config.kGithubAppId, '1');
      config = Config(
        cacheProvider: cacheProvider,
        httpProvider: () => mockClient,
        secretManager: secretManager,
      );

      expect(
        config.getInstallationId(testSlug),
        throwsA(
          isA<CocoonGitHubRequestException>().having(
            (e) => e.message,
            'message',
            contains('failed to get ID'),
          ),
        ),
      );
    });

    test('verify github App Installation Id ', () async {
      final Uri githubInstallationUri = Uri.https('api.github.com', 'app/installations');
      final http.Response response = await mockClient.get(githubInstallationUri);
      final List<dynamic> list =
          (json.decode(response.body).map((dynamic data) => (data) as Map<String, dynamic>)).toList() as List<dynamic>;
      expect(list[0]['id'].toString(), '24369313');
      expect(list[1]['id'].toString(), '23587612');
    });

    test('generateGithubToken pulls from cache', () async {
      const String configValue = 'githubToken';
      final Uint8List cachedValue = Uint8List.fromList(configValue.codeUnits);
      final Cache cache = Cache<dynamic>(cacheProvider).withPrefix('config');
      await cache['githubToken-${flutterSlug.owner}'].set(
        cachedValue,
        const Duration(minutes: 1),
      );

      final String githubToken = await config.generateGithubToken(flutterSlug);
      expect(githubToken, configValue);
    });

    test('Github clients are created with correct token', () async {
      const String flutterToken = 'flutterToken';
      final Uint8List flutterValue = Uint8List.fromList(flutterToken.codeUnits);
      const String testToken = 'testToken';
      final Uint8List testValue = Uint8List.fromList(testToken.codeUnits);
      final Cache cache = Cache<dynamic>(cacheProvider).withPrefix('config');
      await cache['githubToken-${flutterSlug.owner}'].set(
        flutterValue,
        const Duration(minutes: 1),
      );
      await cache['githubToken-${testSlug.owner}'].set(
        testValue,
        const Duration(minutes: 1),
      );

      final GitHub flutterClient = await config.createGithubClient(flutterSlug);
      final GitHub testClient = await config.createGithubClient(testSlug);
      expect(flutterClient.auth.token!, flutterToken);
      expect(testClient.auth.token!, testToken);
    });
  });
}

// This is a throw-away private key created just for Config tests.
const String _fakeKey = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAtktJeC0vgnAjkV7mvCIXJZTG8IMTj8viMZxFrbDKjbXP5e7Y
03srbSwHdFCBgRDasSqo7LEglmTWFedmv7hskO89y6whfQCRovklwIGY8pJmLT86
/zVtrGv7Y513UR1dKJLf7764/RyaCQyZzgcaStHin4DDslrG+VniW7OVfZNpzu52
hYpJSy/CJ1e/csSL4T5EyYfNf4tAAcrgo2rBrZXFH+i3UL7wQjudv612wqwMMP3h
1YgOo2M2GXEPR0ktWkVhKwi9dkW4ac+d/rev4D11GgTEtHQd2Vcy+vsXMSTloEec
6R10WKG0xD25DjmsvFL8gfwxeNjq/fFBKzcFYwIDAQABAoIBABXKZhvhet5ivT2x
VG+Eu7OYVzeE05/KxV0cyw96JJxP8WwQ4wZUoNpJ+xIiVXiyJRIsgUjZ24VexGCV
6qhcSU4B6ycfillA6ifLFIIwe7HzYhdiiZDcOCH2PnSn7A1cLzicZfxolgBbnOYc
BX6lRrVO5YIfiEUXqNVBs1c23lXGR1BhYxVSiFBtNWyle2wFU/POjShx1V+v8xaS
hcQempU2eZqH/vJfTpyyd2jjGrE4yHwd/ywivtN57xyaJ9VchHRKu+285+K2seKb
43TChTaX0CTTSv2jcv/V7LAaVVGHDiqi7aDlS+FxviKwzBJel/b0dsLvkXWxRw+R
skyBF7ECgYEA8mSI/iOiCLHp+BuLw9bZtO24ue4N6dUHG6hoQntA3z724tnkRcdi
KzhOksmnIoYiQrdYBUlNQkjSBUnOdnoj6SbdGtOTajMacXoG/6DoGDSaSnxUukxS
6Vs4Imtv7xy4nt82nO1GKPoI7SObif1hcVN0GzoXznzP93yYFV9kO1cCgYEAwIcQ
lxOfhdhKoWY4V1Ho4T2NvunjLxpMGz9i3kASZhC8EkcCwuSXXKo1lar6pOATkT1O
9ghHP/YnwIL/D8PrPHZbyNeo50506fUmd8j+6UOOjiHr6bLAhcDzUwbqdvgcjUiU
SrELGLG9+y3nLM45mg9iUgovZw+NZ0nmzVmZytUCgYEAu/jY//SUKJgIMD70YTgR
dqzPj2ib45UvQPSVfdDlWvsSLJP64V4gtBGjZVP6R9yrXv+dw+O3hUrBjBZThS9s
/9cCqlYfQMFGpW+TU9PtiS/p4w+OCTc9KPhzjMWydUTZq2LAkGu09/wGxhfR++3C
DkdAiAjCA4BpKqy1qAVkzlsCgYEAoH94OxmmwMOg44/9o/2qsCrKQb9lHt1DWOus
li6/p8qHno0IJkS+UgerCAwzSsNqTIfZjY01KIMifIA39YKUViEtPu9Z5QoouOkf
mng62WbyLlbk/jt/94D01+BKEcegtb8tsF6LK5jxEbYgo99/cYklo9LN1ZLHhLW8
7K+nX8kCgYEAqQPFTRoQvov2Tl7WBrw9yyDLicpfBJP6gCdC7ct7ghslvo6aIbLN
WdOXeDKJ+NfwqsML4B+fxTn9ItT8tTGZK8NOMNi/anS160uIqqQQVAJsQJCAMs6A
G27hsm/zSHDKon89i7lOTdWdwW3ensD128ILh1vyb37k2TnvgMlIpvM=
-----END RSA PRIVATE KEY-----
''';
