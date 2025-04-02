// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../model/firestore/base.dart';
import '../model/firestore/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/firestore.dart';

/// A handler that batch updates all documents in Firestore on-demand.
@immutable
final class BatchMigrateSchema extends ApiRequestHandler<Body> {
  static const _enabledMigrations = [TaskMigration()];

  static const _queryParamDryRun = 'dry-run';
  static const _queryParamPageSize = 'size-per-batch';
  static const _defaultValuePageSize = 100;

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

    // Configuration.
    final int pageSize;
    final bool dryRun;
    {
      final queryParams = request!.uri.queryParameters;
      if (queryParams[_queryParamDryRun] case final value?) {
        dryRun = value == 'true';
      } else {
        dryRun = false;
      }
      if (queryParams[_queryParamPageSize] case final value?) {
        pageSize = int.parse(value);
      } else {
        pageSize = _defaultValuePageSize;
      }
    }

    final firestore = await config.createFirestoreService();
    final documents = await firestore.documentResource();

    // http://cloud/firestore/docs/reference/rest/v1/projects.databases.documents/listDocuments
    for (final migration in _enabledMigrations) {
      String? pageToken;
      do {
        final response = await documents.listDocuments(
          p.posix.join(kDatabase, 'documents'),
          migration.runtimeMetadta.collectionId,
          pageSize: pageSize,
        );

        if (response.documents == null) {
          break;
        }

        final writes = <g.Write>[];
        for (final document in response.documents!) {
          final write = migration.update(
            migration.runtimeMetadta.fromDocument(document),
          );
          if (write != null) {
            writes.add(write);
          }
        }

        if (writes.isNotEmpty && !dryRun) {
          await documents.batchWrite(
            g.BatchWriteRequest(writes: writes),
            kDatabase,
          );
        } else if (dryRun) {
          log.info(
            'Would have written ${writes.length} changes to '
            '${migration.runtimeMetadta.collectionId}.',
          );
          for (final write in writes) {
            log.debug(
              write.update!.fields!
                  .map((k, v) => MapEntry(k, v.toJson().values.first))
                  .toString(),
            );
          }
        }

        pageToken = response.nextPageToken;
      } while (pageToken != null);
    }

    return Body.empty;
  }
}

/// Defines a migration, which is a poor man's "batch update some documents".
@immutable
abstract base class Migration<T extends AppDocument<T>> {
  const Migration();

  /// Describes the structure of [T].
  AppDocumentMetadata<T> get runtimeMetadta;

  /// Returns if a write if [model] should be updated, or `null` for no updates.
  g.Write? update(T model);
}

final class TaskMigration extends Migration<Task> {
  const TaskMigration();

  @override
  AppDocumentMetadata<Task> get runtimeMetadta => Task.metadata;

  @override
  g.Write? update(Task model) {
    if (model.fields!.containsKey('attempt')) {
      return null;
    }
    return g.Write(
      currentDocument: g.Precondition(exists: true),
      update: g.Document(
        fields: {'attempt': g.Value(integerValue: '${model.attempts}')},
      ),
      updateMask: g.DocumentMask(fieldPaths: ['attempt']),
    );
  }
}
