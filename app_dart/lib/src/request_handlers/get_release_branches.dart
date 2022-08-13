// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';

import '../../cocoon_service.dart';

/// Return a list of commit shas of the latest 5 branches for google3 roll, beta, and stable.
///
/// Branches are sorted based on the version number.
///
/// GET: /api/public/get-release-branches
///
/// Response: Status 200 OK
///[
///    {
///        "branch":"flutter-2.13-candidate.0",
///        "name":"stable"
///    },
///    {
///        "branch":"flutter-3.2-candidate.5",
///        "name":"beta"
///    },
///    {
///        "branch":"flutter-3.4-candidate.5",
///        "name":"dev"
///    }
///]

class GetReleaseBranches extends RequestHandler<Body> {
  GetReleaseBranches(Config config, {required this.branchService}) : super(config: config);

  final BranchService branchService;

  @override
  Future<Body> get() async {
    final GitHub github = await config.createGitHubClient(slug: Config.flutterSlug);
    List<Map<String, String>> branchNames =
        await branchService.getStableBetaDevBranches(github: github, slug: Config.flutterSlug);
    return Body.forJson(branchNames);
  }
}
