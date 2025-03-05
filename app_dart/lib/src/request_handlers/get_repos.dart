// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/config.dart';

/// Returns [Config.supportedRepos] as a list of repo names.
@immutable
class GetRepos extends RequestHandler<Body> {
  const GetRepos({required super.config});

  @override
  Future<Body> get() async {
    final repos =
        config.supportedRepos.map((RepositorySlug slug) => slug.name).toList();
    return Body.forJson(repos);
  }
}
