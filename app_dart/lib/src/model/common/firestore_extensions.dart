// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart';

extension StringToValue on String {
  Value toValue() => Value(stringValue: this);
}

extension IntToValue on int {
  Value toValue() => Value(integerValue: '$this');
}

extension BooleanToValue on bool {
  Value toValue() => Value(booleanValue: this);
}

extension DateTimeToValue on DateTime {
  Value toValue() => Value(timestampValue: toUtc().toIso8601String());
}
