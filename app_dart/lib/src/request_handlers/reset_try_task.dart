// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

@immutable
class ResetTryTask extends ApiRequestHandler<Body> {
  const ResetTryTask(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.luciBuildService,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  final LuciBuildService luciBuildService;

  @override
  Future<Body> get() async {
    final String owner = request.uri.queryParameters['owner'] ?? 'flutter';
    final String repo = request.uri.queryParameters['repo'] ?? '';
    final String pr = request.uri.queryParameters['pr'] ?? '';
    final String commitSha = request.uri.queryParameters['commitSha'] ?? '';
    if (<String>[repo, pr, commitSha]
        .any((String element) => element.isEmpty)) {
      throw const BadRequestException('Any of repo, pr or commitSha is empty');
    }
    final RepositorySlug slug = RepositorySlug(owner, repo);
    await luciBuildService.scheduleBuilds(
        prNumber: int.parse(pr), commitSha: commitSha, slug: slug);
    return Body.empty;
  }
}
