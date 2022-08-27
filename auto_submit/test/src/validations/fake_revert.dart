// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' hide PullRequest;
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/validation.dart';

import 'package:github/github.dart';

class FakeRevert extends Revert {
  FakeRevert({required super.config});

  ValidationResult? validationResult;

  @override
  Future<ValidationResult> validate(QueryResult result, PullRequest messagePullRequest) async {
    return validationResult ?? ValidationResult(false, Action.IGNORE_TEMPORARILY, '');
  }
}
