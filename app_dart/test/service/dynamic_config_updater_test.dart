// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show Random;

import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart' show log;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/dynamic_config_updater.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart' show MockClient;
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';

void main() {
  useTestLoggerPerTest();

  late DynamicConfigUpdater updater;
  late MockClient mockHttp;
  String? mockHttpFile;
  late _FakeRandom random;
  late FakeConfig config;
  var mockHttpCalled = 0;

  setUp(() {
    mockHttpCalled = 0;
    mockHttpFile = goodConfigYaml;
    random = _FakeRandom();
    mockHttp = MockClient((req) async {
      mockHttpCalled++;
      if (mockHttpFile != null) {
        return Response(mockHttpFile!, 200);
      }
      return Response('Not found', 404);
    });
    config = FakeConfig();
    updater = DynamicConfigUpdater(
      random: random,
      httpClient: mockHttp,
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
            message: equals('Starting config update loop...'),
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
            message: equals('Stopping config update loop...'),
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
            message: equals('Stopped config update loop'),
            severity: atMostInfo,
          ),
        ),
      ),
    );
  });

  test('handles format errors', () async {
    mockHttpFile = 'BLAH BLAH BLAH';
    updater.startUpdateLoop(config);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    updater.stopUpdateLoop();
    expect(mockHttpCalled, greaterThan(1));
  });

  test('handles fetch errors', () async {
    mockHttpFile = null;
    updater.startUpdateLoop(config);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    updater.stopUpdateLoop();
    expect(mockHttpCalled, greaterThan(1));
  });

  test('works...', () async {
    updater.startUpdateLoop(config);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    updater.stopUpdateLoop();
    expect(config.dynamicConfigs, isNotEmpty);
    expect(config.dynamicConfig.backfillerCommitLimit, 100);
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
