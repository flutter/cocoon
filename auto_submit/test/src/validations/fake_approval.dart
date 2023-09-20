// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';

import 'package:auto_submit/validations/approval.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

class FakeApproval extends Approval {
  FakeApproval({required super.config});

  ValidationResult? validationResult;

  @override
  String get name => 'FakeApproval';

  /// Implements the code review approval logic.
  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    return validationResult ?? ValidationResult(true, Action.REMOVE_LABEL, '');
  }
}
