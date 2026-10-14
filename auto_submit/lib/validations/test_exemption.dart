// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/labels.dart';
import 'package:github/github.dart' as github;

import '../model/auto_submit_query_result.dart';
import '../service/validation_service.dart';
import 'validation.dart';

/// Validates that a pull request with the `missing-tests` label also has the
/// `test-exempt` label before merging.
class TestExemption extends Validation {
  TestExemption({required super.config});

  @override
  String get name => 'TestExemption';

  @override
  Future<ValidationResult> validate(
    QueryResult result,
    github.PullRequest messagePullRequest,
  ) async {
    final labelNames = messagePullRequest.labelNames;
    final isMissingTests = labelNames.contains(kMissingTestsLabel);
    final isTestExempt = labelNames.contains(kTestExemptLabel);

    if (isMissingTests && !isTestExempt) {
      final action = labelNames.contains(kEmergencyLabel)
          ? Action.IGNORE_FAILURE
          : Action.REMOVE_LABEL;
      const message =
          '- This pull request has the `$kMissingTestsLabel` label and '
          'does not have the `$kTestExemptLabel` label. Please add '
          'tests or obtain a test exemption from a tech lead before '
          're-applying the `$kAutosubmitLabel` label.';
      return ValidationResult(false, action, message);
    }

    return ValidationResult(true, Action.REMOVE_LABEL, '');
  }
}
