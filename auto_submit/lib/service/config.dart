// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

import 'github_service.dart';

/// Represents the whole config for the autosubmit engine.
class Config {
  const Config();

  GitHub createGitHubClientWithToken(String token) {
    return GitHub(auth: Authentication.withToken(token));
  }

  GithubService createGithubServiceWithToken(String token) {
    final GitHub github = createGitHubClientWithToken(token);
    return GithubService(github);
  }
}
