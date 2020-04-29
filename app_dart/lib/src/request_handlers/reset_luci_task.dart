// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
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
    @required this.buildBucketClient,
  })  : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final BuildBucketClient buildBucketClient;

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

    final LuciBuildService luciBuildService = LuciBuildService(
      config: config,
      buildBucketClient: buildBucketClient,
    );
    // TODO
    await luciBuildService.rescheduleBuild(
      build: null,
      sha: null,
      builderName: null,
      retries: 0,
    );


    return Body.empty;
  }
}
