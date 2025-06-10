// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart' as rpc;
import 'package:github/github.dart';

import '../model/firestore/tree_status_change.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/firestore.dart';

/// Returns the last 10 tree status updates for a repository.
final class GetTreeStatus extends ApiRequestHandler {
  const GetTreeStatus({
    required FirestoreService firestore,
    required super.config,
    required super.authenticationProvider,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  static const _paramRepo = 'repo';

  @override
  Future<Response> get(Request request) async {
    checkRequiredQueryParameters(request, [_paramRepo]);

    final changes = await TreeStatusChange.getLatest10(
      _firestore,
      repository: RepositorySlug(
        'flutter',
        request.uri.queryParameters[_paramRepo]!,
      ),
    );

    return Response.json([
      ...changes.map((change) {
        return rpc.TreeStatusChange(
          authoredBy: change.authoredBy,
          createdOn: change.createdOn,
          reason: change.reason,
          status: switch (change.status) {
            TreeStatus.success => rpc.TreeStatus.success,
            TreeStatus.failure => rpc.TreeStatus.failure,
          },
        );
      }),
    ]);
  }
}
