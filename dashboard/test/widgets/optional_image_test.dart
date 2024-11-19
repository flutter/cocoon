// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/widgets/optional_image.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OptionalImage.enabled', (WidgetTester tester) async {
    expect(
      const OptionalImage(imageUrl: 'url').enabled,
      isFalse,
    ); // because this is a test
    expect(
      const OptionalImage(imageUrl: 'url', enabled: false).enabled,
      isFalse,
    );
    expect(
      const OptionalImage(imageUrl: 'url', enabled: true).enabled,
      isTrue,
    );
  });
}
