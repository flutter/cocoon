// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';

@immutable
class ResetDevicelabTask extends ApiRequestHandler<Body> {
  const ResetDevicelabTask(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  static const String keyParam = 'Key';

  @override
  Future<Body> post() async {
    checkRequiredParameters(<String>[keyParam]);
    final DatastoreService datastore = datastoreProvider(config.db);
    final String encodedKey = requestData[keyParam] as String;
    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper =
        KeyHelper(applicationContext: clientContext.applicationContext);
    final Key key = keyHelper.decode(encodedKey);
    final Task task = await datastore.lookupByValue(key);
    if (task == null) {
      throw const BadRequestException('Invalid key. Entity does not exist.');
    }

    if (task.status == Task.statusInProgress) {
      throw const BadRequestException(
          'Not allowed to restart task in progress.');
    }
    task
      ..reason = ''
      ..status = Task.statusNew
      ..reservedForAgentId = '';
    await datastore.insert(<Task>[task]);

    return Body.empty;
  }
}
