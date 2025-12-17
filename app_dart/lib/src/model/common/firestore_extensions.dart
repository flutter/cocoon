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

extension ListToValue on List {
  Value toValue() => Value(arrayValue: toArrayValue());

  ArrayValue toArrayValue() => ArrayValue(
    values: [
      for (final t in this)
        switch (t) {
          String() => t.toValue(),
          int() => t.toValue(),
          bool() => t.toValue(),
          DateTime() => t.toValue(),
          Map<String, dynamic>() => t.toValue(),
          _ => throw UnimplementedError(
            'Unsupported list type: ${t.runtimeType}',
          ),
        },
    ],
  );
}

extension MapToValue on Map<String, dynamic> {
  Value toValue() => Value(mapValue: toMapValue());

  MapValue toMapValue() => MapValue(
    fields: {
      for (final MapEntry(:key, :value) in entries)
        key: switch (value) {
          String() => value.toValue(),
          int() => value.toValue(),
          bool() => value.toValue(),
          DateTime() => value.toValue(),
          Map<String, dynamic>() => value.toValue(),
          _ => throw UnimplementedError(
            'Unsupported map type: ${value.runtimeType}',
          ),
        },
    },
  );
}
