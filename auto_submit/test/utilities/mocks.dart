// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/requests/cirrus_graphql_client.dart';
import 'package:github/github.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks(<Type>[
  GithubService,
  GitHub,
  PullRequestsService,
  RepositoriesService,
  CirrusGraphQLClient,
])
void main() {}
