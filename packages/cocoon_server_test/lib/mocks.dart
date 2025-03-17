// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@GenerateNiceMocks([MockSpec<AccessClientProvider>()])
import 'package:cocoon_server/access_client_provider.dart';

@GenerateNiceMocks([
  MockSpec<GitHub>(),
  MockSpec<GitHubComparison>(),
  MockSpec<PullRequestsService>(),
  MockSpec<RepositoriesService>(),
])
import 'package:github/github.dart';

@GenerateNiceMocks([MockSpec<JobsResource>()])
import 'package:googleapis/bigquery/v2.dart';

@GenerateNiceMocks([MockSpec<http.Response>()])
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';
