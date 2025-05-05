// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/is_dart_internal.dart';
import 'package:test/test.dart';

void main() {
  for (final platform in ['Linux', 'Mac', 'Windows']) {
    for (final builder in [
      'packaging_release_builder',
      'flutter_release_builder',
    ]) {
      final name = '$platform $builder';
      test('$name is a dart-internal release builder', () {
        expect(isTaskFromDartInternalBuilder(builderName: name), isTrue);
      });
    }
  }
}
