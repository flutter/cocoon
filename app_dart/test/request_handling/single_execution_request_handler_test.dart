// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/single_execution_request_handler.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  useTestLoggerPerTest();

  late FakeConfig config;
  late FakeAuthenticationProvider authenticationProvider;
  late CacheService cache;
  late ApiRequestHandlerTester tester;

  setUp(() {
    config = FakeConfig();
    authenticationProvider = FakeAuthenticationProvider();
    cache = CacheService(inMemory: true);
    tester = ApiRequestHandlerTester();
  });

  test('refuses a non-cron.yaml scheduled task', () async {
    final handler = _TestHandler(
      () => fail('Should not run'),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: cache,
    );

    await tester.get(handler);

    expect(tester.response.statusCode, HttpStatus.unauthorized);
  });

  test('allows a non-cron.yaml scheduled task', () async {
    final handler = _TestHandler(
      expectAsync0(() async {}),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: cache,
      allowOnlyAppEngineCronAccess: false,
    );

    await tester.get(handler);

    expect(tester.response.statusCode, HttpStatus.ok);
  });

  test('allows a cron.yaml scheduled task (authorized)', () async {
    final handler = _TestHandler(
      expectAsync0(() async {}),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: cache,
      allowOnlyAppEngineCronAccess: true,
    );

    tester.request!.headers.add(
      SingleExecutionRequestHandler.xAppengineCron,
      'true',
    );
    await tester.get(handler);

    expect(tester.response.statusCode, HttpStatus.ok);
  });

  test('blocks re-entry while executing', () async {
    final completer = Completer<void>();
    final handler = _TestHandler(
      expectAsync0(() {
        return completer.future;
      }),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: cache,
      allowOnlyAppEngineCronAccess: false,
    );

    // Make a first request, which will block.
    final blocking = ApiRequestHandlerTester();
    final executing = blocking.get(handler);
    await pumpEventQueue();

    // Make a second request.
    await tester.get(handler);
    expect(tester.response.statusCode, HttpStatus.accepted);

    completer.complete();
    await executing;
  });

  test('allows re-running', () async {
    final handler = _TestHandler(
      expectAsync0(() async {}, count: 2),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: cache,
      allowOnlyAppEngineCronAccess: false,
    );

    // Make a first request, which will succeed.
    await tester.get(handler);
    expect(tester.response.statusCode, HttpStatus.ok);

    // Make a second request, which will succeed.
    await tester.get(handler);
    expect(tester.response.statusCode, HttpStatus.ok);
  });

  test('stores the current DateTime as the cache value', () async {
    final completer = Completer<void>();
    final stickyNow = DateTime.now();
    final handler = _TestHandler(
      expectAsync0(() {
        return completer.future;
      }),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: cache,
      allowOnlyAppEngineCronAccess: false,
      cacheKey: 'test-cache-key',
      now: () => stickyNow,
    );

    final waiting = tester.get(handler);
    await pumpEventQueue();

    final value = await cache.getOrCreate(
      SingleExecutionRequestHandler.subCacheName,
      'test-cache-key',
      createFn: null,
    );
    expect(
      value!.buffer.asUint64List().first,
      stickyNow.millisecondsSinceEpoch,
    );

    completer.complete();
    await expectLater(waiting, completes);

    expect(
      await cache.getOrCreate(
        SingleExecutionRequestHandler.subCacheName,
        'test-cache-key',
        createFn: null,
      ),
      isNull,
    );
  });

  test('stores a TTL', () async {
    final capture = _FakeCapturingCache();
    final handler = _TestHandler(
      expectAsync0(() async {}),
      config: config,
      authenticationProvider: authenticationProvider,
      cache: capture,
      allowOnlyAppEngineCronAccess: false,
      maxExecutionTime: const Duration(seconds: 42),
    );

    await tester.get(handler);
    expect(capture.capturedTtl, const Duration(seconds: 42));
  });
}

final class _FakeCapturingCache extends Fake implements CacheService {
  Duration? capturedTtl;

  @override
  Future<void> purge(String subcacheName, String key) async {}

  @override
  Future<Uint8List?> getOrCreateWithLocking(
    String subcacheName,
    String key, {
    required Future<Uint8List> Function()? createFn,
    Duration ttl = const Duration(minutes: 1),
  }) async {
    return null;
  }

  @override
  Future<Uint8List?> setWithLocking(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    capturedTtl = ttl;
    return null;
  }
}

final class _TestHandler extends SingleExecutionRequestHandler {
  _TestHandler(
    this._run, {
    required super.config,
    required super.authenticationProvider,
    required super.cache,
    super.now,
    bool? allowOnlyAppEngineCronAccess,
    Duration? maxExecutionTime,
    String? cacheKey,
  }) : _cacheKey = cacheKey,
       _allowOnlyAppEngineCronAccess = allowOnlyAppEngineCronAccess,
       _maxExecutionTime = maxExecutionTime;

  @override
  bool get allowOnlyAppEngineCronAccess =>
      _allowOnlyAppEngineCronAccess ?? super.allowOnlyAppEngineCronAccess;
  final bool? _allowOnlyAppEngineCronAccess;

  @override
  Duration get maxExecutionTime => _maxExecutionTime ?? super.maxExecutionTime;
  final Duration? _maxExecutionTime;

  @override
  String get cacheKey => _cacheKey ?? super.cacheKey;
  final String? _cacheKey;

  @override
  Future<void> run() => _run();
  final Future<void> Function() _run;
}
