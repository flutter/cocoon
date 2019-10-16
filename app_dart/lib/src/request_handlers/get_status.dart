// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:neat_cache/neat_cache.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/commit.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';

@immutable
class GetStatus extends RequestHandler<Body> {
  const GetStatus(Config config) : super(config: config);

  @override
  Future<Body> get() async {
    final cacheProvider = Cache.redisCacheProvider('redis://10.0.0.4:6379');
    final cache = Cache(cacheProvider);

    final statusCache = cache.withPrefix('responses').withCodec(utf8);

    final response = await statusCache['get-status'].get();

    await cacheProvider.close();

    return Body.forJson(jsonDecode(response));
  }
}

/// The serialized representation of a [CommitStatus].
// TODO(tvolkert): Directly serialize [CommitStatus] once frontends migrate to new format.
class SerializableCommitStatus {
  const SerializableCommitStatus(this.status);

  final CommitStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Checklist': SerializableCommit(status.commit),
      'Stages': status.stages,
    };
  }
}
