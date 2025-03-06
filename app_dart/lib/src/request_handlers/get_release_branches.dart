// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/request_handling/request_handler.dart';

import '../request_handling/body.dart';
import '../service/branch_service.dart';
import '../service/config.dart';

/// Return a list of release branch information.
///
/// GET: /api/public/get-release-branches
///
/// Response: Status 200 OK
///[
///    {
///        "reference":"flutter-2.13-candidate.0",
///        "channel":"stable"
///    },
///    {
///        "reference":"flutter-3.2-candidate.5",
///        "channel":"beta"
///    },
///    {
///        "reference":"flutter-3.4-candidate.5",
///        "channel":"dev"
///    }
///]

final class GetReleaseBranches extends RequestHandler<Body> {
  GetReleaseBranches({required super.config, required BranchService branchService}) : _branchService = branchService;

  final BranchService _branchService;

  @override
  Future<Body> get() async {
    return Body.forJson(await _branchService.getReleaseBranches(slug: Config.flutterSlug));
  }
}
