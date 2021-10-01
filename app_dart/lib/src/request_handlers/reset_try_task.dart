// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:github/github.dart';
import 'package:googleapis/cloudtasks/v2.dart' as v2;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/logging.dart';

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
    // move to cloud tasks
    final Client client = authenticationProvider.httpClientProvider();
    final v2.CloudTasksApi api = v2.CloudTasksApi(client);
    const String queueName = 'projects/flutter-dashboard/locations/us-central1/queues/memorystore-writes';
    final v2.ProjectsLocationsQueuesTasksResource tasksResource = api.projects.locations.queues.tasks;
    final AccessTokenService? accessTokenService = AccessTokenService.defaultProvider(config);
    final AccessToken? token = await accessTokenService?.createAccessToken();
    log.info('zzz ${token?.type} ${token?.data}');
    final Map<String, dynamic> task = <String, dynamic>{
      'task': <String, dynamic>{
        'app_engine_http_request': <String, dynamic>{
          'http_method': 'GET',
          'relative_uri': '/readiness_check',
          'headers': <String, dynamic>{HttpHeaders.authorizationHeader: '${token?.type} ${token?.data}'}
        }
      }
    };
    final v2.CreateTaskRequest request = v2.CreateTaskRequest.fromJson(task);

    log.info('Request $request');

    await tasksResource.create(request, queueName);
    //////////////////////

    /*final String owner = request!.uri.queryParameters['owner'] ?? 'flutter';
    final String repo = request!.uri.queryParameters['repo'] ?? '';
    final String pr = request!.uri.queryParameters['pr'] ?? '';
    final String commitSha = request!.uri.queryParameters['commitSha'] ?? '';

    final int? prNumber = int.tryParse(pr);
    if (prNumber == null) {
      throw const BadRequestException('pr must be a number');
    }
    final RepositorySlug slug = RepositorySlug(owner, repo);
    final GitHub github = await config.createGitHubClient(slug);
    final PullRequest pullRequest = await github.pullRequests.get(slug, prNumber);
    await scheduler.triggerPresubmitTargets(
        branch: pullRequest.base!.ref!, prNumber: prNumber, commitSha: commitSha, slug: slug);*/
    return Body.empty;
  }
}
