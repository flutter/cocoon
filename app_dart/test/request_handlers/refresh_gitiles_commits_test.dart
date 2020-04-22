// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/refresh_gitiles_commits.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

const String skiaCommits = ''')]}{
      "log": [
        {"commit": "c1", 
        "author": {"name": "n1"},
        "committer": {"time": "Wed Apr 22 17:58:07 2020 +0000"},
        "message": "abc"},
        {"commit": "c2", 
        "author": {"name": "n2"},
        "committer": {"time": "Wed Apr 21 17:58:07 2020 +0000"},
        "message": "def"}]}''';
const String commits = ''')]}{
      "log": [
        {"commit": "c2", 
        "author": {"name": "n2"},
        "committer": {"time": "Wed Apr 21 17:58:07 2020 +0000"},
        "message": "Roll src/third_party/skia abc...def"}]}''';
const String rollCommits = ''')]}{
      "log": [
        {"commit": "c3", 
        "author": {"name": "n3"},
        "committer": {"time": "Wed Apr 20 17:58:07 2020 +0000"},
        "message": "ghi"},
        {"commit": "c4", 
        "author": {"name": "n4"},
        "committer": {"time": "Wed Apr 19 17:58:07 2020 +0000"},
        "message": "jkl"}]}''';

void main() {
  group('RefreshGitilesCommits', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    RefreshGitilesCommits handler;
    FakeHttpClient httpClient;
    FakeHttpClient rollHttpClient;
    FakeTabledataResourceApi tabledataResourceApi;

    setUp(() {
      tester = ApiRequestHandlerTester();
      httpClient = FakeHttpClient();
      rollHttpClient = FakeHttpClient();
      tabledataResourceApi = FakeTabledataResourceApi();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi);
      handler = RefreshGitilesCommits(
        config,
        FakeAuthenticationProvider(),
        httpClientProvider: () => httpClient,
        rollHttpClientProvider: () => rollHttpClient,
      );
    });

    test('insert to bigquery for non-roller commit list', () async {
      httpClient.request.response.body = skiaCommits;

      await tester.get(handler);

      /// Insert happens four times `skia, dart, engine, flutter`. Each time
      /// it inserts two commits in [skiaCommits].
      expect(tabledataResourceApi.rows.length, 8);
    });

    test('insert to bigquery for commit list with roll commit', () async {
      httpClient.request.response.body = commits;
      rollHttpClient.request.response.body = rollCommits;

      await tester.get(handler);

      /// Insert happens four times `skia, dart, engine, flutter`. Each time
      /// it inserts one commit in [commits] and two commits in [rollCommits].
      expect(tabledataResourceApi.rows.length, 12);
    });
  });
}
