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

  static const _passingParam = 'passing';
  static const _repoParam = 'repo';

  @override
  Future<Response> post(Request request) async {
    final body = await request.readBodyAsJson();
    checkRequiredParameters(body, [_passingParam, _repoParam]);

    final passing = body[_passingParam];
    if (passing is! bool) {
      throw const BadRequestException(
        'Parameter "$_passingParam" must be a boolean',
      );
    }

    final repository = body[_repoParam];
    if (repository is! String) {
      throw const BadRequestException(
        'Parameter "$_repoParam" must be a string',
      );
    }

    await TreeStatusChange.create(
      _firestore,
      createdOn: _now(),
      status: passing ? TreeStatus.success : TreeStatus.failure,
      authoredBy: authContext!.email,
      repository: RepositorySlug.full(repository),
    );
    return Response.emptyOk;
  }
}
