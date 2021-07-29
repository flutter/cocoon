// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:test/test.dart';

/// List of supported repositories.
const List<String> repos = <String>[
  'flutter',
];

Future<void> main() async {
  for (final String repo in repos) {
    test('validate test ownership in repo $repo', () async {
      final String ciYamlFile = 'flutter/$repo/master/.ci.yaml';
      final String ciYamlContent = await githubFileContent(
        ciYamlFile,
        httpClientProvider: () => io.HttpClient(),
      );
      final String testOwnerFile = 'flutter/$repo/master/TESTOWNER';
      final String testOwnersContent = await githubFileContent(
        testOwnerFile,
        httpClientProvider: () => io.HttpClient(),
      );

      try {
        validateOwnership(ciYamlContent, testOwnersContent);
      } on FormatException catch (e) {
        fail(e.message);
      }
    });
  }
}
