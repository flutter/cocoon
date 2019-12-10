// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/log_chunk.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';

@immutable
class AppendLog extends ApiRequestHandler<Body> {
  const AppendLog(
    Config config,
    AuthenticationProvider authenticationProvider,
  ) : super(config: config, authenticationProvider: authenticationProvider);

  static const String ownerKeyParam = 'ownerKey';

  @override
  Future<Body> post() async {
    final String encodedOwnerKey = request.uri.queryParameters[ownerKeyParam];
    if (encodedOwnerKey == null) {
      throw const BadRequestException(
          'Missing required query parameter: $ownerKeyParam');
    }

    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper =
        KeyHelper(applicationContext: clientContext.applicationContext);
    final Key ownerKey = keyHelper.decode(encodedOwnerKey);

    final Task task = await config.db.lookupValue<Model>(ownerKey, orElse: () {
      throw const InternalServerError(
          'Invalid owner key. Owner entity does not exist');
    });

    final LogChunk logChunk = LogChunk(
      ownerKey: ownerKey,
      createTimestamp: DateTime.now().millisecondsSinceEpoch,
      data: requestBody,
    );

    await config.db.withTransaction<void>((Transaction transaction) async {
      transaction.queueMutations(inserts: <LogChunk>[logChunk]);
      await transaction.commit();
    });

    final Client httpClient = await clientViaServiceAccount(
      await config.taskLogServiceAccount,
      const <String>[
        'https://www.googleapis.com/auth/logging.write',
      ],
    );

    final LoggingApi _api = LoggingApi(httpClient);

    final List<String> lines = String.fromCharCodes(requestBody).split('\n');

    final WriteLogEntriesRequest logRequest = WriteLogEntriesRequest()
      ..entries = lines.map((String line) => LogEntry()..textPayload = line).toList()
      ..logName = 'projects/flutter-dashboard/logs/${encodedOwnerKey}_${task.attempts}'
      ..resource = (MonitoredResource()..type = 'global');
    await _api.entries.write(logRequest);

    return Body.empty;
  }
}
