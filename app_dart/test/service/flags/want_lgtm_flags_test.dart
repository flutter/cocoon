// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:cocoon_service/src/service/flags/want_lgtm_flags.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  useTestLoggerPerTest();

  group('WantLgtmFlags', () {
    test('defaultInstance has expected defaults', () {
      const flags = WantLgtmFlags.defaultInstance;
      expect(flags.enabled, isFalse);
      expect(flags.useForAllRepos, isFalse);
      expect(flags.enabledRepos, isEmpty);
    });

    test('isEnabledForRepo returns false when enabled is false', () {
      final flags = WantLgtmFlags(
        enabled: false,
        useForAllRepos: true,
        enabledRepos: ['flutter/cocoon'],
      );
      expect(
        flags.isEnabledForRepo(RepositorySlug('flutter', 'cocoon')),
        isFalse,
      );
      expect(
        flags.isEnabledForRepo(RepositorySlug('flutter', 'flutter')),
        isFalse,
      );
    });

    test(
      'isEnabledForRepo returns true for any repo when useForAllRepos is true',
      () {
        final flags = WantLgtmFlags(
          enabled: true,
          useForAllRepos: true,
          enabledRepos: [],
        );
        expect(
          flags.isEnabledForRepo(RepositorySlug('flutter', 'cocoon')),
          isTrue,
        );
        expect(
          flags.isEnabledForRepo(RepositorySlug('flutter', 'flutter')),
          isTrue,
        );
      },
    );

    test('isEnabledForRepo matches case-insensitively in enabledRepos', () {
      final flags = WantLgtmFlags(
        enabled: true,
        useForAllRepos: false,
        enabledRepos: ['flutter/Cocoon'],
      );
      expect(
        flags.isEnabledForRepo(RepositorySlug('flutter', 'cocoon')),
        isTrue,
      );
      expect(
        flags.isEnabledForRepo(RepositorySlug('Flutter', 'COCOON')),
        isTrue,
      );
      expect(
        flags.isEnabledForRepo(RepositorySlug('flutter', 'flutter')),
        isFalse,
      );
    });

    test('JSON round-trip preserves values', () {
      final flags = WantLgtmFlags(
        enabled: true,
        useForAllRepos: false,
        enabledRepos: ['flutter/cocoon', 'flutter/flutter'],
      );
      final json = flags.toJson();
      final decoded = WantLgtmFlags.fromJson(json);

      expect(decoded.enabled, isTrue);
      expect(decoded.useForAllRepos, isFalse);
      expect(decoded.enabledRepos, ['flutter/cocoon', 'flutter/flutter']);
    });
  });

  group('DynamicConfig integration', () {
    test('defaultInstance contains WantLgtmFlags.defaultInstance', () {
      expect(DynamicConfig.defaultInstance.wantLgtm.enabled, isFalse);
      expect(
        DynamicConfig.defaultInstance.isWantLgtmEnabledForRepo(
          RepositorySlug('flutter', 'cocoon'),
        ),
        isFalse,
      );
    });

    test('parses wantLgtm from YAML', () {
      const yamlContent = '''
wantLgtm:
  enabled: true
  useForAllRepos: false
  enabledRepos:
    - flutter/cocoon
''';
      final yaml = loadYaml(yamlContent) as YamlMap;
      final config = DynamicConfig.fromYaml(yaml);

      expect(config.wantLgtm.enabled, isTrue);
      expect(
        config.isWantLgtmEnabledForRepo(RepositorySlug('flutter', 'cocoon')),
        isTrue,
      );
      expect(
        config.isWantLgtmEnabledForRepo(RepositorySlug('flutter', 'flutter')),
        isFalse,
      );
    });
  });
}
