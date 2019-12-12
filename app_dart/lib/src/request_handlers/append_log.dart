// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/stackdriver_logger.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/log_chunk.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';

@immutable
class AppendLog extends ApiRequestHandler<Body> {
  AppendLog(
    Config config,
    AuthenticationProvider authenticationProvider, {
    StackdriverLoggerService stackdriverLogger,
    @visibleForTesting Uint8List requestBodyValue,
  })  : stackdriverLogger =
            stackdriverLogger ?? StackdriverLoggerService(config: config),
        super(config: config, authenticationProvider: authenticationProvider, requestBodyValue: requestBodyValue);

  final StackdriverLoggerService stackdriverLogger;

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

    await writeToStackdriver('${encodedOwnerKey}_${task.attempts}');

    return Body.empty;
  }

  /// Write the log data from this request to Stackdriver under [logName].
  ///
  /// [logName] must follow the format `[encodedOwnerKey]_[task.attempt]` so each
  /// attempt for a task can be located.
  ///
  /// This will write the log to the global path `projects/flutter-dashboard/logs/[logName]` on Google Cloud.
  Future<void> writeToStackdriver(String logName) async {
    final List<String> lines = String.fromCharCodes(requestBody).split('\n');
    await stackdriverLogger.writeLines(logName, lines);
  }
}
