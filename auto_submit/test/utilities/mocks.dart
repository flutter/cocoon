// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/access_client_provider.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

export 'mocks.mocks.dart';

@GenerateMocks(<Type>[
  AccessClientProvider,
  JobsResource,
  ApproverService,
  GitHub,
  PullRequestsService,
  RepositoriesService,
  GitHubComparison,
  http.Response,
])
void main() {}
