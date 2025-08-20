// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart' as rpc;

import '../request_handling/api_request_handler.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/content_aware_hash_service.dart';

/// Aids developers in locating git hashes or content hashes.
final class LookupHash extends ApiRequestHandler {
  const LookupHash({
    required ContentAwareHashService contentAwareHashService,
    required super.config,
    required super.authenticationProvider,
  }) : _contentAwareHashService = contentAwareHashService;

  final ContentAwareHashService _contentAwareHashService;

  static const _paramHash = 'hash';

  @override
  Future<Response> get(Request request) async {
    checkRequiredQueryParameters(request, [_paramHash]);

    final hashes = await _contentAwareHashService.getBuildsByHash(
      request.uri.queryParameters[_paramHash]!,
    );

    return Response.json([
      for (var hash in hashes)
        rpc.ContentHashLookup(
          contentHash: hash.contentHash,
          gitShas: [hash.commitSha, ...hash.waitingShas],
        ),
    ]);
  }
}
