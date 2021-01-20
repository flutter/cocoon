// Copyright 2019 The Flutter Authors. All rights reserved.
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
@immutable
class GetLog extends ApiRequestHandler<Body> {
  const GetLog(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String ownerKeyParam = 'ownerKey';

  @override
  Future<Body> get() async {
    final String encodedOwnerKey = request.uri.queryParameters[ownerKeyParam];
    if (encodedOwnerKey == null) {
      throw const BadRequestException('Missing required query parameter: $ownerKeyParam');
    }

    final KeyHelper keyHelper = KeyHelper(applicationContext: context.applicationContext);
    final Key<int> ownerKey = keyHelper.decode(encodedOwnerKey) as Key<int>;

    final DatastoreService datastore = datastoreProvider(config.db);
    final Task task = await datastore.db.lookupValue<Task>(ownerKey, orElse: () => null);
    if (task == null) {
      throw const BadRequestException('Invalid owner key. Owner entity does not exist.');
    }

    response.headers.set(HttpHeaders.contentTypeHeader, 'text/html; charset=utf-8');

    return Body.forStream(_getResponse(datastore, task, ownerKey));
  }

  Stream<Uint8List> _getResponse(DatastoreService datastore, Task task, Key<int> ownerKey) async* {
    yield utf8.encode('\n\n------------ TASK ------------\n') as Uint8List;
    yield utf8.encode(task.toString()) as Uint8List;

    yield utf8.encode('\n\n------------ LOG ------------\n') as Uint8List;
    final Query<LogChunk> query = datastore.db.query<LogChunk>()
      ..filter('ownerKey =', ownerKey)
      ..order('createTimestamp');
    yield* query.run().map<Uint8List>((LogChunk chunk) => chunk.data as Uint8List);
  }
}
