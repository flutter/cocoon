// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:cocoon_service/src/request_handlers/github/webhook_subscription.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/access_token_provider.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/build_bucket_client.dart';
import 'package:cocoon_service/src/service/commit_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:process/process.dart';

import '../../service/cache_service_test.dart';
import '../service/fake_auth_client.dart';

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

Future<AutoRefreshingAuthClient> authClientProviderShim({
  http.Client? baseClient,
  required List<String> scopes,
}) async =>
    FakeAuthClient(baseClient ?? MockClient((_) => throw const InternalServerError('Test did not set up HttpClient')));

@GenerateMocks(
  <Type>[
    AccessTokenService,
    BigqueryService,
    BranchService,
    BuildBucketClient,
    CommitService,
    Config,
    DatastoreService,
    FakeEntry,
    FirestoreService,
    IssuesService,
    GithubChecksService,
    GithubChecksUtil,
    GithubService,
    GitService,
    GraphQLClient,
    HttpClient,
    HttpClientRequest,
    HttpClientResponse,
    LuciBuildService,
    ProcessManager,
    SearchService,
    TabledataResource,
    UsersService,
    ProjectsDatabasesDocumentsResource,
    BeginTransactionResponse,
    Callbacks,
    PullRequestLabelProcessor,
  ],
  customMocks: [
    MockSpec<Cache<Uint8List>>(),
    // MockSpec<GitHub>(
    //   fallbackGenerators: <Symbol, Function>{
    //     #postJSON: postJsonShim,
    //   },
    // ),
  ],
)
void main() {}

class ThrowingGitHub implements GitHub {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw AssertionError();
}

abstract class Callbacks {
  Future<StagingConclusion> markCheckRunConclusion({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required String checkRun,
    required String conclusion,
  });

  Future<Document> initializeDocument({
    required FirestoreService firestoreService,
    required RepositorySlug slug,
    required String sha,
    required CiStage stage,
    required List<String> tasks,
    required String checkRunGuard,
  });

  /// See [PrCheckRuns.initializeDocument]
  Future<Document> initializePrCheckRuns({
    required FirestoreService firestoreService,
    required PullRequest pullRequest,
    required List<CheckRun> checks,
  });

  /// See [PrCheckRuns.findPullRequestFor]
  Future<PullRequest> findPullRequestFor(
    FirestoreService firestoreService,
    int checkRunId,
    String checkRunName,
  );
}
