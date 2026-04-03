// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:test/test.dart';

void main() {
  group('PubSub', () {
    test('acknowledge handles exceptions gracefully', () async {
      const pubsub = PubSub();
      // This should not throw even if credentials are missing or API fails.
      await expectLater(
        pubsub.acknowledge('test-sub', 'test-ack-id'),
        completes,
      );
    });
  });
}
