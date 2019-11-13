// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
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
import '../service/datastore.dart';

/// Serves a log file to the user as a text file.
/// 
/// If the query [downloadParam] is specified, the file will be sent as a download.
@immutable
class GetLog extends ApiRequestHandler<Body> {
  const GetLog(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String downloadParam = 'download';
  static const String ownerKeyParam = 'ownerKey';

  @override
  Future<Body> get() async {
    final String encodedOwnerKey = request.uri.queryParameters[ownerKeyParam];
    if (encodedOwnerKey == null) {
      throw const BadRequestException('Missing required query parameter: $ownerKeyParam');
    }

    final KeyHelper keyHelper = KeyHelper(applicationContext: context.applicationContext);
    final Key ownerKey = keyHelper.decode(encodedOwnerKey);

    final DatastoreService datastore = datastoreProvider();
    final Task task = await datastore.db.lookupValue<Task>(ownerKey, orElse: () => null);
    if (task == null) {
      throw const BadRequestException('Invalid owner key. Owner entity does not exist.');
    }

    final bool download = request.uri.queryParameters[downloadParam] == 'true';
    if (download) {
      response.headers.set('Content-Disposition', 'attachment; filename=${encodedOwnerKey}_${task.attempts}_${task.endTimestamp}.log');
      response.headers.set(HttpHeaders.contentTypeHeader, 'text/plain; charset=utf-8');
    } else {
      response.headers.set(HttpHeaders.contentTypeHeader, 'text/html; charset=utf-8');
    }

    return Body.forStream(_getResponse(datastore, task, ownerKey, download));
  }

  Stream<Uint8List> _getResponse(DatastoreService datastore, Task task, Key ownerKey, bool download) async* {
    if (!download) {
      yield utf8.encode('<!DOCTYPE html>');
      yield utf8.encode('<html><body><pre>\n\n');
    }

    yield utf8.encode('------------ TASK ------------\n');
    yield utf8.encode(task.toString());

    yield utf8.encode('\n\n------------ LOG ------------\n');
    final Query<LogChunk> query = datastore.db.query<LogChunk>()
      ..filter('ownerKey =', ownerKey)
      ..order('createTimestamp');
    yield* query.run().map<Uint8List>((LogChunk chunk) => chunk.data);

    if (!download) {
      yield utf8.encode('<EOF>');
      yield utf8.encode('</pre></body></html>');
    }
  }
}
