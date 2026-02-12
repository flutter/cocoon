// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/service/dev_cocoon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DevelopmentCocoonService', () {
    late DevelopmentCocoonService service;

    setUp(() {
      service = DevelopmentCocoonService(DateTime.now());
    });

    test('fetchMergeQueueHooks returns empty list', () async {
      final response = await service.fetchMergeQueueHooks(idToken: 'token');
      expect(response.error, isNull);
      expect(response.data, isEmpty);
    });

    test('replayGitHubWebhook returns success', () async {
      final response = await service.replayGitHubWebhook(
        idToken: 'token',
        id: '1',
      );
      expect(response.error, isNull);
    });
  });
}
