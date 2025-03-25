// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../../protos.dart' show BuildStatusResponse, EnumBuildStatus;
import '../service/build_status_provider.dart';

@immutable
class GetBuildStatus extends RequestHandler<Body> {
  const GetBuildStatus({
    required super.config,
    required BuildStatusService buildStatusService,
  }) : _buildStatusService = buildStatusService;

  final BuildStatusService _buildStatusService;
  static const _kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final response = await createResponse();
    return Body.forJson(response.toProto3Json());
  }

  Future<BuildStatusResponse> createResponse() async {
    final repoName = request!.uri.queryParameters[_kRepoParam] ?? 'flutter';
    final slug = RepositorySlug('flutter', repoName);
    final status = (await _buildStatusService.calculateCumulativeStatus(slug))!;
    return BuildStatusResponse()
      ..buildStatus =
          status.succeeded ? EnumBuildStatus.success : EnumBuildStatus.failure
      ..failingTasks.addAll(status.failedTasks);
  }
}
