// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show Random;

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart' show log;
import 'package:cocoon_server_test/fake_secret_manager.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config_updater.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  late DynamicConfigUpdater updater;
  late MockClient mockHttp;
  String? mockHttpFile;
  late _FakeRandom random;
  late Config config;
  late List<Uri> requestUris;

  setUp(() {
    requestUris = <Uri>[];
    mockHttpFile = goodConfigYaml;
    random = _FakeRandom();
    mockHttp = MockClient((req) async {
      requestUris.add(req.url);
      if (mockHttpFile != null) {
        return http.Response(mockHttpFile!, 200);
      }
      return http.Response('Not found', 404);
    });
    final cacheService = CacheService(inMemory: true);
    final secrets = FakeSecretManager();
    config = Config(
      cacheService,
      secrets,
      initialConfig: DynamicConfig.fromJson({}),
    );
    updater = DynamicConfigUpdater(
      random: random,
      httpClientProvider: () => mockHttp,
      delay: const Duration(milliseconds: 1),
      retryOptions: const RetryOptions(
        maxAttempts: 1,
        delayFactor: Duration.zero,
        maxDelay: Duration(milliseconds: 1),
        randomizationFactor: 0,
      ),
    );
  });

  tearDown(() async {
    updater.stopUpdateLoop();
    await Future<void>.delayed(const Duration(milliseconds: 5));
  });

  test('can only be started/stopped once', () async {
    updater.startUpdateLoop(config);
    updater.startUpdateLoop(config);
    updater.startUpdateLoop(config);
    updater.stopUpdateLoop();
    updater.stopUpdateLoop();
    updater.stopUpdateLoop();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      log,
      bufferedLoggerOf(
        containsOnce(
          logThat(
            message: equals('ConfigUpdater: Starting config update loop...'),
            severity: atMostInfo,
          ),
        ),
      ),
    );
    expect(
      log,
      bufferedLoggerOf(
        containsOnce(
          logThat(
            message: equals('ConfigUpdater: Stopping config update loop...'),
            severity: atMostInfo,
          ),
        ),
      ),
    );
    expect(
      log,
      bufferedLoggerOf(
        containsOnce(
          logThat(
            message: equals('ConfigUpdater: Stopped config update loop'),
            severity: atMostInfo,
          ),
        ),
      ),
    );
  });

  test('handles format errors', () async {
    mockHttpFile = 'BLAH BLAH BLAH';
    updater.startUpdateLoop(config);

    // Wait for at least 2 requests to verify the loop continues after error
    await pollUntil(
      () => requestUris.length >= 2,
      interval: const Duration(milliseconds: 10),
    );

    updater.stopUpdateLoop();
    expect(requestUris.length, greaterThan(1));
  });

  test('handles fetch errors', () async {
    mockHttpFile = null;
    updater.startUpdateLoop(config);

    // Wait for at least 2 requests to verify the loop continues after error
    await pollUntil(
      () => requestUris.length >= 2,
      interval: const Duration(milliseconds: 10),
    );

    updater.stopUpdateLoop();
    expect(requestUris.length, greaterThan(1));
  });

  test('works...', () async {
    updater.startUpdateLoop(config);

    // Wait for config to be updated (default is 50, goodConfigYaml is 100)
    await pollUntil(
      () => config.flags.backfillerCommitLimit == 100,
      interval: const Duration(milliseconds: 10),
    );

    updater.stopUpdateLoop();
    expect(
      '${requestUris.last}',
      'https://raw.githubusercontent.com/flutter/cocoon/main/app_dart/config.yaml',
    );
    expect(config.flags.backfillerCommitLimit, 100);
  });

  test('handles updating values', () async {
    updater.startUpdateLoop(config);

    // Wait for initial update (100)
    await pollUntil(
      () => config.flags.backfillerCommitLimit == 100,
      interval: const Duration(milliseconds: 10),
    );

    mockHttpFile = updatedConfigYaml;

    // Wait for second update (200)
    await pollUntil(
      () => config.flags.backfillerCommitLimit == 200,
      interval: const Duration(milliseconds: 10),
    );

    updater.stopUpdateLoop();

    expect(config.flags.backfillerCommitLimit, 200);
    expect(
      log,
      bufferedLoggerOf(
        containsOnce(
          logThat(
            message: equals(
              'ConfigUpdater: flags.backfillerCommitLimit 100 -> 200',
            ),
            severity: atMostInfo,
          ),
        ),
      ),
    );
  });
}

final class _FakeRandom extends Fake implements Random {
  int next = 0;
  @override
  int nextInt(_) {
    return next;
  }
}

const goodConfigYaml = '''
# Defines the config options for Flutter CI (Cocoon)
#
# The schema for this file is defined in DynamicConfig of
# app_dart/lib/src/service/config.dart

backfillerCommitLimit: 100
''';

const updatedConfigYaml = '''
# Defines the config options for Flutter CI (Cocoon)
#
# The schema for this file is defined in DynamicConfig of
# app_dart/lib/src/service/config.dart

backfillerCommitLimit: 200
''';
