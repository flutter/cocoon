// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'common.dart';

/// List of supported repositories with TESTOWNERS.
final List<SupportedConfig> configs = <SupportedConfig>[SupportedConfig(RepositorySlug('flutter', 'flutter'))];

Future<void> main() async {
  for (final SupportedConfig config in configs) {
    test('validate test ownership for $config', () async {
      final String ciYamlContent = await githubFileContent(
        config.slug,
        '.ci.yaml',
        httpClientProvider: () => http.Client(),
        ref: config.branch,
      );
      final String testOwnersContent = await githubFileContent(
        config.slug,
        kTestOwnerPath,
        httpClientProvider: () => http.Client(),
        ref: config.branch,
      );

      try {
        validateOwnership(ciYamlContent, testOwnersContent);
      } on FormatException catch (e) {
        fail(e.message);
      }
    });
  }
}
