// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_service/src/foundation/github_checks_util.dart';
import 'package:cocoon_service/src/service/access_token_provider.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:cocoon_service/src/service/reservation_provider.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:cocoon_service/src/service/task_provider.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';

import '../request_handling/fake_http.dart';

class MockGitHub extends Mock implements GitHub {}

class MockRepositoriesService extends Mock implements RepositoriesService {}

class MockTabledataResourceApi extends Mock implements TabledataResourceApi {}

class MockAccessTokenService extends Mock implements AccessTokenService {}

class MockScheduler extends Mock implements Scheduler {}

class MockTaskService extends Mock implements TaskService {}

class MockReservationService extends Mock implements ReservationService {}

// ignore: must_be_immutable
class MockLuciService extends Mock implements LuciService {}

class MockIssuesService extends Mock implements IssuesService {}

class MockPullRequestsService extends Mock implements PullRequestsService {}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {
  final FakeHttpHeaders _fakeHeaders = FakeHttpHeaders();
  @override
  HttpHeaders get headers => _fakeHeaders;
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.response);

  final List<int> response;

  @override
  StreamSubscription<List<int>> listen(
    void onData(List<int> event), {
    Function onError,
    void onDone(),
    bool cancelOnError,
  }) {
    return Stream<List<int>>.fromFuture(Future<List<int>>.value(response))
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class MockHttpImageResponse extends Mock implements HttpClientResponse {
  MockHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void action(List<int> element)) async {
    response.forEach(action);
  }
}

class ThrowingGitHub implements GitHub {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw AssertionError();
}

// ignore: must_be_immutable, Test mock.
class MockBuildBucketClient extends Mock implements BuildBucketClient {}

class MockGithubChecksService extends Mock implements GithubChecksService {}

class MockLuciBuildService extends Mock implements LuciBuildService {}

class MockGithubChecksUtil extends Mock implements GithubChecksUtil {}
