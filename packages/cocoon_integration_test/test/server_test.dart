// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/cocoon_integration_test.dart';
import 'package:test/test.dart';

void main() {
  test('IntegrationServer starts', () async {
    final server = IntegrationServer();
    expect(server.server, isNotNull);
    expect(server.config, isNotNull);
  });
}
