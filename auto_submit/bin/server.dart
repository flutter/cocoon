// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:auto_submit/helpers.dart';
import 'package:auto_submit/requests/cronjob_handler.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:auto_submit/service/config.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:shelf_router/shelf_router.dart';

/// Number of entries allowed in [Cache].
const int kCacheSize = 1024;

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    final cache = Cache.inMemoryCacheProvider(kCacheSize);
    final Config config = Config(
      cacheProvider: cache,
    );

    final Router router = Router()
      ..post(
          '/webhook',
          GithubWebhook(
            config: config,
          ).post)
      ..get('/cronJob', CronjobHandler(config: config).get);
    await serveHandler(router);
  });
}
