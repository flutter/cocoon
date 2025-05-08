// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/config.dart';

/// Returns [Config.supportedRepos] as a list of repo names.
final class GetRepos extends RequestHandler {
  const GetRepos({required super.config});

  @override
  Future<Body> get(Request request) async {
    return Body.forJson([
      ...config.supportedRepos.map((RepositorySlug slug) => slug.name),
    ]);
  }
}
