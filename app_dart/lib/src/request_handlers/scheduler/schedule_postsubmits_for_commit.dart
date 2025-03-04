// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/request_handling/api_request_handler.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'schedule_postsubmits_for_commit.g.dart';

/// Schedules post-submits for the given repo/branch/commit.
///
/// This API is intended to be used by the release team to manually schedule
/// post-submit builds and tests after the mysterious Dart cronjob finishes
/// building the engine artifacts necessary to run the builds/tests.
@immutable
final class SchedulePostsubmitsForCommit extends ApiRequestHandler<Body> {
  const SchedulePostsubmitsForCommit({
    required super.config,
    required super.authenticationProvider,
    required Scheduler scheduler,
    required DatastoreDB datastore,
  })  : _datastore = datastore,
        _scheduler = scheduler;

  final DatastoreDB _datastore;
  final Scheduler _scheduler;

  @override
  Future<Body> post() async {
    // Validate we have required (but not necessarily correct) input.
    if (requestData == null) {
      throw const BadRequestException('Missing POST body');
    }
    final _Request request;
    try {
      request = _Request.fromJson(requestData!);
    } on CheckedFromJsonException catch (e) {
      throw BadRequestException('Invalid POST body: $e');
    } catch (_) {
      rethrow;
    }

    // Validate we have input that, in theory, will be successful.
    log.info('[SchedulePostsubmitsForCommit] Attempting to schedule post-submit tasks for $request');
    if (request.repo != 'flutter' || request.branch == 'master') {
      throw BadRequestException(
        'Only non-master (${request.branch}) branches on the flutter (${request.repo}) repo '
        'can use SchedulePostsubmitsForCommit',
      );
    }

    // Create a synthetic Commit object that has the properties necessary to be used in Scheduler.
    final commit = Commit(
      // Hard-coded because we validate above.
      repository: 'flutter/flutter',
      key: _datastore.emptyKey.append(
        Commit,
        id: 'flutter/flutter/${request.branch}/${request.commit}',
      ),
      sha: request.commit,
      branch: request.branch,
      message: 'SchedulePostsubmitsForCommit',
    );

    // Do it
    if (await _scheduler.addCommit(commit)) {
      return Body.empty;
    } else {
      response!.statusCode = HttpStatus.internalServerError;
      return Body.forString('Failed to schedule tasks for reasons. See logs for details.');
    }
  }
}

/// Represents the body of a [SchedulePostsubmitsForCommit] request.
///
/// ![](https://github.com/user-attachments/assets/f10a2068-2f64-4bc7-b1a0-a25cdaceb174)
@JsonSerializable(checked: true)
@immutable
final class _Request {
  const _Request({
    required this.repo,
    required this.branch,
    required this.commit,
  });

  factory _Request.fromJson(Map<String, Object?> json) => _$RequestFromJson(json);

  /// Which repository this request is for.
  ///
  /// For example `flutter` or `cocoon`.
  @JsonKey()
  final String repo;

  /// Which branch this request is for.
  ///
  /// For example `master`, `main`, or `flutter-3.29-candidate.0`.
  @JsonKey()
  final String branch;

  /// Which commit (SHA) this request is for.
  @JsonKey()
  final String commit;

  /// Returns the JSON object representation of `this`.
  Map<String, Object?> toJson() => _$RequestToJson(this);

  @override
  String toString() {
    return 'Request ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }
}
