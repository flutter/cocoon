// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'models/git_branch.dart';
import 'models/github_repository.dart';
import 'pages/landing_page.dart';
import 'pages/repository_page.dart';

/// Routes to the `/v2/...` preview part of the application.
(WidgetBuilder, RouteSettings)? v2PreviewRoute(
  BuildContext context,
  Uri route,
  RouteSettings settings,
) {
  final [_, ...v2PathSegments] = route.pathSegments;
  if (v2PathSegments case [final repoOwner, final repoName]) {
    return (
      (_) {
        return V2RepositoryPage(
          repository: GithubRepository.from(repoOwner, repoName),
          branch: GitBranch.from('master'),
        );
      },
      RouteSettings(name: '/v2/$repoOwner/$repoName/branch/master'),
    );
  } else if (v2PathSegments case [
    final repoOwner,
    final repoName,
    'branch',
    final branchName,
  ]) {
    return (
      (_) {
        return V2RepositoryPage(
          repository: GithubRepository.from(repoOwner, repoName),
          branch: GitBranch.from(branchName),
        );
      },
      settings,
    );
  } else if (v2PathSegments case [final repoOwner, ...]) {
    return ((_) => V2LandingPage(repoOwner), settings);
  } else {
    return ((_) => const V2LandingPage(), settings);
  }
}
