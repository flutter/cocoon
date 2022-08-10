// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';

/// Validates that the list of checks for the PR is not empty.
class AutosubmitLabelExistence extends Validation {
  AutosubmitLabelExistence({
    required Config config,
  }) : super(config: config);

  @override

  /// The `autosubmit` label must exist when landing PRs.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    // List of labels associated with the pull request.
    final List<String> labelNames = (messagePullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();
    String message = '- The autosubmit label has been removed. Please add it back when ready.';
    return ValidationResult(labelNames.contains(config.autosubmitLabel), Action.REMOVE_LABEL, message);
  }
}
