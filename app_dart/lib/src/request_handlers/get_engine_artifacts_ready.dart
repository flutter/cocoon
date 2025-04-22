// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/ci_staging.dart';
import '../request_handling/exceptions.dart';

/// Query if engine artifacts are ready for a given commit SHA.
///
/// ```txt
/// GET /api/public/engine-artifacts-ready?sha=<sha>
/// ```
///
/// It would return:
/// - `200 OK`: The SHA matched a commit in our database
/// - `404 NOT FOUND`: **Error**, the SHA did not match a commit in our database.
///
/// If 200 OK, we'd return as the body of the response either:
/// - `{status: "complete"}`; the engine artifacts were built and uploaded
/// - `{status: "pending"}`; the engine artifacts are in the progress of being built
/// - `{status: "failed"}`; the engine artifacts will not be uploaded as there was a failure building the engine
@immutable
final class GetEngineArtifactsReady extends RequestHandler<Body> {
  const GetEngineArtifactsReady({
    required super.config,
    required FirestoreService firestore,
  }) : _firestore = firestore;

  final FirestoreService _firestore;

  static const _paramSha = 'sha';

  @override
  Future<Body> get() async {
    final commitSha = request!.uri.queryParameters[_paramSha];
    if (commitSha == null) {
      throw const BadRequestException('Missing query parameter: "$_paramSha"');
    }

    final CiStaging ciStaging;
    try {
      ciStaging = await CiStaging.fromFirestore(
        firestoreService: _firestore,
        documentName: CiStaging.documentNameFor(
          slug: Config.flutterSlug,
          sha: commitSha,
          stage: CiStage.fusionEngineBuild,
        ),
      );
    } on DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.notFound) {
        response!.statusCode = HttpStatus.notFound;
        return Body.empty;
      }
      rethrow;
    }

    if (ciStaging.failed > 0) {
      return Body.forJson(_GetEngineArtifactsResponse.failed);
    }

    if (ciStaging.remaining > 0) {
      return Body.forJson(_GetEngineArtifactsResponse.pending);
    }

    return Body.forJson(_GetEngineArtifactsResponse.complete);
  }
}

enum _GetEngineArtifactsResponse {
  failed,
  pending,
  complete;

  Map<String, Object?> toJson() {
    return {'status': name};
  }
}
