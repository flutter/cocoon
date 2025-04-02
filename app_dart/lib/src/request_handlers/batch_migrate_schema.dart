// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/firestore.dart';

/// A handler that batch updates all documents in Firestore on-demand.
@immutable
final class BatchMigrateSchema extends ApiRequestHandler<Body> {
  BatchMigrateSchema({
    required super.config,
    required super.authenticationProvider,
  });

  @override
  Future<Body> get() async {
    // Check HTTP Header.
    // This is a long operation, so we don't want to run it manually.
    // See https://cloud.google.com/appengine/docs/flexible/scheduling-jobs-with-cron-yaml#securing_urls_for_cron.
    if (request!.headers.value('X-Appengine-Cron') != 'true') {
      response!.statusCode = HttpStatus.forbidden;
      response!.reasonPhrase = 'Can only be executed by AppEngine Cron';
      return Body.empty;
    }

    // Check if it is a dry run (log only, no writes).
    final dryRun = request!.uri.queryParameters['dry-run'] == 'true';

    final firestore = await config.createFirestoreService();
    final documents = await firestore.documentResource();

    // http://cloud/firestore/docs/reference/rest/v1/projects.databases.documents/listDocuments
    documents.listDocuments(p.posix.join(kDatabase, 'documents'), 'ci_staging');

    return Body.empty;
  }
}
