// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/log_analyzer.dart';
import 'package:genkit/genkit.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();
  group('FakeLogAnalyzer', () {
    test('returns default reply', () async {
      final analyzer = FakeLogAnalyzer();
      expect(await analyzer.analyze(prompt: 'test'), 'Fake analysis result');
    });

    test('returns custom reply', () async {
      final analyzer = FakeLogAnalyzer('custom reply');
      expect(await analyzer.analyze(prompt: 'test'), 'custom reply');
    });
  });

  group('GenkitLogAnalyzer', () {
    test('throws state error when no plugins registered', () async {
      final ai = Genkit(plugins: []);
      final analyzer = GenkitLogAnalyzer(
        ai,
        modelName: 'gemini-3-flash-preview',
      );

      // Expect a StateError or similar when trying to use a model without the plugin.
      // Genkit throws StateError when looking up a model that isn't registered.
      expect(
        () => analyzer.analyze(prompt: 'test'),
        throwsA(isA<GenkitException>()),
      );
    });
  });
}
