// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/service/access_client_provider.dart';
import 'package:cocoon_service/src/service/access_token_provider.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:neat_cache/neat_cache.dart';

import '../../service/cache_service_test.dart';

export 'mocks.mocks.dart';

/// Fallback generated function for returning default values from the generic
/// function [GitHub.postJSON].
Future<T> postJsonShim<S, T>(
  dynamic path, {
  int? statusCode,
  void Function(http.Response)? fail,
  Map<String, String>? headers,
  Map<String, dynamic>? params,
  T Function(S)? convert,
  dynamic body,
  String? preview,
}) {
  if (T == PullRequest) {
    return Future<T>.value(PullRequest() as T);
  }
  throw Exception('MockGitHub.postJSON does not return $T.\n'
      'Either add it to postJsonShim or use a manual mock.');
}

const List<MockSpec<dynamic>> _mocks = <MockSpec<dynamic>>[
  MockSpec<Cache<Uint8List>>(),
  MockSpec<GitHub>(
    fallbackGenerators: <Symbol, Function>{
      #postJSON: postJsonShim,
    },
  ),
];

@GenerateMocks(
  <Type>[
    AccessClientProvider,
    AccessTokenService,
    BigqueryService,
    BuildBucketClient,
    FakeEntry,
    IssuesService,
    // GitHub,
    GithubChecksService,
    GithubChecksUtil,
    GithubService,
    GitService,
    GraphQLClient,
    HttpClient,
    HttpClientRequest,
    HttpClientResponse,
    JobsResource,
    LuciBuildService,
    LuciService,
    PullRequestsService,
    RepositoriesService,
    TabledataResource,
    UsersService,
  ],
  customMocks: _mocks,
)
void main() {}

class ThrowingGitHub implements GitHub {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw AssertionError();
}
