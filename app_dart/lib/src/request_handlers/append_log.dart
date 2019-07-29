// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';
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
      throw BadRequestException('Missing required query parameter: $ownerKeyParam');
    }

    final ClientContext clientContext = authContext.clientContext;
    final KeyHelper keyHelper = KeyHelper(applicationContext: clientContext.applicationContext);
    final Key ownerKey = keyHelper.decode(encodedOwnerKey);

    await config.db.lookupValue<Model>(ownerKey, orElse: () {
      throw InternalServerError('Invalid owner key. Owner entity does not exist');
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

    return Body.empty;
  }
}
