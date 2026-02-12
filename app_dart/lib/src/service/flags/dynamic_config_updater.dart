// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show Random;
import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

import '../../../cocoon_service.dart';
import '../../foundation/providers.dart' show Providers;
import '../../foundation/typedefs.dart' show HttpClientProvider;

/// Responsibly polls for configuration changes to our service config.
///
/// This works by fetching the latest checked in "config.yaml".
interface class DynamicConfigUpdater {
  DynamicConfigUpdater({
    Duration delay = const Duration(minutes: 1),
    @visibleForTesting Random? random,
    @visibleForTesting
    HttpClientProvider httpClientProvider = Providers.freshHttpClient,
    @visibleForTesting
    RetryOptions retryOptions = const RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 3),
    ),
  }) : _delay = delay,
       _random = random ?? Random(),
       _httpClientProvider = httpClientProvider,
       _retryOptions = retryOptions;

  final Duration _delay;
  final Random _random;
  final HttpClientProvider _httpClientProvider;
  final RetryOptions _retryOptions;

  /// Fetches and parses the `config.yaml` from HEAD `flutter/cocoon/app_dart/`.
  Future<DynamicConfig> fetchDynamicConfig() async {
    final file = await githubFileContent(
      Config.cocoonSlug,
      'app_dart/config.yaml',
      ref: 'main',
      httpClientProvider: _httpClientProvider,
      retryOptions: _retryOptions,
    );
    final configYaml = loadYaml(file) as YamlMap;
    return DynamicConfig.fromYaml(configYaml);
  }

  _UpdaterStatus _status = _UpdaterStatus.stopped;

  void stopUpdateLoop() {
    if (_status != _UpdaterStatus.running) return;
    log.info('ConfigUpdater: Stopping config update loop...');
    _status = _UpdaterStatus.stopping;
  }

  void startUpdateLoop(DynamicallyUpdatedConfig config) async {
    if (_status != _UpdaterStatus.stopped) return;
    _status = _UpdaterStatus.running;

    log.info('ConfigUpdater: Starting config update loop...');

    // What we've decided:
    //   1. Each instance will **start** with a valid DynamicConfig
    //   2. Each instance will update their own config on an interval that can
    //      drift by as much as a minute.
    //   3. If a fetch fails, we'll log an error, but keep using the last config
    while (true) {
      await Future<void>.delayed(
        _delay + Duration(milliseconds: _random.nextInt(1000)),
      );
      if (_status != _UpdaterStatus.running) {
        log.info('ConfigUpdater: Stopped config update loop');
        _status = _UpdaterStatus.stopped;
        return;
      }
      try {
        final dynamicConfig = await fetchDynamicConfig();
        final diffs = _diffConfigChanges(
          config._dynamicConfig.toJson(),
          dynamicConfig.toJson(),
        );
        if (diffs.isNotEmpty) {
          log.info('ConfigUpdater: ${diffs.join(',')}');
          config._dynamicConfig = dynamicConfig;
        }
      } catch (e, s) {
        log.error('ConfigUpdater: Unable to fetch DynamicConfig!', e, s);
      }
    }
  }

  /// Produce a simple diff of the changing flags.
  List<String> _diffConfigChanges(
    Map<String, Object?> oldFlags,
    Map<String, Object?> newFlags, {
    List<String>? diffs,
    String chain = 'flags',
  }) {
    diffs ??= <String>[];

    for (final MapEntry(:key, :value) in oldFlags.entries) {
      if (value is Map) {
        _diffConfigChanges(
          value as Map<String, Object?>,
          newFlags[key] as Map<String, Object?>,
          diffs: diffs,
          chain: '$chain.$key',
        );
        continue;
      }
      if (value != newFlags[key]) {
        diffs.add('$chain.$key $value -> ${newFlags[key]}');
      }
    }
    return diffs;
  }
}

/// A base type for a class where [flags] is updated at runtime.
abstract class DynamicallyUpdatedConfig {
  DynamicallyUpdatedConfig({
    required DynamicConfig initialConfig, //
  }) : _dynamicConfig = initialConfig;

  /// Access dynamically configured flags.
  DynamicConfig get flags => _dynamicConfig;
  DynamicConfig _dynamicConfig;
}

enum _UpdaterStatus { stopped, running, stopping }
