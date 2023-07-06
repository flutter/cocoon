// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

/// Validates the PR is not conflicting.
class Conflicting extends Validation {
  Conflicting({
    required super.config,
  });

  @override

  /// Implements the logic to validate if the PR is in a conflicting state.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    // This is used to remove the bot label as it requires manual intervention.
    final bool mergeableResult = result.repository!.pullRequest!.mergeable == MergeableState.CONFLICTING;
    const String message = '- This commit is not mergeable and has conflicts. Please'
        ' rebase your PR and fix all the conflicts.';
    return ValidationResult(!mergeableResult, Action.REMOVE_LABEL, message);
  }
}
