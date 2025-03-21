// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../service/cache_service.dart';
import 'api_request_handler.dart';
import 'body.dart';

/// A class that services an HTTP `GET` request that discards new requests.
///
/// [Scheduling jobs with `cron.yaml`][1] reads:
/// > Only a single instance of a job should run at any time. The Cron service
/// > is designed to provide "at least once" delivery; that is, if a job is
/// > scheduled, App Engine sends the job request at least one time. In some
/// > rare circumstances, it is possible for multiple instances of the same job
/// > to be requested, therefore, your request handler should be idempotent, and
/// > your code should ensure that there are no harmful side-effects if this
/// > occurs.
///
/// [1]: https://cloud.google.com/appengine/docs/flexible/scheduling-jobs-with-cron-yaml
abstract class SingleExecutionRequestHandler extends ApiRequestHandler {
  @visibleForTesting
  static const subCacheName = 'SingleExecutionRequestHandler';

  @visibleForTesting
  static const xAppengineCron = 'X-Appengine-Cron';

  const SingleExecutionRequestHandler({
    required super.config,
    required super.authenticationProvider,
    required CacheService cache,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _cache = cache,
       _now = now;

  final CacheService _cache;
  final DateTime Function() _now;

  /// Whether to disallow access from non-`cron.yaml` jobs.
  ///
  /// See <https://cloud.google.com/appengine/docs/flexible/scheduling-jobs-with-cron-yaml#securing_urls_for_cron>.
  bool get allowOnlyAppEngineCronAccess => true;

  /// The maximum amount of time this task might concievably run.
  ///
  /// After [maxExecutionTime], the "lock" is removed and subsequent requests
  /// still invoke [get], even if (somehow) an existing handler is still
  /// processing a job.
  ///
  /// At most 60 minutes (cron tasks cannot run longer than 60 minutes), but
  /// often shorter, such as the duration set in the root `cron.yaml` file. For
  /// example a task that is executed every 5 minutes might have a max execution
  /// time of 5 minutes.
  @protected
  Duration get maxExecutionTime => const Duration(minutes: 60);

  /// Name of the cache key used for this handler.
  @protected
  String get cacheKey => '$runtimeType';

  @override
  @nonVirtual
  Future<Body> get() async {
    if (allowOnlyAppEngineCronAccess &&
        request!.headers.value(xAppengineCron) != 'true') {
      response!.statusCode = HttpStatus.unauthorized;
      return Body.empty;
    }

    // Lookup if this task is already executing.
    final isExecuting = await _cache.getOrCreateWithLocking(
      subCacheName,
      cacheKey,
      createFn: null,
    );
    if (isExecuting != null) {
      // Skip running this task.
      final started = DateTime.fromMillisecondsSinceEpoch(
        isExecuting.buffer.asUint64List().first,
      );
      log.info(
        'Ignoring request to $runtimeType, already running since ${started.toIso8601String()}.',
      );
      response!.statusCode = HttpStatus.accepted;
    } else {
      // Mark the task as running.
      try {
        final now = Uint64List(1)..[0] = _now().millisecondsSinceEpoch;
        await _cache.setWithLocking(
          subCacheName,
          cacheKey,
          now.buffer.asUint8List(),
          ttl: maxExecutionTime,
        );
        log.debug('Starting $runtimeType');
        await run();
      } finally {
        log.debug('Completed $runtimeType');
        await _cache.purge(subCacheName, cacheKey);
      }
    }
    return Body.empty;
  }

  /// Provide the batch function that executes conditionally.
  Future<void> run();
}
