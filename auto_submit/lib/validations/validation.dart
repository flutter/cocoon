// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';

import '../service/config.dart';
import 'package:github/github.dart' as github;

/// GitHub PR state constants.
const APPROVED_STATE = 'APPROVED';
const CHANGES_REQUESTED_STATE = 'CHANGES_REQUESTED';

/// GitHub status state.
const STATUS_SUCCESS = 'SUCCESS';
const STATUS_FAILURE = 'FAILURE';

/// GitHub merge state.
const UNKNOWN_MERGE_STATE = 'UNKNOWN';

/// Abstract class defining the signature of the validate method used to
/// implement PR state validations.
abstract class Validation {
  const Validation({required this.config});

  final Config config;

  /// Returns [ValidationResult] after using a [QueryResult] and [PullRequest] to validate
  /// a given PR state.
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest);
}

/// Enum that defines the actions to execute when a validation fails.
enum Action {
  /// Add a comment to the PR and remove the autosubmit label.
  REMOVE_LABEL,

  /// Ignore the failure and continue merging the PR.
  IGNORE_FAILURE,

  /// Do not land the PR but do not remove the autosubmit label either. This is
  /// used for temporary states that may fix by themselves.
  IGNORE_TEMPORARILY,
}

/// Holds a result of a validation execution.
/// TODO (ricardoamador) convert this to a record after MergeResult is merged.
class ValidationResult {
  ValidationResult(this.result, this.action, this.message);

  /// True if the validation was successful and should not block landing the PR.
  bool result;

  /// The action to execute if the validation failed.
  Action action;

  /// The message to add to the PR to provide some context to the user about the
  /// executed action.
  String message;
}

/// Holds metadata about a given CI build/test failure.
class FailureDetail {
  const FailureDetail(this.name, this.url);

  /// The name of the check.
  final String name;

  /// The url to the build where the test was executed.
  final String url;

  /// A link in markdown format to be added to the GitHub UI.
  String get markdownLink => '[$name]($url)';

  @override

  /// Hash implementation to support adding the results to set data structures.
  int get hashCode => 17 * 31 + name.hashCode * 31 + url.hashCode;

  @override

  /// Comparison method to simplify equality validations.
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FailureDetail && other.name == name && other.url == url;
  }
}
