// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_server/logging.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

import '../foundation/utils.dart';
import 'config.dart';

class DynamicConfigUpdater {
  DynamicConfigUpdater({
    this.delay = const Duration(minutes: 1),
    @visibleForTesting Random? random,
    @visibleForTesting Client? httpClient,
    @visibleForTesting
    RetryOptions retryOptions = const RetryOptions(
      maxAttempts: 3,
      delayFactor: Duration(seconds: 3),
    ),
  }) : _random = random ?? Random(),
       _httpClient = httpClient ?? Client(),
       _retryOptions = retryOptions;

  final Duration delay;
  final Random _random;
  final Client _httpClient;
  final RetryOptions _retryOptions;

  /// Fetches and parses the `config.yaml` from HEAD `flutter/cocoon/app_dart/`.
  Future<DynamicConfig> fetchDynamicConfig() async {
    final file = await githubFileContent(
      Config.cocoonSlug,
      'app_dart/config.yaml',
      httpClientProvider: () => _httpClient,
      retryOptions: _retryOptions,
    );
    final configYaml = loadYaml(file) as YamlMap;
    return DynamicConfig.fromJson(configYaml.cast<String, dynamic>());
  }

  UpdaterStatus _status = UpdaterStatus.stopped;

  void stopUpdateLoop() {
    if (_status != UpdaterStatus.running) return;
    log.info('Stopping config update loop...');
    _status = UpdaterStatus.stopping;
  }

  void startUpdateLoop(Config config) async {
    if (_status != UpdaterStatus.stopped) return;
    _status = UpdaterStatus.running;

    log.info('Starting config update loop...');

    // What we've decided:
    //   1. Each instance will **start** with a valid DynamicConfig
    //   2. Each instance will update their own config on an interval that can
    //      drift by as much as a minute.
    //   3. If a fetch fails, we'll log an error, but keep using the last config
    while (true) {
      await Future<void>.delayed(
        delay + Duration(milliseconds: _random.nextInt(1000)),
      );
      if (_status != UpdaterStatus.running) {
        log.info('Stopped config update loop');
        _status = UpdaterStatus.stopped;
        return;
      }
      try {
        final dynamicConfig = await fetchDynamicConfig();
        config.dynamicConfig = dynamicConfig;
      } catch (e, s) {
        log.error('Unable to fetch DynamicConfig!', e, s);
      }
    }
  }
}

enum UpdaterStatus { stopped, running, stopping }
