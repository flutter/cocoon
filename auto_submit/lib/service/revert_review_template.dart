// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A template for creating follow up review issues for created revert requests.
class RevertReviewTemplate {
  RevertReviewTemplate({
    required this.repositorySlug,
    required this.revertPrNumber,
    required this.revertPrAuthor,
    required this.originalPrLink,
  });

  final String repositorySlug;
  final int revertPrNumber;
  final String revertPrAuthor;
  final String originalPrLink;

  /// Constructs the issues title.
  String _constructTitle() {
    return '''
Review request for Revert PR $repositorySlug#$revertPrNumber
''';
  }

  // TODO(ricardoamador): add the step about adding the revert_review label
  // back in once bot can respond to it, https://github.com/flutter/flutter/issues/110868
  /// Constructs the issues body.
  String _constructBody() {
    return '''
Pull request $repositorySlug#$revertPrNumber was submitted and merged by
@$revertPrAuthor in order to revert changes made in this pull request $originalPrLink.

Please assign this issue to the person that will make the formal review on the
revert request listed above.

Please do the following so that we may track this issue to completion:
1. Add the reviewer of revert pull request as the assignee of this issue.
2. Close only when the review has been completed.

<!-- DO NOT EDIT, REVERT METADATA
{
  'originalPrLink': '$originalPrLink',
  'revertPrLink': '$repositorySlug#$revertPrNumber',
  'revertPrAuthor': '$revertPrAuthor'
}
-->
''';
  }

  String? get title => _constructTitle();
  String? get body => _constructBody();
}
