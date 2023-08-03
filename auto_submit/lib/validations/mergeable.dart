// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import '../service/log.dart';

/// Validates that a pull request is in a mergeable state.
class Mergeable extends Validation {
  Mergeable({required super.config});

  @override
  String get name => 'Mergeable';

  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    final int pullRequestNumber = messagePullRequest.number!;
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final MergeableState mergeableState = result.repository!.pullRequest!.mergeable!;

    log.info('${slug.name}/$pullRequestNumber has mergeable state $mergeableState');

    switch (mergeableState) {
      case MergeableState.MERGEABLE:
        return ValidationResult(
          true,
          Action.REMOVE_LABEL,
          'Pull request ${slug.fullName}/$pullRequestNumber is mergeable',
        );
      case MergeableState.UNKNOWN:
        return ValidationResult(
          false,
          Action.IGNORE_TEMPORARILY,
          'Mergeability of pull request ${slug.fullName}/$pullRequestNumber could not be determined at time of merge.',
        );
      case MergeableState.CONFLICTING:
        // TODO (ricardoamador) monitor to see if we should make this the default class.
        // github documentation is poor at best.
        return ValidationResult(
          false,
          Action.REMOVE_LABEL,
          'Pull request ${slug.fullName}/$pullRequestNumber is not in a mergeable state.',
        );
    }
  }
}
