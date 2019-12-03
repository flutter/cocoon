// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/server.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService(this.statuses);

  final List<dynamic> statuses;

  @override
  final GitHub github = null;

  @override
  final RepositorySlug slug = null;

  @override
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
    return statuses;
  }
}

