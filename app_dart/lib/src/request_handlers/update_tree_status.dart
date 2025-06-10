// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/firestore/tree_status_change.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/firestore.dart';

/// Manually updates the tree status.
final class UpdateTreeStatus extends ApiRequestHandler {
  const UpdateTreeStatus({
    required FirestoreService firestore,
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _firestore = firestore,
       _now = now;

  final FirestoreService _firestore;
  final DateTime Function() _now;

  static const _paramPassing = 'passing';
  static const _paramRepo = 'repo';
  static const _paramReason = 'reason';

  @override
  Future<Response> post(Request request) async {
    final body = await request.readBodyAsJson();
    checkRequiredParameters(body, [_paramPassing, _paramRepo]);

    final passing = body[_paramPassing];
    if (passing is! bool) {
      throw const BadRequestException(
        'Parameter "$_paramPassing" must be a boolean',
      );
    }

    final RepositorySlug repository;
    {
      final repositoryString = body[_paramRepo];
      if (repositoryString is! String) {
        throw const BadRequestException(
          'Parameter "$_paramRepo" must be a string',
        );
      }
      repository = RepositorySlug('flutter', repositoryString);
    }

    final reason = body[_paramReason];
    if (reason is! String?) {
      throw const BadRequestException(
        'Parameter "$_paramReason" must be a string',
      );
    }

    await TreeStatusChange.create(
      _firestore,
      createdOn: _now(),
      status: passing ? TreeStatus.success : TreeStatus.failure,
      authoredBy: authContext!.email,
      repository: repository,
      reason: reason,
    );
    return Response.emptyOk;
  }
}
