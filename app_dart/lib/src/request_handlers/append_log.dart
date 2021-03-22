// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/config.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/log_chunk.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import '../service/stackdriver_logger.dart';

@immutable
class AppendLog extends ApiRequestHandler<Body> {
  AppendLog(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    StackdriverLoggerService stackdriverLogger,
    @visibleForTesting Uint8List requestBodyValue,
  })  : stackdriverLogger = stackdriverLogger ?? StackdriverLoggerService(config: config),
        super(config: config, authenticationProvider: authenticationProvider, requestBodyValue: requestBodyValue);

  final StackdriverLoggerService stackdriverLogger;
  final DatastoreServiceProvider datastoreProvider;

  static const String ownerKeyParam = 'ownerKey';

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final String encodedOwnerKey = request.uri.queryParameters[ownerKeyParam];
    if (encodedOwnerKey == null) {
      throw const BadRequestException('Missing required query parameter: $ownerKeyParam');
    }

    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper = KeyHelper(applicationContext: clientContext.applicationContext);
    final Key<int> ownerKey = keyHelper.decode(encodedOwnerKey) as Key<int>;

    final Task task = await datastore.lookupByValue<Model<int>>(ownerKey, orElse: () {
      throw const InternalServerError('Invalid owner key. Owner entity does not exist');
    }) as Task;

    final LogChunk logChunk = LogChunk(
      ownerKey: ownerKey,
      createTimestamp: DateTime.now().millisecondsSinceEpoch,
      data: requestBody,
    );

    await datastore.insert(<LogChunk>[logChunk]);
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
