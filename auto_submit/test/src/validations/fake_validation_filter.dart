// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';

class FakeValidationFilter implements ValidationFilter {
  final Set<Validation> validations = {};

  void registerValidation(Validation newValidation) {
    validations.add(newValidation);
  }

  @override
  Set<Validation> getValidations() {
    return validations;
  }
}
