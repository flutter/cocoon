// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';

@immutable
final class GetPresubmitGuard extends ApiRequestHandler {
  const GetPresubmitGuard({
    required super.config,
    required super.authenticationProvider,
    required FirestoreService firestore,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  static const String kSlugParam = 'slug';
  static const String kShaParam = 'sha';

  @override
  Future<Response> get(Request request) async {
    checkRequiredQueryParameters(request, [kSlugParam, kShaParam]);

    final slugName = request.uri.queryParameters[kSlugParam]!;
    final sha = request.uri.queryParameters[kShaParam]!;

    final slug = RepositorySlug.full(slugName);
    final guards = await _firestore.queryPresubmitGuards(
      slug: slug,
      commitSha: sha,
    );

    if (guards.isEmpty) {
      return Response.json(null);
    }

    // Consolidate metadata from the first record.
    final first = guards.first;
    final response = rpc_model.PresubmitGuardResponse(
      prNum: first.pullRequestId,
      checkRunId: first.checkRunId,
      author: first.author,
      stages: [
        ...guards.map(
          (g) => rpc_model.PresubmitGuardStage(
            name: g.stage.name,
            createdAt: g.creationTime,
            builds: g.builds,
          ),
        ),
      ],
    );

    return Response.json(response.toJson());
  }
}
