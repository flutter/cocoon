// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/src/service/gerrit_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late MockClient mockHttpClient;
  late GerritService gerritService;
  group('getBranches', () {
    test('Error in request', () async {
      mockHttpClient = MockClient((_) async => http.Response(')]}\'\n[]', HttpStatus.forbidden));
      gerritService = GerritService(httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches('myhost', 'a/b/c', 'flutter-');
      expect(branches, equals(<String>[]));
    });
    test('Returns a list of branches', () async {
      const String body =
          ')]}\'\n[{"web_links":[{"name":"browse","url":"https://a.com/branch_a","target":"_blank"}],"ref":"refs/heads/branch_a","revision":"0bc"}]';
      mockHttpClient = MockClient((_) async => http.Response(body, HttpStatus.ok));
      gerritService = GerritService(httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches('myhost', 'a/b/c', 'flutter-');
      expect(branches, equals(<String>['refs/heads/branch_a']));
    });

    test('No results return an empty list', () async {
      mockHttpClient = MockClient((_) async => http.Response(')]}\'\n[]', HttpStatus.ok));
      gerritService = GerritService(httpClient: mockHttpClient);
      final List<String> branches = await gerritService.branches('myhost', 'a/b/c', 'flutter-');
      expect(branches, equals(<String>[]));
    });
  });
}
