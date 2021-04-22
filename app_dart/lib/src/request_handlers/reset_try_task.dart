// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/scheduler.dart';

/// Runs all the applicable tasks for a given PR and commit hash. This will be
/// used to unblock rollers when creating a new commit is not possible.
@immutable
class ResetTryTask extends ApiRequestHandler<Body> {
  const ResetTryTask(
    Config config,
    AuthenticationProvider authenticationProvider,
    this.scheduler,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  final Scheduler scheduler;

  @override
  Future<Body> get() async {
    final String owner = request.uri.queryParameters['owner'] ?? 'flutter';
    final String repo = request.uri.queryParameters['repo'] ?? '';
    final String pr = request.uri.queryParameters['pr'] ?? '';
    final String commitSha = request.uri.queryParameters['commitSha'] ?? '';

    // Set logger for service classes.
    scheduler.setLogger(log);

    final int prNumber = int.tryParse(pr);
    final RepositorySlug slug = RepositorySlug(owner, repo);
    await scheduler.triggerPresubmitTargets(prNumber: prNumber, commitSha: commitSha, slug: slug);
    return Body.empty;
  }
}
