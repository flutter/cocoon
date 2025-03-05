// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/branch_service.dart';
import '../service/config.dart';
import '../service/github_service.dart';

/// Return a list of release branch information.
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
  GetReleaseBranches({required super.config, required this.branchService});

  final BranchService branchService;

  @override
  Future<Body> get() async {
    final github = await config.createGitHubClient(slug: Config.flutterSlug);
    final githubService = GithubService(github);
    final branchNames = await branchService.getReleaseBranches(
      githubService: githubService,
      slug: Config.flutterSlug,
    );
    return Body.forJson(branchNames);
  }
}
