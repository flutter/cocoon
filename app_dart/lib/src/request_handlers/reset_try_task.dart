// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/cloudtasks/v2.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../service/access_client_provider.dart';

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
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    final Client client = await accessClientProvider.createAccessClient();
    final CloudTasksApi api = CloudTasksApi(client);
    const String queueName = 'projects/flutter-dashboard/locations/us-central1/queues/memorystore-writes';
    final ProjectsLocationsQueuesTasksResource tasksResource = api.projects.locations.queues.tasks;
    final AccessTokenService? accessTokenService = AccessTokenService.defaultProvider(config);
    final AccessToken? token = await accessTokenService?.createAccessToken();
    final Map<String, dynamic> task = <String, dynamic>{
      'task': <String, dynamic>{
        'appEngineHttpRequest': <String, dynamic>{
          'httpMethod': 'POST',
          'relativeUri': '/tasks/reset_try_tasks',
          'body': base64Encode(json.encode(request?.uri.queryParameters).codeUnits),
          'headers': <String, dynamic>{
            'X-Flutter-IdToken': '${token!.data}',
            'Content-Type': 'application/json',
          }
        }
      }
    };
    final CreateTaskRequest taskRequest = CreateTaskRequest.fromJson(task);
    await tasksResource.create(taskRequest, queueName);
    return Body.empty;
  }
}
