// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

Matcher throwsExceptionWith<T>(String messageSubString) {
  return throwsA(
    isA<T>().having(
      (T e) => e.toString(),
      'description',
      contains(messageSubString),
    ),
  );
}
