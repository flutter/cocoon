// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// List of supported repositories.
const List<String> repos = <String>[
  'flutter',
];

Future<void> main() async {
  for (final String repo in repos) {
    test('validate test ownership in repo $repo', () async {
      final String ciYamlFile = 'flutter/$repo/master/$kCiYamlPath';
      final String ciYamlContent = await githubFileContent(
        ciYamlFile,
        httpClientProvider: () => http.Client(),
      );
      final String testOwnerFile = 'flutter/$repo/master/$kTestOwnerPath';
      final String testOwnersContent = await githubFileContent(
        testOwnerFile,
        httpClientProvider: () => http.Client(),
      );

      try {
        validateOwnership(ciYamlContent, testOwnersContent);
      } on FormatException catch (e) {
        fail(e.message);
      }
    });
  }
}
