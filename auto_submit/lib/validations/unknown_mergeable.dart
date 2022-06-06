// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';

/// Validates the PR is not temporarily in a unknown mergeable state.
class UnknownMergeable extends Validation {
  UnknownMergeable({
    required Config config,
  }) : super(config: config);

  @override

  /// Verifies the PR is in a known mergeable state.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    // This is used to skip landing until we are sure the PR is mergeable.
    final bool unknownMergeableState = messagePullRequest.mergeableState == UNKNOWN_MERGE_STATE;
    return ValidationResult(!unknownMergeableState, Action.IGNORE_TEMPORARILY, '');
  }
}
